//
//  WelcomeView.swift
//  durian.health
//
//  Introduction shown before sign-in, based on the fyp-website landing page.
//

import SwiftUI

struct WelcomeView: View {
    @State private var authMode: AuthFlowView.Mode?

    private struct Item: Identifiable {
        let icon: String
        let color: Color
        let title: String
        let text: String
        var id: String { title }
    }

    private let benefits = [
        Item(icon: "bolt.fill", color: .blue, title: "Rapid diagnosis",
             text: "Photograph a leaf and get a disease label in seconds."),
        Item(icon: "iphone", color: .orange, title: "Built for the field",
             text: "Scan straight from your phone camera as you walk the orchard."),
        Item(icon: "chart.line.uptrend.xyaxis", color: .durianGreen, title: "Track history",
             text: "Follow every tree's scans and your farm's health over time."),
    ]

    private let steps = [
        Item(icon: "camera.fill", color: .durianGreen, title: "Snap",
             text: "Take a clear photo of a single leaf."),
        Item(icon: "sparkles", color: .blue, title: "Diagnose",
             text: "The AI identifies the disease and how confident it is."),
        Item(icon: "checklist", color: .orange, title: "Act & track",
             text: "Save the result to the tree and watch its health over time."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                hero
                section("Why durian.health?", items: benefits, numbered: false)
                section("How it works", items: steps, numbered: true)
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) { actions }
        .sheet(item: $authMode) { mode in
            AuthFlowView(initialMode: mode)
        }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: 20) {
            Wordmark(size: 26)

            // The image fills a fixed frame as an overlay, so scaledToFill can't
            // widen the layout beyond the screen.
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .overlay {
                    Image("DurianFarm")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityElement()
                .accessibilityLabel("Durian farm")

            VStack(alignment: .leading, spacing: 10) {
                Text("Diagnose durian tree health")
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text("AI-powered leaf disease detection that helps Malaysian durian farmers spot problems early and track tree health over time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func section(_ title: String, items: [Item], numbered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title3.bold())
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 14) {
                        IconTile(systemName: item.icon, color: item.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(numbered ? "\(index + 1). \(item.title)" : item.title)
                                .font(.headline)
                            Text(item.text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    if index < items.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .card(padding: 16)
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("Farn Xin Yang · TP074541")
                .font(.footnote.weight(.semibold))
            Text("Improving durian tree health. Developed under the supervision of Dr. Kulothunkan A/L Palasundram.")
            Text("SDG 12: Responsible Consumption and Production")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Log In") { authMode = .login }
            SecondaryButton(title: "Create Account") { authMode = .register }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

#Preview {
    WelcomeView()
        .environment(AuthStore())
}
