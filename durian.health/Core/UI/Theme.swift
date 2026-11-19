//
//  Theme.swift
//  durian.health
//

import SwiftUI

extension Color {
    /// Brand green, matching the website (#22c55e).
    static let durianGreen = Color(red: 0x22 / 255, green: 0xC5 / 255, blue: 0x5E / 255)
}

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

/// Full-width primary button with a loading state.
struct PrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(.white) }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.durianGreen)
        .controlSize(.large)
        .disabled(isLoading)
    }
}
