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
    private var referralID : String? // ID received after handleDeepLink, used to notify server of referral reception and success
    private var referralLinkID : String? // LinkID sent to potential referrees
    
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
        case .failure(let error):
            print(error)
        }
    }

    /// Asynchronously generates a referral link.
    ///
    /// - Returns: A `ReferralLink` object representing the generated link.
    /// - Throws: Throws a `ReefReferralError.missingAPIKey` error if the API key is missing.
    ///
    public func generateReferralLink() async throws -> ReferralLink {

        guard let apiKey else { throw ReefReferralError.missingAPIKey }
        
        let request = ReferralLinkRequest(app_id: apiKey)
        let response = await ReefAPIClient.shared.send(request)
        switch response {
        case .success(let result):
            self.referralLinkID = result.link.id
            return result
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
        
        guard let referralLinkID else { return }
        
        let statusesRequest = ReferralStatusesRequest(link_id: referralLinkID)
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
    
    /// Asynchronously handles deep links with the given linkId and udid parameters.
    ///
    /// - Parameters:
    ///   - linkId: The unique identifier for the deep link.
    ///   - udid: The unique device identifier.
    ///
    public func handleDeepLink(linkId: String, udid: String) async {
        guard apiKey != nil else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        let request = HandleDeepLinkRequest(link_id: linkId, udid: udid)
        _ = await ReefAPIClient.shared.send(request)
    }
    
    /// Asynchronously triggers a referral success event with the given referralID parameter.
    ///
    /// - Parameters:
    ///   - referralID: The unique identifier for the referral.
    ///
    public func triggerReferralSuccess(referralID: String) async {
        guard apiKey != nil else {
            print("Missing API key, did you forgot to initialize ReefReferal SDK ?")
            return
        }
        let request = NotifyReferralSuccessRequest(referral_id: referralID)
        _ = await ReefAPIClient.shared.send(request)
    }
    
}

