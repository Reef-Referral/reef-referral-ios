//
//  CouponRedemptionDetector.swift
//
//
//  Created by Alexis Creuzot on 31/10/2023.
//

import Foundation
import StoreKit

internal class CouponRedemptionDetector: NSObject, SKPaymentTransactionObserver {
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func checkForCouponRedemption(productIdentifiers: [String]) {
        let productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productsRequest.start()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                let productIdentifier = transaction.payment.productIdentifier
                switch productIdentifier {
                case ReefReferral.shared.data.referralInfo?.offer.referral_offer_code:
                    ReefReferral.shared.triggerReferralSuccess()
                case ReefReferral.shared.data.referralInfo?.offer.referring_offer_code:
                    ReefReferral.shared.triggerReferringSuccess()
                default:
                    ReefReferral.logger.debug("Unknown productIdentifier \(productIdentifier), ignoring")
                }
                
                break
            default:
                break
            }
        }
    }
}

