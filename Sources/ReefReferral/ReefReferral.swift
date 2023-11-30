import Foundation
import Combine
import Logging
import UIKit
import Network

public struct Reef {} // Reef Namespace for public models

public protocol ReefReferralDelegate {
    func referringUpdate(senderLinkURL: URL?, 
                         senderLinkReceivedCount: Int,
                         senderLinkRedeemedCount: Int,
                         senderRewardEligibility: Reef.SenderRewardStatus,
                         senderRewardCodeURL: URL?)
    func referredUpdate(receiverStatus: Reef.ReceiverOfferStatus,
                        receiverOfferCodeURL: URL?)
}

public extension ReefReferralDelegate {
    func referringUpdate(senderLinkURL: URL?,
                         senderLinkReceivedCount: Int,
                         senderLinkRedeemedCount: Int,
                         senderRewardEligibility: Reef.SenderRewardStatus,
                         senderRewardCodeURL: URL?) {}
    func referredUpdate(receiverStatus: Reef.ReceiverOfferStatus,
                        receiverOfferCodeURL: URL?) {}
}

public class ReefReferral: ObservableObject {
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    public var delegate: ReefReferralDelegate?
    
    private let monitor = NWPathMonitor()
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String?
    private var data: ReefData = ReefData.load()
    private var receiptData: String {
        guard let url = Bundle.main.appStoreReceiptURL,
              let data = try? Data.init(contentsOf: url)
        else { return "" }
        return data.base64EncodedString()
    }
    
    @Published public var senderLinkURL: URL? = nil
    @Published public var senderLinkReceivedCount: Int = 0
    @Published public var senderLinkRedeemedCount: Int = 0
    @Published public var senderRewardEligibility: Reef.SenderRewardStatus = .not_eligible
    @Published public var senderRewardCodeURL: URL? = nil
    
    @Published public var receiverStatus: Reef.ReceiverOfferStatus = .none
    @Published public var receiverOfferCodeURL: URL? = nil
    
    init() {
        self.updateSenderInfos()
        self.updateReceiverInfos()
    }
    
    private func updateSenderInfos() {
        let referringInfo = data.referringInfo
        self.senderLinkURL = referringInfo?.link.linkURL
        self.senderLinkReceivedCount = referringInfo?.received ?? 0
        self.senderLinkRedeemedCount = referringInfo?.redeemed ?? 0
        self.senderRewardEligibility = referringInfo?.link.reward_status ?? .not_eligible
        self.senderRewardCodeURL = referringInfo?.link.rewardURL
        self.delegate?.referringUpdate(
            senderLinkURL: senderLinkURL,
            senderLinkReceivedCount: senderLinkReceivedCount,
            senderLinkRedeemedCount: senderLinkRedeemedCount,
            senderRewardEligibility: senderRewardEligibility,
            senderRewardCodeURL: senderRewardCodeURL
        )
    }
    
    private func updateReceiverInfos() {
        let referredInfo = data.referredInfo
        self.receiverStatus = referredInfo?.referred_user.referred_status ?? .none
        self.receiverOfferCodeURL = referredInfo?.appleOfferURL
    }
    
    @objc private func monitorNetworkStatus()  {
        guard monitor.pathUpdateHandler == nil else {
            Task {
                await self.status()
            }
            return
        }
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                ReefReferral.logger.debug("🟢 Connection restored")
                Task {
                    await self.status()
                }
                
            } else {
                ReefReferral.logger.debug("🔴 Not internet connection")
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    @discardableResult private func status() async -> Result<Reef.ReferralStatus, Error> {
        guard let apiKey = apiKey else {
            return .failure(Reef.ReefError.missingAPIKey)
        }
        
        let statusRequest = StatusRequest(udid: data.udid, app_id: apiKey, receipt_data: receiptData)
        let result = await ReefAPIClient.shared.send(statusRequest)
        
        switch result {
        case .success(let infos):
            data.referringInfo = infos
            data.save()
            couponHandler.receiverOfferId = infos.offer.referral_offer_id
            couponHandler.receiverOfferId = infos.offer.referring_offer_id
            couponHandler.checkForCouponRedemption()
            DispatchQueue.main.async {
                self.updateSenderInfos()
            }
            return .success(infos.status)
            
        case .failure(let error):
            ReefReferral.logger.error("\(error)")
            return .failure(error)
        }
       
    }
    
    // MARK: - Common
    
    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil, logLevel: Reef.LogLevel = .none) {
        self.apiKey = apiKey
        self.delegate = delegate
        
        // Custom log level
        switch logLevel {
        case .debug:
            ReefReferral.logger.logLevel = .error
        default:
            ReefReferral.logger.logLevel = .critical
        }
        
        self.monitorNetworkStatus()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(monitorNetworkStatus),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    public func refresh() {
        Task {
            await self.status()
        }
    }
    
    // MARK: - Sender
        
    public func triggerSenderSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(Reef.ReefError.missingAPIKey.localizedDescription)")
            return
        }
        guard let link = data.referringInfo?.link else {
            ReefReferral.logger.error("No referral link found")
            return
        }
        
        Task {
            let request = NotifyReferringSuccessRequest(link_id: link.id)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let referringInfo):
                data.referringInfo = referringInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateSenderInfos()
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    // MARK: - Receiver
    
    public func handleDeepLink(url: URL) {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(Reef.ReefError.missingAPIKey.localizedDescription)")
            return
        }
        
        guard let linkId = url.absoluteString.components(separatedBy: "://").last else {
            ReefReferral.logger.error("Error parsing link ID")
            return
        }
        
        Task {
            let udid = UUID().uuidString
            let request = HandleDeepLinkRequest(link_id: linkId, udid: udid, receipt_data: receiptData)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let referredInfo):
                data.referredInfo = referredInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateReceiverInfos()
                    if let url = referredInfo.appleOfferURL, referredInfo.offer_automatic_redirect {
                        UIApplication.shared.open(url)
                    }
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    public func triggerReceiverSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(Reef.ReefError.missingAPIKey.localizedDescription)")
            return
        }
        guard let referredUser = data.referredInfo?.referred_user else {
            ReefReferral.logger.error("No referred user found")
            return
        }
        
        Task {
            let request = NotifyReferredSuccessRequest(referred_user_id: referredUser.id)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let referredInfo):
                data.referredInfo = referredInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateReceiverInfos()
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    // MARK: - Dev Utils
    
    public func clear() {
        data.referringInfo = nil
        data.referredInfo = nil
        data.save()
        self.updateSenderInfos()
        self.updateReceiverInfos()
    }
}
