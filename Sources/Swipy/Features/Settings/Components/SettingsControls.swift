import SwiftUI
import SwipyCore

/// High-contrast interactive custom slider bar with clearly visible track, active progress fill, and draggable knob.
public struct CustomSliderBar: View {
    @Binding var value: Double
    public let range: ClosedRange<Double>
    public let step: Double
    public let onCommit: () -> Void

    public init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.05,
        onCommit: @escaping () -> Void = {}
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.onCommit = onCommit
    }

    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let knobDiameter: CGFloat = 16
            let usableWidth = max(1.0, totalWidth - knobDiameter)
            let span = max(0.0001, range.upperBound - range.lowerBound)
            let clampedVal = max(range.lowerBound, min(range.upperBound, value))
            let fraction = CGFloat((clampedVal - range.lowerBound) / span)
            let knobX = fraction * usableWidth + (knobDiameter / 2)

            ZStack(alignment: .leading) {
                // Background Track: Crisp, visible 6px bar with subtle stroke
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "E0E0E0"))
                    .frame(height: 6)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: "D0D0D0"), lineWidth: 0.5))

                // Active Progress Fill: High-contrast charcoal/black bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "171717"))
                    .frame(width: max(0, knobX), height: 6)

                // Draggable Tactile Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .overlay(Circle().stroke(Color(hex: "BFBFBF"), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                    .offset(x: knobX - (knobDiameter / 2))
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let locationX = max(0, min(totalWidth, gesture.location.x))
                        let rawFraction = Double(locationX / totalWidth)
                        let rawValue = range.lowerBound + rawFraction * span
                        let stepped = (rawValue / step).rounded() * step
                        let newValue = max(range.lowerBound, min(range.upperBound, stepped))
                        value = newValue
                        onCommit()
                    }
            )
        }
        .frame(height: 22)
    }
}

/// High-contrast reusable settings slider with formatted value readout and visible track bar.
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
        VStack(alignment: .leading, spacing: 10) {
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

            CustomSliderBar(
                value: value,
                range: range,
                step: step,
                onCommit: onCommit
            )
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
