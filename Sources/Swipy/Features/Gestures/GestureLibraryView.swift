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
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gesture Library")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Text("Configure hand poses, assigned system actions, and individual gesture toggles.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "777777"))
            }
            Spacer()
            Button(action: {
                appState.settings.bindings = SwipySettings.defaultBindings
                appState.settings.save()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Reset Defaults")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "FAFAFA"))
                .foregroundColor(Color(hex: "171717"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(
                    title: "All (\(appState.settings.bindings.count))",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }
                ForEach(GestureCategory.allCases, id: \.self) { cat in
                    let count = appState.settings.bindings.filter { $0.category == cat }.count
                    filterPill(
                        title: "\(cat.rawValue) (\(count))",
                        isSelected: viewModel.selectedCategory == cat
                    ) {
                        viewModel.selectedCategory = cat
                    }
                }
            }
            .padding(.trailing, 16)
            .padding(.vertical, 2)
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
                    .frame(width: 34, height: 34)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "E8E8E8"), lineWidth: 1))
                Spacer()
                monochromePillSwitch(isOn: binding.isEnabled)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(binding.wrappedValue.gestureType.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                Menu {
                    ForEach(GestureAction.allCases, id: \.self) { act in
                        Button(act.rawValue) {
                            binding.wrappedValue.action = act
                            appState.settings.save()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(binding.wrappedValue.action.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "555555"))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(hex: "888888"))
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            HStack {
                Text(binding.wrappedValue.category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "F3F3F3"))
                    .foregroundColor(Color(hex: "666666"))
                    .cornerRadius(4)
                Spacer()
                Text(binding.wrappedValue.isEnabled ? "Active" : "Disabled")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(binding.wrappedValue.isEnabled ? Color(hex: "171717") : Color(hex: "999999"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }

    private func monochromePillSwitch(isOn: Binding<Bool>) -> some View {
        Button(action: {
            isOn.wrappedValue.toggle()
            appState.settings.save()
        }) {
            ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                Capsule()
                    .fill(isOn.wrappedValue ? Color(hex: "171717") : Color(hex: "E5E5E5"))
                    .frame(width: 38, height: 22)
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(.horizontal, 2)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
            }
            .animation(.easeOut(duration: 0.15), value: isOn.wrappedValue)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func gestureIcon(for type: GestureType) -> some View {
        let name: String = {
            switch type {
            case .indexPointing: return "hand.point.up.left"
            case .thumbIndexPinch: return "hand.pinch"
            case .pinchAndDrag: return "hand.draw"
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
            case .twoFingerTap: return "hand.tap"
            case .victorySign: return "v.circle"
            case .fistHold: return "lock.fill"
            }
        }()
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(hex: "171717"))
    }
}
