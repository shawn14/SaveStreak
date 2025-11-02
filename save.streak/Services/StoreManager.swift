//
//  StoreManager.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import StoreKit
import SwiftUI

/// Manages In-App Purchases using StoreKit 2
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    // Product IDs - these need to be configured in App Store Connect
    private enum ProductID {
        static let monthlySubscription = "com.savestreak.premium.monthly"
        static let yearlySubscription = "com.savestreak.premium.yearly"
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var isPremium = false

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Load available products from App Store
    func loadProducts() async {
        do {
            // Request products from App Store
            let productIDs: Set<String> = [
                ProductID.monthlySubscription,
                ProductID.yearlySubscription
            ]

            self.products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }

        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Purchase a product
    func purchase(_ product: Product) async throws -> Transaction? {
        // Start a purchase
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            // Check if the transaction is verified
            let transaction = try checkVerified(verification)

            // Deliver content to the user
            await updatePurchasedProducts()

            // Always finish a transaction
            await transaction.finish()

            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update purchased products
            await updatePurchasedProducts()

        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    /// Update the list of purchased products
    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        // Iterate through all current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // If transaction is valid, add to purchased set
                purchasedIDs.insert(transaction.productID)

            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        self.purchasedProductIDs = purchasedIDs

        // Update premium status
        self.isPremium = !purchasedIDs.isEmpty
    }

    /// Listen for transaction updates (background purchases, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Update purchased products
                    await self.updatePurchasedProducts()

                    // Finish the transaction
                    await transaction.finish()

                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    /// Verify a transaction is valid
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // This transaction is not verified, fail
            throw StoreError.failedVerification

        case .verified(let safe):
            // Transaction is verified
            return safe
        }
    }

    /// Get monthly subscription product
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlySubscription }
    }

    /// Get yearly subscription product
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlySubscription }
    }

    /// Check if user has active subscription
    var hasActiveSubscription: Bool {
        isPremium
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}

// MARK: - Helper Extensions
extension Product {
    /// Get formatted price string
    var formattedPrice: String {
        self.displayPrice
    }
}
