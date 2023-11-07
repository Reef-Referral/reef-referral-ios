//
//  CouponRedemptionDetector.swift
//
//
//  Created by Alexis Creuzot on 31/10/2023.
//

import Foundation
import StoreKit

internal class CouponRedemptionDetector: NSObject, SKPaymentTransactionObserver {
    
    public var referredOfferCode : String?
    public var referringOfferCode : String?
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func checkForCouponRedemption() {
        let productIdentifiers: [String] = [referredOfferCode, referringOfferCode].compactMap {$0}
        let productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productsRequest.start()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                let productIdentifier = transaction.payment.productIdentifier
                switch productIdentifier {
                case referredOfferCode:
                    ReefReferral.shared.triggerReferralSuccess()
                case referringOfferCode:
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

