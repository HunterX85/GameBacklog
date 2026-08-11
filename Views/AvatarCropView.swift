//
//  AvatarCropView.swift
//  GameBacklog
//
//  Created by Serhii Pershuta on 11.08.2026.
//

import SwiftUI

struct AvatarCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onCrop: (Data) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropDiameter: CGFloat = 300
    private let maxUserScale: CGFloat = 4

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: displaySize.width, height: displaySize.height)
                        .position(
                            x: geometry.size.width / 2 + offset.width,
                            y: geometry.size.height / 2 + offset.height
                        )

                    cropOverlay(containerSize: geometry.size)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(dragGesture.simultaneously(with: magnificationGesture))
            }
            .navigationTitle(String(localized: "profile.crop.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "profile.button.cancel"), action: onCancel)
                        .tint(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "profile.button.done"), action: crop)
                        .tint(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var fitScale: CGFloat {
        guard image.size.width > 0, image.size.height > 0 else { return 1 }
        return max(cropDiameter / image.size.width, cropDiameter / image.size.height)
    }

    private var displaySize: CGSize {
        CGSize(
            width: image.size.width * fitScale * scale,
            height: image.size.height * fitScale * scale
        )
    }

    private func cropOverlay(containerSize: CGSize) -> some View {
        ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: containerSize))
                path.addEllipse(in: CGRect(
                    x: (containerSize.width - cropDiameter) / 2,
                    y: (containerSize.height - cropDiameter) / 2,
                    width: cropDiameter,
                    height: cropDiameter
                ))
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))

            Circle()
                .strokeBorder(Color.white, lineWidth: 2)
                .frame(width: cropDiameter, height: cropDiameter)
        }
        .allowsHitTesting(false)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                clampOffset()
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), maxUserScale)
                clampOffset()
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private func clampOffset() {
        let maxOffsetX = max(0, (displaySize.width - cropDiameter) / 2)
        let maxOffsetY = max(0, (displaySize.height - cropDiameter) / 2)
        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
    }

    private func crop() {
        let parameters = AvatarImageProcessor.CropParameters(
            displaySize: displaySize,
            cropDiameter: cropDiameter,
            offset: offset
        )
        guard let data = AvatarImageProcessor.crop(image, parameters: parameters) else {
            onCancel()
            return
        }
        onCrop(data)
    }
}

#Preview {
    AvatarCropView(image: UIImage(systemName: "photo")!, onCancel: {}, onCrop: { _ in })
}
