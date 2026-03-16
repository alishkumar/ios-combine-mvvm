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
    @State private var isPresentingTagSheet = false
    @State private var currentTagName: String = ""
    @State private var selectedPhoto: FacePhoto?
    @State private var selectedFace: DetectedFace?
    @State private var columnCount: Int = 2
    @State private var lastMagnification: CGFloat = 1.0
    @State private var cachedRange: Range<Int>?

    private let cachingManager = PHCachingImageManager()
    
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
        .sheet(isPresented: $isPresentingTagSheet) {
            if let photo = selectedPhoto, let face = selectedFace {
                TagFaceSheet(photo: photo, face: face, name: $currentTagName) {
                    viewModel.updateTag(for: photo, face: face, name: currentTagName)
                }
            } else {
                VStack(spacing: 12) {
                    Text("No photo selected")
                        .font(.headline)
                    Text("Please tap a face to tag it.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
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
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 10)
                            .frame(width: 90, height: 90)

                        Circle()
                            .trim(from: 0, to: viewModel.scanProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 90, height: 90)

                        Text("\(Int(viewModel.scanProgress * 100))%")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 4) {
                        Text("Scanning Photos")
                            .font(.headline)
                        Text("Detecting faces in your library")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
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
                        ForEach(Array(viewModel.facePhotos.enumerated()), id: \.element.id) { index, photo in
                            FacePhotoCell(photo: photo, targetSize: thumbnailSize) { face in
                                selectedPhoto = photo
                                selectedFace = face
                                currentTagName = face.tag ?? ""
                                isPresentingTagSheet = true
                            }
                            .onAppear {
                                updatePreheatCache(centerIndex: index)
                            }
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

    private func updatePreheatCache(centerIndex: Int) {
        let total = viewModel.facePhotos.count
        guard total > 0 else { return }

        let start = max(0, centerIndex - 5)
        let end = min(total, centerIndex + 6)
        let newRange = start ..< end

        if cachedRange == newRange { return }

        if let cachedRange = cachedRange {
            let oldAssets = cachedRange.map { viewModel.facePhotos[$0].asset }
            cachingManager.stopCachingImages(for: oldAssets,
                                             targetSize: thumbnailSize,
                                             contentMode: .aspectFill,
                                             options: nil)
        }

        let newAssets = newRange.map { viewModel.facePhotos[$0].asset }
        cachingManager.startCachingImages(for: newAssets,
                                          targetSize: thumbnailSize,
                                          contentMode: .aspectFill,
                                          options: nil)
        cachedRange = newRange
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
    let onFaceTap: (DetectedFace) -> Void
    
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
                            FaceBoundingBox(face: face,
                                            containerSize: geometry.size,
                                            imageSize: image.size,
                                            isAspectFill: true)
                                .onTapGesture {
                                    onFaceTap(face)
                                }
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
    let imageSize: CGSize?
    let isAspectFill: Bool
    
    var body: some View {
        let rect = convertedRect(from: face.boundingBox, in: containerSize, imageSize: imageSize, isAspectFill: isAspectFill)
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
    
    private func convertedRect(from boundingBox: CGRect,
                               in size: CGSize,
                               imageSize: CGSize?,
                               isAspectFill: Bool) -> CGRect {
        guard let imageSize = imageSize, imageSize.width > 0, imageSize.height > 0 else {
            let width = boundingBox.size.width * size.width
            let height = boundingBox.size.height * size.height
            let x = boundingBox.origin.x * size.width
            let y = (1 - boundingBox.origin.y - boundingBox.size.height) * size.height
            return CGRect(x: x, y: y, width: width, height: height)
        }

        let scaleW = size.width / imageSize.width
        let scaleH = size.height / imageSize.height
        let scale = isAspectFill ? max(scaleW, scaleH) : min(scaleW, scaleH)
        let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let xOffset = (scaledImageSize.width - size.width) / 2
        let yOffset = (scaledImageSize.height - size.height) / 2

        let faceRectInImage = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
            width: boundingBox.size.width * imageSize.width,
            height: boundingBox.size.height * imageSize.height
        )

        let scaledRect = CGRect(
            x: faceRectInImage.origin.x * scale - xOffset,
            y: faceRectInImage.origin.y * scale - yOffset,
            width: faceRectInImage.size.width * scale,
            height: faceRectInImage.size.height * scale
        )

        return scaledRect
    }
}

struct TagFaceSheet: View {
    let photo: FacePhoto
    let face: DetectedFace
    @Binding var name: String
    var onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    if let image = image {
                        GeometryReader { geometry in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .overlay(
                                    FaceBoundingBox(face: face,
                                                    containerSize: geometry.size,
                                                    imageSize: image.size,
                                                    isAspectFill: false)
                                )
                        }
                        .frame(height: 220)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 220)
                            .overlay(ProgressView())
                    }
                }
                
                Text("Enter a name for this person.")
                    .font(.headline)
                
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Tag Face")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let targetSize = CGSize(width: 1000, height: 1000)
        PhotoAssetImageCache.shared.image(for: photo.asset,
                                          targetSize: targetSize,
                                          contentMode: .aspectFit) { uiImage in
            self.image = uiImage
        }
    }
}
