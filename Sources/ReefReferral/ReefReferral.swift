import Foundation

/// ReefReferral SDK main class
public class ReefReferral {
        
    public static let shared = ReefReferral()
    public var data : ReefData {
        return reefData
    }
    
    private var apiKey: String? // currently app-id, we'll need to do something more flexible
    private var reefData: ReefData = ReefData.load()
    
    // MARK: - Common
    
    /// Asynchronously starts the ReefReferral configuration with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to be used for configuration.
    ///
    public func start(apiKey: String) async {
        self.apiKey = apiKey
        
        let testConnectionRequest = ReferralTestConnectionRequest(app_id: apiKey)
        let result = await ReefAPIClient.shared.send(testConnectionRequest)
        switch result {
        case .success(_):
            print("ReefReferral properly configured")
        case .failure(let error):
            print(error)
        }
    }
    
    // MARK: - Referrer part

    /// Asynchronously generates a referral link.
    ///
    /// - Returns: A `ReferralLink` with the link.
    ///
    public func generateReferralLink() async -> ReferralLinkContent? {

        guard let apiKey else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return nil
        }
        
        if let link = reefData.referralLink {
            return link
        }
        
        let request = ReferralLinkRequest(app_id: apiKey)
        let response = await ReefAPIClient.shared.send(request)
        switch response {
        case .success(let result):
            reefData.referralLink = result.link
            reefData.save()
            return result.link
        case .failure(let error):
            print(error)
            return nil
        }
    }

    
    /// Asynchronously checks referral statuses for a specific referral link.
    ///
    public func checkReferralStatuses() async -> [ReferralStatus]{

        guard apiKey != nil else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return []
        }
        
        guard let link = reefData.referralLink else { return [] }
        
        let statusesRequest = ReferralStatusesRequest(link_id: link.id)
        let response = await ReefAPIClient.shared.send(statusesRequest)
        
        switch response {
        case .success(let statuses):
            return statuses
        case .failure(let error):
            print(error)
            return []
        }
    }
    
    // MARK: - Referred part
    
    /// Asynchronously handles deep links and extracts the link_id from the URL.
    ///
    /// - Parameters:
    ///   - url: The deep link URL.
    ///
    public func handleDeepLink(url: URL) async {
        guard apiKey != nil else {
            print("Missing API key, did you forget to initialize ReefReferral SDK?")
            return
        }
        
        if let referalId = reefData.referralId {
            print("Referal already opened with referalID : \(referalId)")
            return
        }
                
        // Extract the link_id from the URL
        if let linkId = url.absoluteString.components(separatedBy: "://").last {
            let request = HandleDeepLinkRequest(link_id: linkId, udid: reefData.udid)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let result):
                reefData.referralId = result.referral.id
                reefData.save()
            case .failure(let failure):
                print(failure)
            }
        } else {
            print("Invalid URL")
        }
        
    }
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    ///
    /// - Parameters:
    ///   - referralID: The unique identifier for the referral.
    ///
    public func triggerReferralSuccess() async {
        guard apiKey != nil else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        guard let referralID = reefData.referralId else {
            print("No referralID to send")
            return
        }
        let request = NotifyReferralSuccessRequest(referral_id: referralID)
        _ = await ReefAPIClient.shared.send(request)
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

