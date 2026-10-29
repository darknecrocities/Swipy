import SwiftUI

/// View model managing active settings category tabs.
@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var selectedTab: String = "Cursor"

    public init() {}
}
