import Foundation


public protocol ReefReferralDelegate {
    func didRefer(statuses: [ReferralStatus])
    func didReceiveReferral(from: String)
}

public class ReefReferral {
        
    public static let shared = ReefReferral()
    private var apiKey: String? // currently app-id
    
    private var links : [String : URL] = [:]
    
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
    
    public func showReferralSheet() {
        // Implement code to display the referral sheet
        // This may involve presenting a UI screen for sharing the referral link
    }
    
    public func triggerReward() {
        // Implement code to trigger the reward condition
        // This is called when a referred user meets a specific condition defined by the developer
    }
    
//    public func checkReferralStatuses(linkID: String) async throws -> [ReferralStatus] {
//        guard let apiKey = apiKey else {
//            throw ReefReferralError.missingAPIKey
//        }
//        
//        return []
//    }
}

enum ReefReferralError: Error {
    case missingAPIKey
    case invalidURL
    case invalidAPIKey
}
