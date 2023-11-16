//
//  CouponRedemptionDetector.swift
//
//
//  Created by Alexis Creuzot on 31/10/2023.
//

import Foundation
import StoreKit

internal class CouponRedemptionDetector: NSObject, SKPaymentTransactionObserver {
    
    public var receiverOfferId : String?
    public var senderRewardOfferId : String?
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func checkForCouponRedemption() {
        let productIdentifiers: [String] = [receiverOfferId, senderRewardOfferId].compactMap {$0}
        let productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        productsRequest.start()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                let productIdentifier = transaction.payment.productIdentifier
                switch productIdentifier {
                case receiverOfferId:
                    ReefReferral.shared.triggerReceiverSuccess()
                case senderRewardOfferId:
                    ReefReferral.shared.triggerSenderSuccess()
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

