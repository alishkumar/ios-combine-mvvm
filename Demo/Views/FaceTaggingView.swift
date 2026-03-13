//
//  FaceTaggingView.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import SwiftUI
import Photos
import UIKit

struct FaceTaggingView: View {
    
    @StateObject private var viewModel = FaceTaggingViewModel()
    @State private var columnCount: Int = 2
    @State private var lastMagnification: CGFloat = 1.0
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: columnCount)
    }

    private var thumbnailSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width - 2
        let side = max(36, (screenWidth / CGFloat(columnCount)).rounded(.down))
        let scale = UIScreen.main.scale
        return CGSize(width: side * scale, height: side * scale)
    }
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.authorizationStatus {
                case .authorized, .limited:
                    authorizedContent
                case .notDetermined:
                    permissionRequestView
                default:
                    deniedView
                }
            }
            .navigationTitle("Face Tagging")
        }
        .onAppear {
            viewModel.refreshAuthorizationStatus()
        }
    }
    
    private var permissionRequestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Access Your Photos")
                .font(.title2.bold())
            
            Text("We need access to your photo library to detect faces and let you tag them.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.requestPermission()
            }) {
                Text(viewModel.isRequestingPermission ? "Requesting..." : "Allow Photo Access")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isRequestingPermission)
            .padding(.horizontal)
        }
    }
    
    private var deniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Photo Access Needed")
                .font(.title2.bold())
            
            Text("Please enable photo library access in Settings to use face tagging.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: openSettings) {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
    
    private var authorizedContent: some View {
        VStack {
            if viewModel.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scanning photos...")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    ProgressView(value: viewModel.scanProgress)
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)
                        .padding(.top, 4)
                    Text("\(Int(viewModel.scanProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            } else {
                Button(action: {
                    viewModel.startScan()
                }) {
                    Text(viewModel.facePhotos.isEmpty ? "Scan Photo Library" : "Rescan Library")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            if viewModel.facePhotos.isEmpty && !viewModel.isScanning {
                Spacer()
                Text("No faces detected yet.\nTap \"Scan Photo Library\" to get started.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 4) {
                        ForEach(viewModel.facePhotos) { photo in
                            FacePhotoCell(photo: photo, targetSize: thumbnailSize)
                        }
                    }
                    .padding(4)
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let zoomInThreshold: CGFloat = 0.05
                                let zoomOutThreshold: CGFloat = 0.05
                                if value - lastMagnification > zoomInThreshold {
                                    columnCount = max(2, columnCount - 1)
                                    lastMagnification = value
                                } else if lastMagnification - value > zoomOutThreshold {
                                    columnCount = min(4, columnCount + 1)
                                    lastMagnification = value
                                }
                            }
                            .onEnded { _ in
                                lastMagnification = 1.0
                            }
                    )
                }
            }
        }
    }
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

struct FacePhotoCell: View {
    let photo: FacePhoto
    let targetSize: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
            if let image = image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                        
                        ForEach(photo.faces) { face in
                            FaceBoundingBox(face: face, containerSize: geometry.size)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .overlay(
                            ProgressView()
                        )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(4)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        PhotoAssetImageCache.shared.image(for: photo.asset, targetSize: targetSize) { uiImage in
            self.image = uiImage
        }
    }
}

struct FaceBoundingBox: View {
    let face: DetectedFace
    let containerSize: CGSize
    
    var body: some View {
        let rect = convertedRect(from: face.boundingBox, in: containerSize)
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            
            if let tag = face.tag, !tag.isEmpty {
                Text(tag)
                    .font(.caption2.bold())
                    .padding(4)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: rect.minX + 4, y: rect.minY + 10)
            }
        }
    }
    
    private func convertedRect(from boundingBox: CGRect, in size: CGSize) -> CGRect {
        let width = boundingBox.size.width * size.width
        let height = boundingBox.size.height * size.height
        let x = boundingBox.origin.x * size.width
        let y = (1 - boundingBox.origin.y - boundingBox.size.height) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
