import SwiftUI
import SwipyCore

/// View model managing active category filter for the gesture library.
@MainActor
public final class GestureLibraryViewModel: ObservableObject {
    @Published public var selectedCategory: GestureCategory? = nil

    public init() {}
}
