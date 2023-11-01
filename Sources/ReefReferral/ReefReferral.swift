import Foundation
import Logging

public protocol ReefReferralDelegate {
    func didReceiveReferralStatus(referralReceived: Int, referralSuccess: Int, rewardEligibility: RewardStatus)
    func referredUserDidReceiveReferral()
    func referredUserDidClaimReferral()
    func referringUserDidClaimReward()
}

extension ReefReferralDelegate {
    func didReceiveReferralStatus(referralReceived: Int, referralSuccess: Int, rewardEligibility: RewardStatus) {}
    func referredUserDidReceiveReferral() {}
    func referredUserDidClaimReferral() {}
    func referringUserDidClaimReward() {}
}

/// ReefReferral SDK main class
public class ReefReferral {
        
    public static let shared = ReefReferral()
    public static var logger = Logger(label: "com.reef-referral.logger")
    
    public var data: ReefData {
        return reefData
    }
    
    private var couponHandler = CouponRedemptionDetector()
    private var apiKey: String? // currently app-id, we'll need to do something more flexible
    private var delegate: ReefReferralDelegate?
    private var reefData: ReefData = ReefData.load()
    
    // MARK: - Common
    
    /// Asynchronously starts the ReefReferral configuration with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to be used for configuration.
    ///
    public func start(apiKey: String, delegate: ReefReferralDelegate?) {
        self.apiKey = apiKey
        self.delegate = delegate
        
        Task {
            let testConnectionRequest = ReferralTestConnectionRequest(app_id: apiKey)
            let result = await ReefAPIClient.shared.send(testConnectionRequest)
            switch result {
            case .success(_):
                ReefReferral.logger.info("ReefReferral properly configured")
                self.couponHandler.checkForCouponRedemption(identifier: "test")
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    // MARK: - Referrer part

    /// Asynchronously generates a referral link.
    ///
    /// - Returns: A `ReferralLink` with the link.
    ///
    public func generateReferralLink() async -> ReferralLinkContent? {

        guard let apiKey else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return nil
        }
        
        if let link = reefData.referralLink {
            return link
        }
        
        let request = GenerateReferralLinkRequest(app_id: apiKey, udid: reefData.udid)
        let response = await ReefAPIClient.shared.send(request)
        switch response {
        case .success(let result):
            reefData.referralLink = result.link
            reefData.save()
            return result.link
        case .failure(let error):
            ReefReferral.logger.error("\(error)")
            return nil
        }
    }

    
    /// Asynchronously checks referral statuses for a specific referral link.
    ///
    public func checkReferralStatus() {

        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        
        guard let link = reefData.referralLink else { return }
        
        Task {
            let statusesRequest = ReferralStatusRequest(link_id: link.id)
            let response = await ReefAPIClient.shared.send(statusesRequest)
            
            switch response {
            case .success(let referral_status):
                DispatchQueue.main.async {
                    let nbReceived = referral_status.referred_users.filter { $0.referred_status == .received }.count
                    let nbSuccess = referral_status.referred_users.filter { $0.referred_status == .success }.count
                    let status = referral_status.link.reward_status
                    self.delegate?.didReceiveReferralStatus(referralReceived: nbReceived,
                                                            referralSuccess: nbSuccess,
                                                            rewardEligibility: status)
                }
            case .failure(let error):
                ReefReferral.logger.error("\(error)")
            }
        }
    }
    
    // MARK: - Referred part
    
    /// Asynchronously handles deep links and extracts the link_id from the URL.
    ///
    /// - Parameters:
    ///   - url: The deep link URL.
    ///
    public func handleDeepLink(url: URL) {
        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        guard url != reefData.referralLink?.linkURL else {
            ReefReferral.logger.error("Cannot use own promo-code")
            return
        }
        
        if let referalId = reefData.referralId {
            ReefReferral.logger.debug("Referal already opened with referalID : \(referalId)")
            return
        }
        
        Task {
            // Extract the link_id from the URL
            if let linkId = url.absoluteString.components(separatedBy: "://").last {
                let request = HandleDeepLinkRequest(link_id: linkId, udid: reefData.udid)
                let response = await ReefAPIClient.shared.send(request)
                switch response {
                case .success(let result):
                    reefData.referralId = result.referral.id
                    reefData.save()
                    DispatchQueue.main.async {
                        self.delegate?.referredUserDidReceiveReferral()
                    }
                case .failure(let error):
                    ReefReferral.logger.error("\(error)")
                }
            } else {
                ReefReferral.logger.error("Invalid URL scheme")
            }
        }
    }
    
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    /// This get automatically triggered if the developer has properly added an Apple Coupon Code for Referred user
    ///
    ///
    public func triggerReferralSuccess() {
        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        guard let referralID = reefData.referralId else {
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
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    /// This get automatically triggered if the developer has properly added an Apple Coupon Code for Referring user
    ///
    public func triggerReferringSuccess() {
        guard apiKey != nil else {
            ReefReferral.logger.error("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        guard let linkID = reefData.referralLink?.id else {
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
    
    // MARK: - DEV Utils
    
    /// Clears link in case we want to create a new one
    ///
    public func clearLink() {
        reefData.referralLink = nil
        reefData.save()
    }
    
    /// Clears link in case we want to create a new one
    ///
    public func clearReferralID() {
        reefData.referralId = nil
        reefData.save()
    }
}

