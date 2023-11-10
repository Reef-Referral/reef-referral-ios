//
//  ReferralSheetView.swift
//
//
//  Created by Alexis Creuzot on 09/11/2023.
//

import Foundation
import SwiftUI
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func load(fromURL url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if image == nil {
                    print("Error: Failed to load image")
                }
                self?.image = image
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct LazyImageView: View {
    @StateObject private var loader = ImageLoader()
    
    let url: URL?
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if let url = url {
                loader.load(fromURL: url)
            }
        }
    }
}

public struct ReefReferralSheetView: View {
    let imageURL: URL
    let title: String
    let subtitle: String
    let description: String
    let footnote: String
    
    @ObservedObject private var reef = ReefReferral.shared

    public init(imageURL: URL, title: String, subtitle: String, description: String, footnote: String) {
        self.imageURL = imageURL
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.footnote = footnote
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack {
                LazyImageView(url: imageURL)
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
                                        // Handle invite action
                }) {
                    
                    switch reef.rewardEligibility {
                    case .not_eligible:
                        Text("Invite")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                    case .eligible:
                        Text("Claim Reward!")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                    case .granted:
                        Text("Reward Already Claimed")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(Color.gray)
                    }
                    
                }
                
                .cornerRadius(10)
                
                Spacer()
                
                VStack(spacing:8) {
                    if reef.receivedCount > 0 {
                        Text("\(reef.receivedCount) invitation received")
                            .bold()
                    }
                    if reef.successCount > 0 {
                        Text("\(reef.successCount) referral successes")
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                
                Spacer()
                Text(footnote)
                    .font(.footnote)
                
            }
        }
    }
}


