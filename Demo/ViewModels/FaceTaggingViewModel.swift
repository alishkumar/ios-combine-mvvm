//
//  FaceTaggingViewModel.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import Foundation
import Photos
import Combine

@MainActor
final class FaceTaggingViewModel: ObservableObject {
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isRequestingPermission = false
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var facePhotos: [FacePhoto] = []
    @Published var errorMessage: String?
    
    private let service: PhotoFaceServiceProtocol
    
    struct FaceGroup: Identifiable {
        let id: String
        let name: String
        let samplePhoto: FacePhoto
        let count: Int
    }

    
    init(service: PhotoFaceServiceProtocol = PhotoFaceService()) {
        self.service = service
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    var faceGroups: [FaceGroup] {
        var photosByName: [String: Set<String>] = [:]
        var sampleByName: [String: FacePhoto] = [:]
        
        for photo in facePhotos {
            let tags = Set(photo.faces.compactMap { face in
                face.tag?.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty })
            
            for name in tags {
                if sampleByName[name] == nil {
                    sampleByName[name] = photo
                }
                var set = photosByName[name] ?? []
                set.insert(photo.id)
                photosByName[name] = set
            }
        }
        
        return photosByName.compactMap { name, ids in
            guard let sample = sampleByName[name] else { return nil }
            return FaceGroup(id: name, name: name, samplePhoto: sample, count: ids.count)
        }
        .sorted { $0.name < $1.name }
    }

    
    func refreshAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestPermission() {
        guard authorizationStatus == .notDetermined else { return }
        isRequestingPermission = true
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.isRequestingPermission = false
            }
        }
    }
    
    func startScan() {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            errorMessage = "Please allow access to Photos in Settings."
            return
        }
        guard !isScanning else { return }
        
        isScanning = true
        scanProgress = 0
        errorMessage = nil
        facePhotos.removeAll()
        
        Task {
            do {
                let result = try await service.scanLibrary { [weak self] progress in
                    self?.scanProgress = progress
                }
                let mapped = result.map { pair in
                    FacePhoto(id: pair.0.localIdentifier, asset: pair.0, faces: pair.1)
                }
                await MainActor.run {
                    self.facePhotos = mapped
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }
    
    func updateTag(for photo: FacePhoto, face: DetectedFace, name: String) {
        guard let photoIndex = facePhotos.firstIndex(where: { $0.id == photo.id }) else { return }
        var updatedPhoto = facePhotos[photoIndex]
        
        if let faceIndex = updatedPhoto.faces.firstIndex(where: { $0.id == face.id }) {
            var updatedFace = updatedPhoto.faces[faceIndex]
            updatedFace.tag = name.isEmpty ? nil : name
            updatedPhoto.faces[faceIndex] = updatedFace
        }
        
        facePhotos[photoIndex] = updatedPhoto
    }
}
