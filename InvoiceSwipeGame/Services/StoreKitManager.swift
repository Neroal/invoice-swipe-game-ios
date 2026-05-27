import StoreKit
import Combine

// MARK: - Product IDs
// 請在 App Store Connect > 你的 App > Monetization > In-App Purchases
// 建立「Non-Consumable」類型，ID 填入下方常數。
private let coffeeProductID = "invoice.coffee.support"

// MARK: - Manager

@MainActor
final class StoreKitManager: ObservableObject {

    static let shared = StoreKitManager()

    @Published var coffeeProduct: Product? = nil
    @Published var isPurchased: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var transactionTask: Task<Void, Never>? = nil

    init() {
        // 先從 UserDefaults 讀快取狀態，避免每次冷啟動都感覺沒買
        isPurchased = UserDefaults.standard.bool(forKey: "coffee_supporter")
        transactionTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshPurchaseStatus() }
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [coffeeProductID])
            coffeeProduct = products.first
        } catch {
            print("[StoreKit] 讀取商品失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = coffeeProduct else {
            errorMessage = "無法載入商品，請稍後再試"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification) as Transaction
                await updatePurchased(transaction)
                await transaction.finish()

            case .userCancelled:
                break  // 使用者取消，不做任何事

            case .pending:
                errorMessage = "購買待確認（可能需要家長批准）"

            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            // 靜默處理
        } catch {
            errorMessage = "購買失敗：\(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            errorMessage = "恢復購買失敗：\(error.localizedDescription)"
        }
    }

    // MARK: - Verify & update state

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchased(_ transaction: Transaction) async {
        if transaction.productID == coffeeProductID
            && transaction.revocationDate == nil {
            isPurchased = true
            UserDefaults.standard.set(true, forKey: "coffee_supporter")
        }
    }

    /// 啟動時重新驗證現有權益（防止解除安裝後重裝遺失）
    func refreshPurchaseStatus() async {
        var found       = false
        var hasRevoked  = false   // 明確收到撤銷記錄才降級

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.productID == coffeeProductID else { continue }

            if transaction.revocationDate != nil {
                // Apple 明確標記撤銷（退款）→ 降級
                hasRevoked = true
            } else {
                found = true
                await updatePurchased(transaction)
            }
        }

        // 只有在收到明確撤銷紀錄時才清除快取，
        // currentEntitlements 返回空序列（StoreKit 初始化中、無網路）時保留現有狀態。
        if hasRevoked && !found {
            isPurchased = false
            UserDefaults.standard.set(false, forKey: "coffee_supporter")
        }
    }

    // MARK: - Transaction listener（後台自動補單）

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.updatePurchased(transaction)
                await transaction.finish()
            }
        }
    }

    // MARK: - Display price helper

    var displayPrice: String {
        coffeeProduct?.displayPrice ?? "NT$30"
    }
}
