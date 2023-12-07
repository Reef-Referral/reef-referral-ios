import Foundation
import Logging
import UIKit
import Network


public protocol ReefReferralDelegate {
    func infoUpdated(referralInfo: ReefReferral.ReferralInfo)
}

public extension ReefReferralDelegate {
    func infoUpdated(referralInfo: ReefReferral.ReferralInfo) {}
}

public class ReefReferral {
    public static var logger = Logger(label: "com.reef-referral.logger")

    public static let shared = ReefReferral()
    public var delegate: ReefReferralDelegate?

    private let reefReferralInternal = ReefReferralInternal()


    public func start(apiKey: String, delegate: ReefReferralDelegate? = nil, logLevel: ReefReferral.LogLevel = .none) {
        self.delegate = delegate
        reefReferralInternal.start(apiKey: apiKey, delegate: self, logLevel: logLevel)
    }

    public func getReferralInfo(cached: Bool = true) async throws -> ReferralInfo {
        if cached {
            let new = try? await reefReferralInternal.status()
            if let newOrCached = new ?? getReferralInfoCached() {
                return newOrCached
            } else {
                throw ReefError.infoUnavailable
            }
        } else {
            return try await reefReferralInternal.status()
        }
    }

    public func getReferralInfoCached() -> ReferralInfo? {
        return ReferralInfo(reefReferralInternal.data)
    }

    public func setUserId(_ id : String) {
        reefReferralInternal.setUserId(id)
    }


    public func handleDeepLink(url: URL) {
        reefReferralInternal.handleDeepLink(url: url)
    }

    /// Helper function, use on UIWindowSceneDelegate.func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
    public func handleDeepLink(URLContexts: Set<UIOpenURLContext>) {
        for link in URLContexts {
            handleDeepLink(url: link.url)
        }
    }

    /// Helper function, use on UIWindowSceneDelegate.scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
    public func handleDeepLink(connectionOptions: UIScene.ConnectionOptions) {
        handleDeepLink(URLContexts: connectionOptions.urlContexts)
    }

    public func setUserID(id: String)  {
        reefReferralInternal.setUserId(id)
    }

    //MARK: Manual mode

    public func triggerSenderSuccess() {
        reefReferralInternal.triggerSenderSuccess()
    }

    public func triggerReceiverSuccess() {
        reefReferralInternal.triggerReceiverSuccess()
    }
}

extension ReefReferral: ReefReferralDelegatePassThrough {
    func infoUpdated(referralInfo: ReferralInfo) {
        delegate?.infoUpdated(referralInfo: referralInfo)
    }
}
