import Foundation

public class ReefReferral {
    
    public typealias RewardCallback = (() -> Void)?
    
    public static let shared = ReefReferral()
    public var rewardCallBack: RewardCallback?
    private var apiKey: String?
    
    
    public func start(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func showReferralSheet() {
        // Implement code to display the referral sheet
        // This may involve presenting a UI screen for sharing the referral link
    }
    
    public func triggerReward() {
        // Implement code to trigger the reward condition
        // This is called when a referred user meets a specific condition defined by the developer
    }
    
    public func checkReferralStatuses(linkID: String) async throws -> [ReferralStatus] {
        guard let apiKey = apiKey else {
            throw ReefReferralError.missingAPIKey
        }
        
        return []
    }
}

enum ReefReferralError: Error {
    case missingAPIKey
    case invalidURL
    case invalidAPIKey
}
