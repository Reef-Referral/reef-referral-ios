//
//  File.swift
//  
//
//  Created by Piotr Knapczyk on 06/12/2023.
//

import Foundation
import Logging
import UIKit
import Network

protocol ReefReferralDelegatePassThrough {
    func infoUpdated(referralInfo: ReefReferral.ReferralInfo)
}

class ReefReferralInternal {
    private let monitor = NWPathMonitor()
    private var apiKey: String?
    private var apiService: ReefAPIClient?

    var delegate: ReefReferralDelegatePassThrough?

    var data: ReefData = ReefData.load() { didSet { dataUpdated() }}


    func receiptData() -> String {
        guard let url = Bundle.main.appStoreReceiptURL,
              let data = try? Data.init(contentsOf: url)
        else { return "" }
        return data.base64EncodedString()
    }



    func setUserId(_ id : String) {
        self.data.custom_id = id
        Task {
            try? await self.status()
        }
    }

    func dataUpdated() {
        let info = ReefReferral.ReferralInfo(data)
        delegate?.infoUpdated(referralInfo: info)
    }

    @objc private func monitorNetworkStatus()  {
        guard monitor.pathUpdateHandler == nil else {
            Task {
                try? await self.status()
            }
            return
        }
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                ReefReferral.logger.debug("🟢 Connection restored")
                Task {
                    try? await self.status()
                }

            } else {
                ReefReferral.logger.debug("🔴 Not internet connection")
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func status() async throws -> ReefReferral.ReferralInfo {
        guard let api = apiService else {
            throw ReefReferral.ReefError.missingAPIKey
        }

        let statusRequest = StatusRequest(udid: data.udid, custom_id:self.data.custom_id, receipt_data: receiptData())

        do {
            let infos = try await api.send(statusRequest)

            return await MainActor.run {
                self.data.senderInfo = infos.sender
                self.data.receiverInfo = infos.receiver
                self.data.save()
                self.dataUpdated()
                return ReefReferral.ReferralInfo(data)
            }
        } catch {
            ReefReferral.logger.error("\(error)")
            throw error
        }
    }

    // MARK: - Common

    func start(apiKey: String, delegate: ReefReferralDelegatePassThrough, logLevel: ReefReferral.LogLevel) {
        self.apiService = ReefAPIClient(api: ReefAPI(apiKey: apiKey))
        self.delegate = delegate

        // Custom log level
        switch logLevel {
        case .debug:
            ReefReferral.logger.logLevel = .debug
        default:
            ReefReferral.logger.logLevel = .error
        }

        self.monitorNetworkStatus()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(monitorNetworkStatus),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func refresh() {
        Task {
            try? await self.status()
        }
    }

    // MARK: - Sender

    func triggerSenderSuccess() {
        Task {
            guard let api = apiService else {
                ReefReferral.logger.critical("\(ReefReferral.ReefError.missingAPIKey.localizedDescription)")
                return
            }
            guard let link = data.senderInfo?.link else {
                ReefReferral.logger.error("No referral link found")
                return
            }

            let request = NotifyReferringSuccessRequest(link_id: link.id)
            do {
                let referringInfo = try await api.send(request)

                await MainActor.run {
                    self.data.senderInfo = referringInfo
                    self.data.save()
                    self.dataUpdated()
                }

            } catch {
                ReefReferral.logger.error("\(error)")
            }
        }
    }

    // MARK: - Receiver

    func handleDeepLink(url: URL) {
        Task {

            guard let api = apiService else {
                ReefReferral.logger.critical("\(ReefReferral.ReefError.missingAPIKey.localizedDescription)")
                return
            }

            guard let linkId = url.absoluteString.components(separatedBy: "://").last else {
                ReefReferral.logger.error("Error parsing link ID")
                return
            }

            let udid = self.data.custom_id ?? self.data.udid
            let request = HandleDeepLinkRequest(link_id: linkId, udid: udid, receipt_data: receiptData())
            do {
                let referredInfo = try await api.send(request)

                await MainActor.run {
                    self.data.receiverInfo = referredInfo
                    self.data.save()
                    self.dataUpdated()
                    if let url = referredInfo.appleOfferURL, referredInfo.offer_automatic_redirect {
                        UIApplication.shared.open(url)
                    }
                }

            } catch {
                ReefReferral.logger.error("\(error)")
            }
        }
    }

    func triggerReceiverSuccess() {
        Task {

            guard let api = apiService else {
                ReefReferral.logger.critical("\(ReefReferral.ReefError.missingAPIKey.localizedDescription)")
                return
            }

            let udid = self.data.custom_id ?? self.data.udid

            let request = NotifyReferredSuccessRequest(udid: udid)
            do {

                let referredInfo = try await api.send(request)
                await MainActor.run {
                    self.data.receiverInfo = referredInfo
                    self.data.save()
                    self.dataUpdated()
                }

            } catch {
                ReefReferral.logger.error("\(error)")
            }
        }
    }

}