//
//  ReferralSheetView.swift
//
//
//  Created by Alexis Creuzot on 09/11/2023.
//

import SwiftUI
import Foundation
import Combine

public struct ReefReferralSheetView: View {
    
    let apiKey: String
    
    let image: UIImage
    let title: String
    let subtitle: String
    let description: String
    let footnote: String
    
    @ObservedObject private var reef = ReefReferral.shared

    public init(apiKey:String,image: UIImage, title: String, subtitle: String, description: String, footnote: String) {
        self.apiKey = apiKey
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.footnote = footnote
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height / 3)
                VStack(alignment: .center, spacing: 16) {
                    Text(title)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(subtitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                    
                Spacer()
                Button(action: {
                    switch reef.senderRewardEligibility {
                    case .not_eligible:
                        if let senderLinkURL = reef.senderLinkURL {
                            UIApplication.shared.open(senderLinkURL)
                        } else {
                            ReefReferral.logger.error("No referredOfferURL")
                        }
                    case .eligible:
                        if let rewardURL = reef.senderRewardCodeURL{
                            UIApplication.shared.open(rewardURL)
                        } else {
                            ReefReferral.logger.error("No rewardURL")
                        }
                    default:
                        break
                    }
                    
                }) {
                    switch reef.senderRewardEligibility {
                    case .not_eligible:
                        HStack(spacing: 8) {
                            Text("Invite friends")
                                .foregroundColor(.white)
                                .font(.headline)
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.blue)
                        
                    case .eligible:
                        HStack(spacing: 8){
                            Text("Claim Reward!")
                                .foregroundColor(.white)
                                .font(.headline)
                            Image(systemName: "gift.fill")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.green)
                    case .redeemed:
                            HStack(spacing: 8){
                                Text("Reward Already Claimed")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color.gray)
                    }
                
                }
                
                .cornerRadius(10)
                
                Spacer()
                
                VStack(spacing:8) {
                    if reef.senderLinkReceivedCount > 0 {
                        Text("\(reef.senderLinkReceivedCount) invitation received")
                            .bold()
                    }
                    if reef.senderLinkRedeemedCount > 0 {
                        Text("\(reef.senderLinkRedeemedCount) referral successes")
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                
                Spacer()
                Text(footnote)
                    .font(.footnote)
                
            }
            .onOpenURL { url in
                reef.handleDeepLink(url: url)
            }
            .onAppear {
                reef.start(apiKey: apiKey)
            }
        }
    }
    
}


