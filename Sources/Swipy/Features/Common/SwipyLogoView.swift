import SwiftUI
import AppKit

/// Resolution-independent brandmark view displaying the official Swipy squircle logo.
public struct SwipyLogoView: View {
    public let size: CGFloat
    public let cornerRadius: CGFloat
    public let showShadow: Bool

    public init(size: CGFloat = 32, cornerRadius: CGFloat? = nil, showShadow: Bool = false) {
        self.size = size
        self.cornerRadius = cornerRadius ?? (size * 0.22)
        self.showShadow = showShadow
    }

    public var body: some View {
        Group {
            if let image = loadLogoImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .cornerRadius(cornerRadius)
            } else {
                fallbackBrandmark
            }
        }
        .shadow(color: showShadow ? Color.black.opacity(0.12) : .clear, radius: 6, x: 0, y: 3)
    }

    private var fallbackBrandmark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(hex: "171717"))
            Image(systemName: "hand.tap.fill")
                .font(.system(size: size * 0.48))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }

    private func loadLogoImage() -> NSImage? {
        // Priority 1: App bundle resource
        if let bundlePath = Bundle.main.path(forResource: "AppLogo", ofType: "png"),
           let image = NSImage(contentsOfFile: bundlePath) {
            return image
        }
        // Priority 2: Workspace relative resource path
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let directPath = "\(currentDir)/Resources/AppLogo.png"
        if let image = NSImage(contentsOfFile: directPath) {
            return image
        }
        return nil
    }
}
