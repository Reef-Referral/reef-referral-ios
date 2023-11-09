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
            .sink { [weak self] in self?.image = $0 }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct LazyImageView: View {
    @StateObject private var loader = ImageLoader()
    
    let url: URL?
    let placeholderImage: UIImage?
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let placeholderImage {
                Image(uiImage: placeholderImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .onAppear {
            if let url = url {
                loader.load(fromURL: url)
            }
        }
    }
}

struct ReferralSheetView: View {
    
    let imageURL: URL
    let title: String
    let subtitle: String
    let description: String
    let footnote: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                
                LazyImageView(url: imageURL, placeholderImage: nil)
                
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                Text(description)
                    .font(.body)
                Button("Invite") {
                    // Handle invite action
                }
                Text(footnote)
                    .font(.footnote)
            }
            .padding()
        }
    }
}

