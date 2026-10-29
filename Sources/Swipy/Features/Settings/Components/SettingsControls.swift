import SwiftUI
import SwipyCore

/// High-contrast reusable settings slider with formatted value readout.
public struct SettingsSliderRow: View {
    public let title: String
    public let subtitle: String?
    public let value: Binding<Double>
    public let range: ClosedRange<Double>
    public let step: Double
    public let format: String
    public let unit: String
    public let onCommit: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.05,
        format: String = "%.2f",
        unit: String = "",
        onCommit: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.range = range
        self.step = step
        self.format = format
        self.unit = unit
        self.onCommit = onCommit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "171717"))
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "777777"))
                    }
                }
                Spacer()
                Text(String(format: "%@%@", String(format: format, value.wrappedValue), unit))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "171717"))
            }

            Slider(value: value, in: range, step: step)
                .onChange(of: value.wrappedValue) {
                    onCommit()
                }
        }
        .padding(14)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}

/// High-contrast reusable switch toggle row with explicit charcoal typography and subtle gray track.
public struct SettingsToggleRow: View {
    public let title: String
    public let subtitle: String?
    public let isOn: Binding<Bool>
    public let onCommit: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        onCommit: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isOn = isOn
        self.onCommit = onCommit
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "171717"))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "777777"))
                }
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) {
                    onCommit()
                }
        }
        .padding(14)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "EAEAEA"), lineWidth: 1))
    }
}
