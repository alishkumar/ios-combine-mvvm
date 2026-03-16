//
//  FaceTagStore.swift
//  Demo
//
//  Created by AI on 13/03/26.
//

import Foundation
import CoreGraphics

final class FaceTagStore {
    static let shared = FaceTagStore()

    private let defaults = UserDefaults.standard
    private let key = "face_tag_store_v1"

    private init() {}

    func tag(for assetId: String, boundingBox: CGRect) -> String? {
        let dict = loadAll()
        return dict[makeKey(assetId: assetId, boundingBox: boundingBox)]
    }

    func setTag(_ tag: String?, for assetId: String, boundingBox: CGRect) {
        var dict = loadAll()
        let key = makeKey(assetId: assetId, boundingBox: boundingBox)
        if let tag = tag, !tag.isEmpty {
            dict[key] = tag
        } else {
            dict.removeValue(forKey: key)
        }
        defaults.set(dict, forKey: keyStoreKey)
    }

    private var keyStoreKey: String { key }

    private func loadAll() -> [String: String] {
        defaults.dictionary(forKey: keyStoreKey) as? [String: String] ?? [:]
    }

    private func makeKey(assetId: String, boundingBox: CGRect) -> String {
        let f = { (v: CGFloat) in String(format: "%.4f", v) }
        return "\(assetId)|\(f(boundingBox.origin.x))|\(f(boundingBox.origin.y))|\(f(boundingBox.size.width))|\(f(boundingBox.size.height))"
    }
}
