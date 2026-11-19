import Foundation
import SwiftUI
import UIKit
import ImageIO

// MARK: - Native GPU-Accelerated GIF Player
public struct AnimatedGIFView: UIViewRepresentable {
    public let data: Data?
    public let contentMode: UIView.ContentMode

    public init(data: Data?, contentMode: UIView.ContentMode = .scaleAspectFit) {
        self.data = data
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        return imageView
    }

    public func updateUIView(_ uiView: UIImageView, context: Context) {
        guard let data = data else {
            uiView.stopAnimating()
            uiView.image = nil
            return
        }

        if let (images, duration) = decodeGIF(data: data) {
            uiView.animationImages = images
            uiView.animationDuration = duration
            uiView.animationRepeatCount = 0 // Infinite loop
            uiView.image = images.first // Display first frame immediately
            if !uiView.isAnimating {
                uiView.startAnimating()
            }
        }
    }

    private func decodeGIF(data: Data) -> ([UIImage], TimeInterval)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        if count == 1 {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                return ([UIImage(cgImage: cgImage)], 1.0)
            }
            return nil
        }

        var images: [UIImage] = []
        var totalDuration: TimeInterval = 0.0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))

                var frameDuration: TimeInterval = 0.1
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                   let gifDict = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                    if let delay = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? Double, delay > 0.01 {
                        frameDuration = delay
                    } else if let delay = gifDict[kCGImagePropertyGIFDelayTime] as? Double, delay > 0.01 {
                        frameDuration = delay
                    }
                }
                totalDuration += frameDuration
            }
        }

        if totalDuration <= 0.0 { totalDuration = Double(count) * 0.1 }
        return (images, totalDuration)
    }
}

// MARK: - Animated Exercise Preview Card (Only Authenticated Animated GIFs)
public struct AnimatedExercisePreviewCard: View {
    public let exercise: Exercise

    public init(exercise: Exercise) {
        self.exercise = exercise
    }

    private var gifData: Data? {
        ExerciseIllustrationService.shared.gifData(for: exercise.name)
    }

    public var body: some View {
        if let data = gifData {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BEWEGUNGSVORSCHAU")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(GymTheme.cyanAccent)

                        Text("Animierte Ausführung (Looping)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(GymTheme.finishGreen)
                            .frame(width: 6, height: 6)
                        Text("ANIMIERT")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.finishGreen)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(GymTheme.finishGreen.opacity(0.12))
                    .cornerRadius(4)
                }

                // Looping GIF Display
                ZStack(alignment: .bottomTrailing) {
                    AnimatedGIFView(data: data)
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)

                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 9, weight: .bold))
                        Text("LOOP")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color.black.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(4)
                    .padding(8)
                }
            }
            .padding(16)
            .background(GymTheme.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(GymTheme.cyanAccent.opacity(0.25), lineWidth: 1)
            )
        } else {
            // Strict Instruction: If no animated asset exists on hasaneyldrm dataset, let it be (no static drawings)
            EmptyView()
        }
    }
}
