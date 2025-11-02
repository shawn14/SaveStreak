//
//  PaywallView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreManager.shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Features List
                    featuresList

                    // Pricing Options
                    pricingSection

                    // Purchase Button
                    purchaseButton

                    // Restore Button
                    restoreButton

                    // Footer
                    footer
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isPurchasing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    }
                }
            }
        }
        .task {
            // Select yearly by default (better value)
            if selectedProduct == nil {
                selectedProduct = storeManager.yearlyProduct ?? storeManager.monthlyProduct
            }
        }
    }

    // MARK: - Header
    @ViewBuilder
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("SaveStreak Premium")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock unlimited goals and powerful features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    // MARK: - Features List
    @ViewBuilder
    private var featuresList: some View {
        VStack(spacing: 16) {
            featureRow(
                icon: "infinity",
                title: "Unlimited Goals",
                description: "Track as many savings goals as you want"
            )

            featureRow(
                icon: "bell.badge.fill",
                title: "Multiple Reminders",
                description: "Morning reminder + evening nudge"
            )

            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Stats",
                description: "Detailed charts and insights (coming soon)"
            )

            featureRow(
                icon: "paintpalette.fill",
                title: "Custom Themes",
                description: "Personalize your experience (coming soon)"
            )

            featureRow(
                icon: "sparkles",
                title: "AI Tips",
                description: "Daily money-saving tips powered by AI (coming soon)"
            )

            featureRow(
                icon: "icloud.fill",
                title: "Cloud Sync",
                description: "Sync across all your devices (coming soon)"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Pricing Section
    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if let yearly = storeManager.yearlyProduct {
                productCard(product: yearly, isBestValue: true)
            }

            if let monthly = storeManager.monthlyProduct {
                productCard(product: monthly, isBestValue: false)
            }

            if storeManager.products.isEmpty {
                Text("Loading products...")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func productCard(product: Product, isBestValue: Bool) -> some View {
        Button(action: {
            selectedProduct = product
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)

                    if let subscription = product.subscription {
                        switch subscription.subscriptionPeriod.unit {
                        case .month:
                            Text("per month")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        case .year:
                            Text("per year")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        default:
                            EmptyView()
                        }
                    }
                }

                Image(systemName: selectedProduct?.id == product.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedProduct?.id == product.id ? .green : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedProduct?.id == product.id ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button
    @ViewBuilder
    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button(action: purchaseSelected) {
                Text("Start Premium")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedProduct == nil || isPurchasing)

            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Restore Button
    @ViewBuilder
    private var restoreButton: some View {
        Button(action: restorePurchases) {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Footer
    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 8) {
            Text("Subscription auto-renews unless cancelled 24 hours before the end of the current period.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://savestreak.com/terms")!)
                Text("•")
                Link("Privacy", destination: URL(string: "https://savestreak.com/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions
    private func purchaseSelected() {
        guard let product = selectedProduct else { return }

        Task {
            isPurchasing = true
            purchaseError = nil

            do {
                let transaction = try await storeManager.purchase(product)

                if transaction != nil {
                    // Purchase successful
                    dismiss()
                } else {
                    // User cancelled or pending
                    purchaseError = nil
                }
            } catch {
                purchaseError = "Purchase failed. Please try again."
            }

            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true
            purchaseError = nil

            await storeManager.restorePurchases()

            isPurchasing = false

            if storeManager.isPremium {
                dismiss()
            } else {
                purchaseError = "No purchases to restore."
            }
        }
    }
}

#Preview {
    PaywallView()
}
