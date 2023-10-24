import Foundation

public protocol ReefReferralDelegate {
    /// Notifies the delegate about changes in referral statuses.
    ///
    /// - Parameters:
    ///   - statuses: An array of `ReferralStatus` objects representing the current referral statuses.
    func referralStatusChanged(statuses: [ReferralStatus])
    
    /// Notifies the delegate when a referral is received, typically after handling deeplink
    ///
    /// - Parameters:
    ///   - linkID: The linkID of the referral.
    func didReceiveReferral(linkID: String)
}

public enum ReefReferralError: Error {
    case missingAPIKey
    case invalidAPIKey
}

/// ReefReferral SDK main class
public class ReefReferral {
        
    public static let shared = ReefReferral()
    
    private var delegate: ReefReferralDelegate?
    private var apiKey: String? // currently app-id, we'll need to do something more flexible
    
    public var reefData: ReefData = ReefData.load()
    
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
    
    /// Asynchronously starts the ReefReferral configuration with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: The API key to be used for configuration.
    ///
    public func start(apiKey: String, delegate: ReefReferralDelegate) async {
        self.apiKey = apiKey
        self.delegate = delegate
        
        let testConnectionRequest = ReferralTestConnectionRequest(app_id: apiKey)
        let result = await ReefAPIClient.shared.send(testConnectionRequest)
        switch result {
        case .success(_):
            print("ReefReferral properly configured")
            await self.checkReferralStatuses()
        case .failure(let error):
            print(error)
        }
    }

    /// Asynchronously generates a referral link.
    ///
    /// - Returns: A `ReferralLink` with the link.
    /// - Throws: Throws a `ReefReferralError.missingAPIKey` error if the API key is missing.
    ///
    public func generateReferralLink() async throws -> ReferralLinkContent {

        guard let apiKey else { throw ReefReferralError.missingAPIKey }
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
            throw error
        }
    }

    
    /// Asynchronously checks referral statuses for a specific referral link.
    ///
    public func checkReferralStatuses() async {

        guard apiKey != nil else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        
        guard let link = reefData.referralLink else { return }
        
        let statusesRequest = ReferralStatusesRequest(link_id: link.id)
        let response = await ReefAPIClient.shared.send(statusesRequest)
        
        switch response {
        case .success(let statuses):
            if !statuses.isEmpty {
                self.delegate?.referralStatusChanged(statuses: statuses)
            }
        case .failure(let error):
            print(error)
        }
    }
    
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
        if let linkId = url.lastPathComponent.isEmpty ? nil : url.lastPathComponent {
            
            let request = HandleDeepLinkRequest(link_id: linkId, udid: reefData.udid)
            let response = await ReefAPIClient.shared.send(request)
            switch response {
            case .success(let result):
                reefData.referralId = result.referral.id
                reefData.save()
                self.delegate?.didReceiveReferral(linkID: linkId)
            case .failure(let failure):
                print(failure)
            }
            
        } else {
            print("Invalid deep link URL")
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
    
}

