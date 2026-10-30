import SwiftUI
import SwipyCore

/// Visual library detailing all supported gestures with illustration, action mapping, and toggle controls.
public struct GestureLibraryView: View {
    @ObservedObject var appState: AppLifecycleManager
    @StateObject private var viewModel = GestureLibraryViewModel()

    public init(appState: AppLifecycleManager) {
        self.appState = appState
    }

    private var filteredBindings: [GestureBinding] {
        if let cat = viewModel.selectedCategory {
            return appState.settings.bindings.filter { $0.category == cat }
        }
        return appState.settings.bindings
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerView
                categoryFilterBar
                gesturesGrid
            }
            .padding(32)
        }
        .background(Color.white)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gesture Library")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Color(hex: "171717"))
            Text("Configure hand poses, assigned system actions, and individual gesture toggles.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "777777"))
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    viewModel.selectedCategory = nil
                }
                ForEach(GestureCategory.allCases, id: \.self) { cat in
                    filterPill(title: cat.rawValue, isSelected: viewModel.selectedCategory == cat) {
                        viewModel.selectedCategory = cat
                    }
                }
            }
        }
    }

    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "171717") : Color(hex: "FAFAFA"))
                .foregroundColor(isSelected ? .white : Color(hex: "777777"))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var gesturesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach($appState.settings.bindings) { $binding in
                if viewModel.selectedCategory == nil || binding.category == viewModel.selectedCategory {
                    gestureCard(binding: $binding)
                }
            }
        }
    }

    private func gestureCard(binding: Binding<GestureBinding>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                gestureIcon(for: binding.wrappedValue.gestureType)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "FAFAFA"))
                    .cornerRadius(8)
                Spacer()
                Toggle("", isOn: binding.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: binding.wrappedValue.isEnabled) {
                        appState.settings.save()
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(binding.wrappedValue.gestureType.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text(binding.wrappedValue.action.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "777777"))
            }

            HStack {
                Text(binding.wrappedValue.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "F3F3F3"))
                    .foregroundColor(Color(hex: "777777"))
                    .cornerRadius(4)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    @ViewBuilder
    private func gestureIcon(for type: GestureType) -> some View {
        let name: String = {
            switch type {
            case .indexPointing: return "hand.point.up.left"
            case .thumbIndexPinch: return "hand.pinch"
            case .thumbMiddlePinch: return "hand.tap"
            case .thumbMiddleZoom: return "plus.magnifyingglass"
            case .doublePinch: return "hand.tap.fill"
            case .twoFingerScroll: return "arrow.up.and.down"
            case .threeFingerSwipeUp: return "arrow.up"
            case .threeFingerSwipeDown: return "arrow.down"
            case .threeFingerSwipeLeft: return "arrow.left"
            case .threeFingerSwipeRight: return "arrow.right"
            case .fourFingerSwipeLeft: return "square.grid.2x2"
            case .fourFingerSwipeRight: return "square.grid.2x2.fill"
            case .twoHandZoom: return "arrow.up.left.and.arrow.down.right"
            case .openPalmsPause: return "hand.raised"
            }
        }()
        Image(systemName: name)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "171717"))
    }
}
