import Foundation

extension ReefReferral {
    public struct ReferralInfo {
        public struct SenderInfo {
            public let linkURL: URL?
            public let redeemedCount: Int
            public let rewardEligibility: ReefReferral.SenderRewardStatus
            public let offerCodeURL: URL?
        }
        public struct ReceiverInfo {
            public let rewardEligibility: ReefReferral.ReceiverOfferStatus
            public let offerCodeURL: URL?
        }

        public let senderInfo: SenderInfo
        public let receiverInfo: ReceiverInfo
        public let userID: String

        internal init(_ reefData: ReefData) {
            let sender = SenderInfo(linkURL: reefData.senderInfo?.link.linkURL,
                                    redeemedCount: reefData.senderInfo?.redeemed ?? 0,
                                    rewardEligibility: reefData.senderInfo?.link.reward_status ?? .not_eligible,
                                    offerCodeURL: reefData.senderInfo?.link.rewardURL)

            let receiver = ReceiverInfo(rewardEligibility: reefData.receiverInfo?.referred_status ?? .not_eligible,
                                        offerCodeURL: reefData.receiverInfo?.appleOfferURL)

            senderInfo = sender
            receiverInfo = receiver
            userID = reefData.udid
        }
    }

}
