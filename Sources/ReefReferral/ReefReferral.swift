import Foundation
import Combine
import Logging
import UIKit

public protocol ReefReferralDelegate {
    func didReceiveReferralStatus(referralReceived: Int, referralSuccess: Int, rewardEligibility: ReferringRewardStatus)
    func referredUserDidReceiveReferral()
    func referredUserDidClaimReferral()
    func referringUserDidClaimReward()
}

extension ReefReferralDelegate {
    func didReceiveReferralStatus(referralReceived: Int, referralSuccess: Int, rewardEligibility: ReferringRewardStatus) {}
    public func referredUserDidReceiveReferral() {}
    public func referredUserDidClaimReferral() {}
    public func referringUserDidClaimReward() {}
}

public class ReefReferralObservable: ObservableObject {
    
    @Published public var referralLinkURL: URL? = ReefReferral.shared.data.referralInfo?.link.linkURL
    @Published public var referralStatus: (received: Int, success: Int, eligibility: ReferringRewardStatus) = (0, 0, .not_eligible)
    @Published public var wasReferred: Bool = (ReefReferral.shared.data.referredId != nil)
    @Published public var hasClaimedReferralReward: String? = ReefReferral.shared.data.referredId
    

    private var reefReferral: ReefReferral

    public init(reefReferral: ReefReferral) {
        self.reefReferral = reefReferral
        self.reefReferral.delegate = self
        self.reefReferral.observable = self
    }
}

extension ReefReferralObservable: ReefReferralDelegate {
    public func didReceiveReferralStatus(referralReceived: Int, referralSuccess: Int, rewardEligibility: ReferringRewardStatus) {
        referralStatus = (referralReceived, referralSuccess, rewardEligibility)
    }
}
 
/// ReefReferral SDK main class
public class ReefReferral {
    
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    public var delegate: ReefReferralDelegate?
    public var observable: ReefReferralObservable?
    public  var data: ReefData {
        return reefData
    }
    
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String? // currently app-id, we'll need to do something more flexible
    private var reefData: ReefData = ReefData.load()
    
    // MARK: - Common
    
    /// Asynchronously starts the ReefReferral configuration with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to be used for configuration.
    ///
    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil) {
        self.apiKey = apiKey
        self.delegate = delegate
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(status),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        Task {
            let testConnectionRequest = ReferralTestConnectionRequest(app_id: apiKey)
            let result = await ReefAPIClient.shared.send(testConnectionRequest)
            switch result {
            case .success(_):
                ReefReferral.logger.info("ReefReferral properly configured")
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    /// Check status of referral for the current user
    ///
    @objc public func status() {
        
        guard let apiKey else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        Task {
            let testConnectionRequest = StatusRequest(udid: reefData.udid, app_id: apiKey)
            let result = await ReefAPIClient.shared.send(testConnectionRequest)
            switch result {
            case .success(let referralInfo):
                self.reefData.referralInfo = referralInfo
                self.reefData.save()
                let received = referralInfo.referred_users.filter({ $0.referred_status == .received }).count
                let successes = referralInfo.referred_users.filter({ $0.referred_status == .success }).count
                let productIdentifiers = [referralInfo.offer.referral_offer_code, referralInfo.offer.referring_offer_code].compactMap { $0 }
                self.couponHandler.checkForCouponRedemption(productIdentifiers: productIdentifiers)
                
                DispatchQueue.main.async {
                    self.observable?.referralLinkURL = referralInfo.link.linkURL
                    self.observable?.didReceiveReferralStatus(referralReceived: received, referralSuccess: successes, rewardEligibility: referralInfo.link.reward_status)
                    self.delegate?.didReceiveReferralStatus(referralReceived: received, referralSuccess: successes, rewardEligibility: referralInfo.link.reward_status)
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
        guard let linkID = reefData.referralInfo?.link.id else {
            ReefReferral.logger.error("No linkID found")
            return
        }
        
        Task {
            let request = NotifyReferringSuccessRequest(link_id: linkID)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(_):
                ReefReferral.logger.info("Reffering user did claim reward")
                DispatchQueue.main.async {
                    self.delegate?.referringUserDidClaimReward()
                }
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
        
        if linkId == reefData.referralInfo?.link.id {
            ReefReferral.logger.debug("Cannot use own link")
            return
        }
        
        if let referalId = reefData.referredId {
            ReefReferral.logger.debug("Referal already opened with referalID : \(referalId)")
            return
        }
        
        Task {
            // Extract the link_id from the URL
            let request = HandleDeepLinkRequest(link_id: linkId, udid: reefData.udid)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let result):
                reefData.referredId = result.id
                reefData.save()
                DispatchQueue.main.async {
                    self.observable?.wasReferred = true
                    self.delegate?.referredUserDidReceiveReferral()
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
        guard let referralID = reefData.referredId else {
            ReefReferral.logger.error("No referralID found")
            return
        }
        
        Task {
            let request = NotifyReferralSuccessRequest(referral_id: referralID)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(_):
                ReefReferral.logger.info("Reffering user did claim reward")
                DispatchQueue.main.async {
                    self.delegate?.referredUserDidClaimReferral()
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
        reefData.referralInfo = nil
        observable?.referralLinkURL = nil
        reefData.referredId = nil
        observable?.wasReferred = false
        reefData.save()
        self.delegate?.didReceiveReferralStatus(referralReceived: 0, referralSuccess: 0, rewardEligibility: .not_eligible)
    }

}

