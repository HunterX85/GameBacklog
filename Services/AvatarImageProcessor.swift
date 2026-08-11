//
//  AvatarImageProcessor.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.08.2026.
//

import UIKit
import ImageIO

enum AvatarImageProcessor {
    static let maxSourceDimension: CGFloat = 1600
    static let outputDimension: CGFloat = 640
    static let jpegCompressionQuality: CGFloat = 0.85

    struct CropParameters {
        let displaySize: CGSize
        let cropDiameter: CGFloat
        let offset: CGSize
    }

    /// Decodes image data directly at a bounded pixel size using ImageIO.
    /// Avoids materializing the full-resolution bitmap in memory, which can
    /// exceed 100MB for modern camera originals (e.g. 48MP HEIC).
    static func downsampledImage(from data: Data, maxDimension: CGFloat = maxSourceDimension) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Renders the circular crop selection as a square JPEG. Re-rasterizing through
    /// UIGraphicsImageRenderer also strips any EXIF/GPS metadata from the original photo.
    static func crop(
        _ image: UIImage,
        parameters: CropParameters,
        outputDimension: CGFloat = outputDimension
    ) -> Data? {
        guard parameters.cropDiameter > 0, image.size.width > 0, image.size.height > 0 else { return nil }

        let renderScale = outputDimension / parameters.cropDiameter
        let scaledDisplaySize = CGSize(
            width: parameters.displaySize.width * renderScale,
            height: parameters.displaySize.height * renderScale
        )
        let origin = CGPoint(
            x: (outputDimension - scaledDisplaySize.width) / 2 + parameters.offset.width * renderScale,
            y: (outputDimension - scaledDisplaySize.height) / 2 + parameters.offset.height * renderScale
        )

        // Without an explicit scale, UIGraphicsImageRenderer defaults to the main
        // screen's scale (e.g. 3x), silently tripling `outputDimension` in actual
        // pixels. Pinning scale to 1 makes the output exactly outputDimension×outputDimension px.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: outputDimension, height: outputDimension),
            format: format
        )
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledDisplaySize))
        }
        return rendered.jpegData(compressionQuality: jpegCompressionQuality)
    }
}
