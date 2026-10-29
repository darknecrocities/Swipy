import SwiftUI
import AppKit

/// Floating glassmorphic application switcher overlay.
public struct FloatingAppSwitcherView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AppSwitcherViewModel()

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Application Switcher")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "CCCCCC"))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.runningApps.enumerated()), id: \.offset) { index, app in
                        appIconCard(app: app, isSelected: index == viewModel.selectedIndex) {
                            viewModel.activate(app: app)
                            isPresented = false
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .frame(width: 480)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
        .onAppear {
            viewModel.refreshRunningApps()
        }
    }

    private func appIconCard(app: NSRunningApplication, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 44, height: 44)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "999999"))
                }

                Text(app.localizedName ?? "App")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "171717"))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: 80)
            .background(isSelected ? Color(hex: "F0F0F0") : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
