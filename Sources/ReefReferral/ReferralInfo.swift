import Foundation

extension ReefReferral {
    public struct ReferralStatus {
        public struct SenderStatus {
            /// URL of the referral page generated for the current user
            public let linkURL: URL?

            /// Number of times that the current user's offer has been redeemed
            public let redeemedCount: Int

            /// Eligibility of the current users to receive the sender's reward
            public let rewardEligibility: ReefReferral.SenderRewardStatus

            /// How many referred users needed for the sender user to be eligible
            public let offerEligibilityCount: Int?

            /// URL to claim the offer code for the sender's reward.
            /// Has value only when `rewardEligibility == .eligible`
            public let offerCodeURL: URL?
        }
        public struct ReceiverStatus {
            /// Eligibility of the current users to receive the receiver's reward
            public let rewardEligibility: ReefReferral.ReceiverOfferStatus

            /// URL to claim the offer code for the receiver's reward.
            /// Has value only when `rewardEligibility == .eligible`
            public let offerCodeURL: URL?
        }

        /// Status of the current user as a sender of the referral offer
        public let senderStatus: SenderStatus

        /// Status of the current user as a receiver of the referral offer
        public let receiverStatus: ReceiverStatus

        /// Current user id. By default it's a generated anonymous id but can be set with `ReefReferral.shared.setUserId(_:String)
        public let userID: String

        internal init(_ reefData: ReefData) {
            let sender = SenderStatus(linkURL: reefData.senderInfo?.link.linkURL,
                                    redeemedCount: reefData.senderInfo?.redeemed ?? 0,
                                      rewardEligibility: reefData.senderInfo?.link.reward_status ?? .not_eligible,
                                      offerEligibilityCount: reefData.senderInfo?.offer.referring_offer_eligibility,
                                    offerCodeURL: reefData.senderInfo?.link.rewardURL)

            let receiver = ReceiverStatus(rewardEligibility: reefData.receiverInfo?.referred_status ?? .not_eligible,
                                        offerCodeURL: reefData.receiverInfo?.appleOfferURL)

            senderStatus = sender
            receiverStatus = receiver
            userID = reefData.id
        }
    }

}
