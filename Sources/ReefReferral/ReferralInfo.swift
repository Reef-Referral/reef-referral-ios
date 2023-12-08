import Foundation

extension ReefReferral {
    public struct ReferralStatus {
        public struct SenderStatus {
            public let linkURL: URL?
            public let redeemedCount: Int
            public let rewardEligibility: ReefReferral.SenderRewardStatus
            public let offerCodeURL: URL?
        }
        public struct ReceiverStatus {
            public let rewardEligibility: ReefReferral.ReceiverOfferStatus
            public let offerCodeURL: URL?
        }

        public let senderStatus: SenderStatus
        public let receiverStatus: ReceiverStatus
        public let userID: String

        internal init(_ reefData: ReefData) {
            let sender = SenderStatus(linkURL: reefData.senderInfo?.link.linkURL,
                                    redeemedCount: reefData.senderInfo?.redeemed ?? 0,
                                    rewardEligibility: reefData.senderInfo?.link.reward_status ?? .not_eligible,
                                    offerCodeURL: reefData.senderInfo?.link.rewardURL)

            let receiver = ReceiverStatus(rewardEligibility: reefData.receiverInfo?.referred_status ?? .not_eligible,
                                        offerCodeURL: reefData.receiverInfo?.appleOfferURL)

            senderStatus = sender
            receiverStatus = receiver
            userID = reefData.custom_id ?? reefData.udid
        }
    }

}
