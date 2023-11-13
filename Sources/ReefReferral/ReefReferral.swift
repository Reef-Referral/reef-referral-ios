import Foundation
import Combine
import Logging
import UIKit
import Network

public enum LogLevel {
    case debug
    case none
}

public protocol ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, redeemed: Int, rewardEligibility: ReferringRewardStatus, referringRewardOfferCodeURL: URL?)
    func referredUpdate(status: ReferredStatus, referredRewardOfferCodeURL: URL?)
}

public extension ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, redeemed: Int, rewardEligibility: ReferringRewardStatus, referringRewardOfferCodeURL: URL?) {}
    func referredUpdate(status: ReferredStatus, referredRewardOfferCodeURL: URL?) {}
}

public enum ReefError : Error {
    case missingAPIKey
    
    public var localizedDescription: String {
        switch self {
        case .missingAPIKey:
            return "Missing API key, did you forget to initialize ReefReferral SDK?"
        }
    }
}

public class ReefReferral: ObservableObject {
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    public var delegate: ReefReferralDelegate?
    
    private let monitor = NWPathMonitor()
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String?
    private var data: ReefData = ReefData.load()
    
    @Published public var referringLinkURL: URL? = nil
    @Published public var receivedCount: Int = 0
    @Published public var redeemedCount: Int = 0
    @Published public var rewardEligibility: ReferringRewardStatus = .not_eligible
    @Published public var referringRewardOfferCodeURL: URL? = nil
    
    @Published public var referredStatus: ReferredStatus = .none
    @Published public var referredRewardOfferCodeURL: URL? = nil
    
    init() {
        updateReferringInfos()
        updateReferredInfos()
    }
    
    private func updateReferringInfos() {
        let referringInfo = data.referringInfo
        referringLinkURL = referringInfo?.link.linkURL
        receivedCount = referringInfo?.received ?? 0
        redeemedCount = referringInfo?.redeemed ?? 0
        rewardEligibility = referringInfo?.link.reward_status ?? .not_eligible
        referringRewardOfferCodeURL = referringInfo?.link.rewardURL
        delegate?.referringUpdate(
            linkURL: referringLinkURL,
            received: receivedCount,
            redeemed: redeemedCount,
            rewardEligibility: rewardEligibility,
            referringRewardOfferCodeURL: referringRewardOfferCodeURL
        )
    }
    
    private func updateReferredInfos() {
        let referredInfo = data.referredInfo
        referredStatus = referredInfo?.referred_user.referred_status ?? .none
        referredRewardOfferCodeURL = referredInfo?.appleOfferURL
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
    
    // MARK: - Common
    
    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil, logLevel: LogLevel = .none) {
        self.apiKey = apiKey
        self.delegate = delegate
        
        self.monitorNetworkStatus()
        
        // Custom log level
        switch logLevel {
        case .debug:
            ReefReferral.logger.logLevel = .error
        case .none:
            ReefReferral.logger.logLevel = .critical
        }
        
        // Development logLevel
        ReefReferral.logger.logLevel = .trace
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(monitorNetworkStatus),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @discardableResult public func status() async -> Result<ReferralStatus, Error> {
        guard let apiKey = apiKey else {
            return .failure(ReefError.missingAPIKey)
        }
        
        let testConnectionRequest = StatusRequest(udid: data.udid, app_id: apiKey)
        let result = await ReefAPIClient.shared.send(testConnectionRequest)
        
        switch result {
        case .success(let infos):
            data.referringInfo = infos
            data.save()
            couponHandler.referredOfferCode = infos.offer.referral_offer_code
            couponHandler.referredOfferCode = infos.offer.referring_offer_code
            couponHandler.checkForCouponRedemption()
            DispatchQueue.main.async {
                self.updateReferringInfos()
            }
            return .success(infos.status)
            
        case .failure(let error):
            ReefReferral.logger.error("\(error.localizedDescription)")
            return .failure(error)
        }
       
    }
    
    public func triggerReferringSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(ReefError.missingAPIKey.localizedDescription)")
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
                ReefReferral.logger.info("Reffering user did claim reward")
                data.referringInfo = referringInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateReferringInfos()
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    // MARK: - Referred part
    
    public func handleDeepLink(url: URL) {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(ReefError.missingAPIKey.localizedDescription)")
            return
        }
        
        guard let linkId = url.absoluteString.components(separatedBy: "://").last else {
            ReefReferral.logger.error("Error parsing link ID")
            return
        }
        
        if let referalId = data.referredInfo?.referred_user.id {
            ReefReferral.logger.debug("Referal already opened with referred ID : \(referalId)")
            return
        }
        
        Task {
            let udid = UUID().uuidString
            let request = HandleDeepLinkRequest(link_id: linkId, udid: udid)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let referredInfo):
                data.referredInfo = referredInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateReferredInfos()
                    if let url = referredInfo.appleOfferURL, referredInfo.offer_automatic_redirect {
                        UIApplication.shared.open(url)
                    }
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    public func triggerReferralSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.critical("\(ReefError.missingAPIKey.localizedDescription)")
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
                ReefReferral.logger.debug("Reffered user did claim offer")
                data.referredInfo = referredInfo
                data.save()
                DispatchQueue.main.async {
                    self.updateReferredInfos()
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
        self.updateReferringInfos()
        self.updateReferredInfos()
    }
}
