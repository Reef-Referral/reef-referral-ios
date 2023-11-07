import Foundation
import Combine
import Logging
import UIKit

public protocol ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, successes: Int, rewardEligibility: ReferringRewardStatus, rewardURL: URL?)
    func referredUpdate(status: ReferredStatus, offerURL: URL?)
}

extension ReefReferralDelegate {
    public func referringUpdate(linkURL: URL?, received: Int, successes: Int, rewardEligibility: ReferringRewardStatus, rewardURL: URL?) {}
    public func referredUpdate(status: ReferredStatus, offerURL: URL?) {}
}

public class ReefReferral {
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    public var delegate: ReefReferralDelegate?
    
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String?
    private var data: ReefData = ReefData.load()
    
    public var referringLinkURL: URL? { data.referringInfo?.link.linkURL }
    public var referringReceivedCount: Int { data.referringInfo?.received ?? 0 }
    public var referringSuccessCount: Int { data.referringInfo?.successes ?? 0 }
    public var referringRewardEligibility: ReferringRewardStatus { data.referringInfo?.link.reward_status ?? .not_eligible }
    public var referringRewardURL: URL? { data.referringInfo?.link.rewardURL }
    public var referredStatus: ReferredStatus { data.referredInfo?.referred_user.referred_status ?? .none }
    public var referredOfferURL: URL? { data.referredInfo?.referred_user.appleOfferURL }
    
    // MARK: - Common
    
    /// Asynchronously starts the ReefReferral configuration with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to be used for configuration.
    ///
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
    
    /// Check status of referral for the current user
    ///
    @objc public func status() {
        
        guard let apiKey else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        Task {
            let testConnectionRequest = StatusRequest(udid: self.data.udid, app_id: apiKey)
            let result = await ReefAPIClient.shared.send(testConnectionRequest)
            switch result {
            case .success(let referralInfo):
                self.data.referringInfo = referralInfo
                self.data.save()

                self.couponHandler.referredOfferCode = referralInfo.offer.referral_offer_code
                self.couponHandler.referredOfferCode = referralInfo.offer.referring_offer_code
                self.couponHandler.checkForCouponRedemption()
                
                DispatchQueue.main.async {
                    self.delegate?.referringUpdate(linkURL: referralInfo.link.linkURL,
                                                   received: referralInfo.received,
                                                   successes: referralInfo.successes,
                                                    rewardEligibility: referralInfo.link.reward_status,
                                                    rewardURL: referralInfo.link.rewardURL)
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    /// This get automatically triggered if the developer has properly added an Apple Coupon Code for Referring user
    /// If not, developer has to manually call it to indicate that a reward was gifted to the current user
    ///
    public func triggerReferringSuccess() {
        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
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
                self.data.referringInfo = referringInfo
                self.data.save()
                ReefReferral.logger.info("Reffering user did claim reward")
                self.delegate?.referringUpdate(linkURL: referringInfo.link.linkURL,
                                               received: referringInfo.received,
                                               successes: referringInfo.successes,
                                                rewardEligibility: referringInfo.link.reward_status,
                                                rewardURL: referringInfo.link.rewardURL)
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    
    // MARK: - Referred part
    
    /// Asynchronously handles deep links and extracts the link_id from the URL.
    /// Automatically called either from the AppStore redirection (when using coupon) or from the browser
    ///
    /// - Parameters:
    ///   - url: The deep link URL.
    ///
    public func handleDeepLink(url: URL) {
        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        guard let linkId = url.absoluteString.components(separatedBy: "://").last else {
            ReefReferral.logger.debug("Error parsing link ID")
            return
        }
        
//        if linkId == data.referralInfo?.link.id {
//            ReefReferral.logger.debug("Cannot use own link")
//            return
//        }
        
        if let referalId = data.referredInfo?.referred_user.id {
            ReefReferral.logger.debug("Referal already opened with referred ID : \(referalId)")
            return
        }
        
        Task {
            let udid = UUID().uuidString // data.udid
            // Extract the link_id from the URL
            let request = HandleDeepLinkRequest(link_id: linkId, udid: udid)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let referredInfo):
                data.referredInfo = referredInfo
                data.save()
                DispatchQueue.main.async {
                    self.delegate?.referredUpdate(status: referredInfo.referred_user.referred_status,
                                                  offerURL: referredInfo.referred_user.appleOfferURL)
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    /// This get automatically triggered if the developer has properly added an Apple Coupon Code for Referred user
    /// If not, the developer has to manually call it to indicate that the current user referral was succesfull
    ///
    ///
    public func triggerReferralSuccess() {
        guard apiKey != nil else {
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
                    self.delegate?.referredUpdate(status: referredInfo.referred_user.referred_status,
                                                  offerURL: referredInfo.referred_user.appleOfferURL)
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    
    // MARK: - Dev Utils
    
    /// Clears local data
    ///
    public func clear() {
        data.referringInfo = nil
        data.referredInfo = nil
        data.save()
        self.delegate?.referringUpdate(linkURL: nil, received: 0, successes: 0, rewardEligibility: .not_eligible, rewardURL: nil)
        self.delegate?.referredUpdate(status: .none, offerURL: nil)
    }

}

