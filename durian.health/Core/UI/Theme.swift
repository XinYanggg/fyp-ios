//
//  Theme.swift
//  durian.health
//
//  Shared colors and small building blocks for a consistent, minimal look.
//

import SwiftUI

extension Color {
    /// Brand green from the asset catalog: #16a34a in light mode (Android's primary),
    /// #22c55e in dark mode (the website's green).
    static let durianGreen = Color("BrandGreen")
}

// MARK: - Wordmark

/// "durian.health" with ".health" in brand green, as on Android.
struct Wordmark: View {
    var size: CGFloat = 28

    var body: some View {
        (Text("durian").foregroundStyle(.primary) + Text(".health").foregroundStyle(Color.durianGreen))
            .font(.system(size: size, weight: .bold, design: .rounded))
            .accessibilityLabel("durian.health")
    }
}

// MARK: - Cards

/// Rounded surface used for content blocks outside of Lists.
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardStyle(padding: padding)) }
}

/// Rounded square with an SF Symbol, tinted background.
struct IconTile: View {
    let systemName: String
    var color: Color = .durianGreen
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

// MARK: - Health

/// Horizontal bar showing the share of healthy trees.
struct HealthBar: View {
    /// 0...100
    let percent: Int
    var height: CGFloat = 8

    private var color: Color {
        switch percent {
        case 80...: .durianGreen
        case 50..<80: .orange
        default: .red
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.fill.tertiary)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("\(percent) percent healthy")
    }
}

// MARK: - Forms and buttons

/// Rounded text field container used by the auth forms.
struct FormFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension View {
    func formField() -> some View { modifier(FormFieldStyle()) }
}

/// Full-width filled button with a loading state.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            ZStack {
                Group {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                    } else {
                        Text(title)
                    }
                }
                .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(.white) }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                Color.durianGreen.opacity(isEnabled ? 1 : 0.4),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

/// Full-width tinted button for secondary actions.
struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(Color.durianGreen)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.durianGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
