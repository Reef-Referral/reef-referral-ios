import Foundation
import Combine
import Logging
import UIKit

public protocol ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, successes: Int, rewardEligibility: ReferringRewardStatus, rewardURL: URL?)
    func referredUpdate(status: ReferredStatus, offerURL: URL?)
}

extension ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, successes: Int, rewardEligibility: ReferringRewardStatus, rewardURL: URL?) {}
    func referredUpdate(status: ReferredStatus, offerURL: URL?) {}
}

public class ReefReferral: ObservableObject {
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    public var delegate: ReefReferralDelegate?
    
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String?
    private var data: ReefData = ReefData.load()
    
    @Published public var referringLinkURL: URL? = nil
    @Published public var receivedCount: Int = 0
    @Published public var successCount: Int = 0
    @Published public var rewardEligibility: ReferringRewardStatus = .not_eligible
    @Published public var rewardURL: URL? = nil
    @Published public var referredStatus: ReferredStatus = .none
    @Published public var referredOfferURL: URL? = nil
    
    init() {
        updateReferringInfos()
        updateReferredInfos()
    }
    
    private func updateReferringInfos() {
        let referringInfo = data.referringInfo
        referringLinkURL = referringInfo?.link.linkURL
        receivedCount = referringInfo?.received ?? 0
        successCount = referringInfo?.successes ?? 0
        rewardEligibility = referringInfo?.link.reward_status ?? .not_eligible
        rewardURL = referringInfo?.link.rewardURL
        delegate?.referringUpdate(
            linkURL: referringLinkURL,
            received: receivedCount,
            successes: successCount,
            rewardEligibility: rewardEligibility,
            rewardURL: rewardURL
        )
    }
    
    private func updateReferredInfos() {
        let referredInfo = data.referredInfo
        referredStatus = referredInfo?.referred_user.referred_status ?? .none
        referredOfferURL = referredInfo?.referred_user.appleOfferURL
    }

    // MARK: - Common
    
    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil, logLevel: Logger.Level) {
        self.apiKey = apiKey
        self.delegate = delegate
        ReefReferral.logger.logLevel = logLevel
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(status),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc public func status() {
        guard let apiKey = apiKey else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        Task {
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
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    public func triggerReferringSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferal SDK ?")
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
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        guard let linkId = url.absoluteString.components(separatedBy: "://").last else {
            ReefReferral.logger.debug("Error parsing link ID")
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
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    public func triggerReferralSuccess() {
        guard let _ = apiKey else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
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
                ReefReferral.logger.info("Reffered user did claim offer")
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
