import SwiftUI
import Combine

#if canImport(RevenueCat)
import RevenueCat
#endif

enum QuitERGYRevenueCat {
    static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }

    static let offeringIdentifier: String = "default"
    static let packageIdWeekly: String = "$rc_weekly"
    static let packageIdYearly: String = "$rc_annual"

    static let productIdWeekly: String = "quitergy_weekly"
    static let productIdYearly: String = "quitergy_yearly"

    static let entitlementPremium: String = "QuitERGYPremium"
}

// MARK: - Layout Metrics
struct PaywallLayoutMetrics {
    enum VerticalSizeClass {
        case compact
        case regular
        case expanded
    }

    let scale: CGFloat
    let sizeClass: VerticalSizeClass
    private let size: CGSize
    private let safeAreaInsets: EdgeInsets

    init(geometry: GeometryProxy) {
        size = geometry.size
        safeAreaInsets = geometry.safeAreaInsets

        let baseHeight: CGFloat = 812
        let rawScale = size.height / baseHeight
        scale = PaywallLayoutMetrics.clamp(rawScale, minimum: 0.86, maximum: 1.18)

        if size.height <= 700 {
            sizeClass = .compact
        } else if size.height >= 920 {
            sizeClass = .expanded
        } else {
            sizeClass = .regular
        }
    }

    var isUltraCompact: Bool { size.height <= 670 }

    var horizontalPadding: CGFloat { scaledValue(20, minimum: 16, maximum: 24) }
    var bodySpacing: CGFloat { scaledValue(18, minimum: 14, maximum: 22) }
    var headerSpacing: CGFloat { scaledValue(8, minimum: 6, maximum: 10) }
    var headerTopPadding: CGFloat {
        isUltraCompact ? 12 : scaledValue(20, minimum: 16, maximum: 28)
    }
    var headerBottomPadding: CGFloat {
        isUltraCompact ? 8 : scaledValue(14, minimum: 10, maximum: 18)
    }
    var featureSpacing: CGFloat { scaledValue(10, minimum: 8, maximum: 14) }
    var featureRowSpacing: CGFloat { scaledValue(10, minimum: 8, maximum: 12) }
    var planSpacing: CGFloat { scaledValue(12, minimum: 10, maximum: 16) }
    var footerSpacing: CGFloat { scaledValue(16, minimum: 12, maximum: 20) }

    var contentBottomPadding: CGFloat { safeAreaInsets.bottom + scaledValue(32, minimum: 18, maximum: 42) }

    func headerIconSize() -> CGFloat { scaledValue(70, minimum: 60, maximum: 80) }
    func headerBadgePadding() -> CGFloat { scaledValue(6, minimum: 4, maximum: 8) }

    func scaledValue(_ base: CGFloat, minimum: CGFloat? = nil, maximum: CGFloat? = nil) -> CGFloat {
        var value = base * min(scale, 1.0)
        if let minimum { value = max(minimum, value) }
        if let maximum { value = min(maximum, value) }
        return value
    }

    private static func clamp(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        max(minimum, min(maximum, value))
    }
}

// MARK: - Paywall View
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var canDismiss = false
    @State private var progress: Double = 0
    private let dismissDuration: Double = 5
    @State private var showCelebration = false
    private let celebrationDuration: TimeInterval = 1.6
    @State private var wasPremiumOnAppear = false

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            QuitERGYPaywallBrand.screenBackground.ignoresSafeArea()

            GeometryReader { proxy in
                let metrics = PaywallLayoutMetrics(geometry: proxy)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: metrics.bodySpacing) {
                        header(metrics: metrics)
                        benefitsSection(metrics: metrics)
                        PlanSelectionSection(
                            planColor: QuitERGYPaywallBrand.accent,
                            layoutScale: metrics.scale,
                            onPurchaseSuccess: handlePurchaseSuccess
                        )
                        .environmentObject(purchaseManager)

                        footerLinks(metrics: metrics)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.bottom, metrics.contentBottomPadding)
                }
            }

            dismissButton
                .padding(.top, 10)
                .padding(.trailing, 18)
        }
        .overlay {
            if showCelebration {
                CelebrationConfettiView(duration: celebrationDuration)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onReceive(timer) { _ in
            guard !canDismiss else { return }
            progress = min(1.0, progress + 0.1 / dismissDuration)
            if progress >= 1.0 { canDismiss = true }
        }
        .onAppear {
            PurchaseManager.configureIfNeeded()
            progress = 0
            canDismiss = false
            showCelebration = false
            wasPremiumOnAppear = purchaseManager.isPremiumUnlocked
            purchaseManager.ensureInitialSync()
        }
        .onChange(of: purchaseManager.isPremiumUnlocked) { _, isPremium in
            guard isPremium, !wasPremiumOnAppear else { return }
            handlePurchaseSuccess()
        }
        .interactiveDismissDisabled(!canDismiss)
    }

    // MARK: Header
    private func header(metrics: PaywallLayoutMetrics) -> some View {
        VStack(spacing: metrics.headerSpacing) {
            ZStack {
                QuitERGYPaywallBrand.blurGlow(radius: 68)
                    .frame(width: metrics.headerIconSize() * 1.6)
                Image("PaywallIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: metrics.headerIconSize(), height: metrics.headerIconSize())
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: QuitERGYPaywallBrand.accent.opacity(0.45), radius: 18, y: 10)
            }

            Text("QuitERGY Premium")
                .font(.quitRounded(.semibold, size: metrics.scaledValue(24, minimum: 20, maximum: 28)))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("Stay clean longer, understand every craving, and celebrate progress with real insights.")
                .font(.quitRounded(.medium, size: metrics.scaledValue(14, minimum: 12, maximum: 16)))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, metrics.scaledValue(12, minimum: 8, maximum: 20))

        }
        .padding(.top, metrics.headerTopPadding)
        .padding(.bottom, metrics.headerBottomPadding)
    }

    // MARK: Benefits
    private func benefitsSection(metrics: PaywallLayoutMetrics) -> some View {
        let items = BenefitItem.sampleItems
        return VStack(spacing: metrics.featureRowSpacing) {
            ForEach(items) { item in
                BenefitRow(item: item, metrics: metrics)
            }
        }
        .padding(metrics.scaledValue(16, minimum: 12, maximum: 20))
        .background(
            RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                .fill(QuitERGYTheme.surface)
                .shadow(color: QuitERGYTheme.cardShadowColor, radius: 18, x: 0, y: 12)
        )
    }

    // MARK: Footer Links
    private func footerLinks(metrics: PaywallLayoutMetrics) -> some View {
        HStack(spacing: metrics.footerSpacing) {
            Button {
                Task { try? await purchaseManager.restorePurchases() }
            } label: {
                Text("Restore")
                    .underline()
            }

            Link("Terms", destination: URL(string: "https://quitergy.app/terms")!)
                .underline()
            
            Link("Privacy", destination: URL(string: "https://quitergy.app/privacy")!)
                .underline()
        }
        .font(.quitRounded(.medium, size: metrics.scaledValue(13, minimum: 11, maximum: 15)))
        .foregroundStyle(QuitERGYTheme.textSecondary)
        .frame(maxWidth: .infinity)
    }

    // MARK: Dismiss Button
    private var dismissButton: some View {
        VStack(spacing: 6) {
            Button {
                if canDismiss { dismiss() }
            } label: {
                ZStack {
                    Circle()
                        .stroke(QuitERGYPaywallBrand.accent.opacity(0.25), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            QuitERGYPaywallBrand.accent,
                            style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(canDismiss ? QuitERGYPaywallBrand.accent : QuitERGYTheme.textSecondary)
                }
                .frame(width: 32, height: 32)
            }
            .disabled(!canDismiss)

            Text(canDismiss ? "" : "\(max(0, Int(ceil((1 - progress) * dismissDuration))))")
                .font(.quitRounded(.medium, size: 12).monospacedDigit())
                .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.9))
                .frame(height: 12)
        }
        .animation(.easeInOut(duration: 0.15), value: progress)
    }

    // MARK: Purchase Success
    private func handlePurchaseSuccess() {
        guard !showCelebration else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            showCelebration = true
        }
        canDismiss = true
        progress = 1.0
        wasPremiumOnAppear = true

        Task {
            try? await Task.sleep(nanoseconds: UInt64(celebrationDuration * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCelebration = false
                }
                dismiss()
            }
        }
    }
}

// MARK: - Benefit Views
private struct BenefitItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String

    static let sampleItems: [BenefitItem] = [
        BenefitItem(
            icon: "chart.bar.doc.horizontal.fill",
            title: "Detailed Statistics",
            description: "Track your progress with beautiful charts showing money saved, sugar avoided, and drinks skipped."
        ),
        BenefitItem(
            icon: "person.2.fill",
            title: "Multiple Profiles",
            description: "Create unlimited drink profiles to track different energy drinks and compare your progress."
        ),
        BenefitItem(
            icon: "alarm.fill",
            title: "Daily Reminders",
            description: "Get gentle daily check-ins to log your progress and stay accountable to your goals."
        )
    ]
}

private struct BenefitRow: View {
    let item: BenefitItem
    let metrics: PaywallLayoutMetrics

    var body: some View {
        HStack(alignment: .top, spacing: metrics.scaledValue(16, minimum: 12, maximum: 18)) {
            ZStack {
                QuitERGYPaywallBrand.blurGlow(radius: 20, opacity: 0.32)
                    .frame(width: metrics.scaledValue(32, minimum: 26, maximum: 38))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(QuitERGYPaywallBrand.surface.opacity(0.9))
                    .frame(width: metrics.scaledValue(44, minimum: 36, maximum: 52), height: metrics.scaledValue(44, minimum: 36, maximum: 52))
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: metrics.scaledValue(20, minimum: 16, maximum: 22), weight: .semibold))
                            .foregroundStyle(QuitERGYPaywallBrand.accent)
                    }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.quitRounded(.semibold, size: metrics.scaledValue(17, minimum: 15, maximum: 19)))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                Text(item.description)
                    .font(.quitRounded(.medium, size: metrics.scaledValue(14, minimum: 12, maximum: 16)))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Plan Selection Section
struct PlanSelectionSection: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.colorScheme) private var colorScheme

    let planColor: Color
    let layoutScale: CGFloat
    let onPurchaseSuccess: @MainActor () -> Void

    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var isProcessing = false
    @State private var isLoading = true
    @State private var loadError: String?

    private func scaledValue(_ base: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        let value = base * min(layoutScale, 1.0)
        return max(minimum, min(maximum, value))
    }

    enum SubscriptionPlan {
        case yearly
        case weekly

        var productId: String {
            switch self {
            case .yearly: return QuitERGYRevenueCat.productIdYearly
            case .weekly: return QuitERGYRevenueCat.productIdWeekly
            }
        }

        var packageId: String {
            switch self {
            case .yearly: return QuitERGYRevenueCat.packageIdYearly
            case .weekly: return QuitERGYRevenueCat.packageIdWeekly
            }
        }

        var fallbackPrice: String {
            switch self {
            case .yearly: return "$29.99 / year"
            case .weekly: return "$2.49 / week"
            }
        }
    }

    var body: some View {
        VStack(spacing: scaledValue(16, minimum: 12, maximum: 20)) {
            if isLoading {
                ProgressView("Loading plans…")
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            } else {
                planButton(for: .yearly, badge: "BEST VALUE", subtitle: "Save big each year")
                planButton(for: .weekly, badge: "3-DAY FREE TRIAL", subtitle: "Cancel anytime")
            }

            Text("3-day free trial, then only what you already spend on energy drinks.")
                .font(.quitRounded(.medium, size: scaledValue(14, minimum: 12, maximum: 16)))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(selectedPlan == .weekly ? 1 : 0)
                .accessibilityHidden(selectedPlan != .weekly)

            Button {
                Task { await onPurchaseTapped() }
            } label: {
                ZStack {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: scaledValue(10, minimum: 8, maximum: 12)) {
                            Text(selectedPlan == .weekly ? "Start free trial" : "Continue")
                                .font(.quitRounded(.semibold, size: scaledValue(20, minimum: 18, maximum: 24)))
                            Image(systemName: "chevron.right")
                                .font(.system(size: scaledValue(16, minimum: 14, maximum: 18), weight: .semibold))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, scaledValue(18, minimum: 14, maximum: 22))
                .background(
                    LinearGradient(
                        colors: [planColor.opacity(0.85), planColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isProcessing || isLoading)

            if let loadError {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loadError)
                        .font(.quitRounded(.medium, size: 13))
                        .foregroundStyle(Color.red)
                    Button("Retry") {
                        Task { await loadOfferings() }
                    }
                    .font(.quitRounded(.semibold, size: 13))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 6)
        .task { await loadOfferings() }
    }

    private func planButton(for plan: SubscriptionPlan, badge: String, subtitle: String) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack(spacing: scaledValue(12, minimum: 10, maximum: 16)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan == .weekly ? "Weekly Plan" : "Yearly Plan")
                        .font(.quitRounded(.semibold, size: scaledValue(17, minimum: 15, maximum: 19)))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                    Text(priceDescription(for: plan))
                        .font(.quitRounded(.semibold, size: scaledValue(18, minimum: 16, maximum: 20)))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                }
                Spacer(minLength: scaledValue(8, minimum: 6, maximum: 12))
                HStack(spacing: 8) {
                    Text(badge)
                        .font(.quitRounded(.semibold, size: scaledValue(11, minimum: 9, maximum: 13)))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSelected ? planColor.opacity(0.9) : Color.red.opacity(0.85))
                        .clipShape(Capsule())
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: scaledValue(22, minimum: 18, maximum: 24), weight: .semibold))
                        .foregroundStyle(isSelected ? planColor : QuitERGYTheme.textSecondary)
                }
            }
            .padding(.vertical, scaledValue(14, minimum: 11, maximum: 16))
            .padding(.horizontal, scaledValue(16, minimum: 13, maximum: 18))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(planRowBackground(isSelected: isSelected))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? planColor : planRowSeparator(), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12), radius: scaledValue(18, minimum: 12, maximum: 24), y: 8)
        }
        .buttonStyle(.plain)
    }

    private func priceDescription(for plan: SubscriptionPlan) -> String {
        let localized = purchaseManager.packages.first(where: {
            $0.identifier == plan.packageId || $0.storeProduct.productIdentifier == plan.productId
        })?.storeProduct.localizedPriceString
        if let localized { return localized }
        return plan.fallbackPrice
    }

    private func planRowBackground(isSelected: Bool) -> Color {
        let base = QuitERGYPaywallBrand.surface.opacity(isSelected ? 0.95 : 0.75)
        return base
    }

    private func planRowSeparator() -> Color {
        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18)
    }

    private func loadOfferings() async {
        isLoading = true
        loadError = nil
        let success = await purchaseManager.loadOfferings()
        isLoading = false
        if !success || purchaseManager.packages.isEmpty {
            loadError = "Could not load offers. Please check your connection."
        }
    }

    @MainActor
    private func onPurchaseTapped() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        if let package = package(for: selectedPlan) {
            await purchaseManager.purchase(package: package)
            await handlePostPurchase()
        } else {
            let _ = await purchaseManager.loadOfferings()
            if let package = package(for: selectedPlan) {
                await purchaseManager.purchase(package: package)
                await handlePostPurchase()
            } else {
                try? await purchaseManager.purchase(productId: selectedPlan.productId)
                await handlePostPurchase()
            }
        }
    }

    private func package(for plan: SubscriptionPlan) -> Package? {
        purchaseManager.packages.first {
            $0.identifier == plan.packageId || $0.storeProduct.productIdentifier == plan.productId
        }
    }

    @MainActor
    private func handlePostPurchase() async {
        if purchaseManager.isPremiumUnlocked {
            onPurchaseSuccess()
            return
        }

        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 120_000_000)
            if purchaseManager.isPremiumUnlocked {
                onPurchaseSuccess()
                return
            }
        }
    }
}

// MARK: - Celebration Confetti
struct CelebrationConfettiView: View {
    let duration: TimeInterval
    @State private var animate = false

    var body: some View {
        TimelineView(.animation) { timeline in
            ConfettiCanvas(currentTime: timeline.date.timeIntervalSinceReferenceDate)
        }
        .transition(.opacity)
        .ignoresSafeArea()
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: duration * 0.3)) {
                animate = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeInOut(duration: 0.3)) { animate = false }
            }
        }
    }
}

private struct ConfettiCanvas: View {
    let currentTime: TimeInterval
    private let itemCount: Int = 80

    var body: some View {
        Canvas { context, size in
            let colors: [Color] = [
                QuitERGYPaywallBrand.accent,
                QuitERGYPaywallBrand.accent.opacity(0.65),
                Color.white.opacity(0.75)
            ]

            for index in 0..<itemCount {
                let normalized = Double(index) / Double(itemCount)
                let primaryPhase = currentTime * 0.6 + normalized * 4
                let secondaryPhase = currentTime * 1.2 + normalized * 6

                let x = CGFloat(normalized) * size.width
                let baseY = CGFloat((primaryPhase.truncatingRemainder(dividingBy: 1.0))) * size.height
                let sway = CGFloat(sin(secondaryPhase) * 35)
                let y = baseY + sway

                var transform = context.transform
                transform = transform.translatedBy(x: x, y: y)
                let rotationAngle = Double(index) * 9 + secondaryPhase * 120
                let rotationRadians = rotationAngle * .pi / 180
                transform = transform.rotated(by: rotationRadians)
                context.transform = transform

                let rect = CGRect(x: -3, y: -10, width: 6, height: 20)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 3),
                    with: .color(colors[index % colors.count])
                )
                context.transform = .identity
            }
        }
    }
}

// MARK: - Purchase Manager
#if canImport(RevenueCat)
@MainActor
final class PurchaseManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = PurchaseManager()
    private(set) static var isSDKConfigured = false

    @Published private(set) var packages: [Package] = []
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var isPremiumUnlocked: Bool = false

    private var hasPerformedInitialSync = false

    private override init() {
        super.init()
        Purchases.shared.delegate = self
    }

    static func configureIfNeeded(apiKey: String = QuitERGYRevenueCat.apiKey) {
        guard !isSDKConfigured, !apiKey.isEmpty else { return }
        let configuration = Configuration.Builder(withAPIKey: apiKey)
            .with(usesStoreKit2IfAvailable: true)
            .build()
        Purchases.configure(with: configuration)
        Purchases.shared.delegate = shared
        isSDKConfigured = true
    }

    func ensureInitialSync() {
        guard !hasPerformedInitialSync else { return }
        hasPerformedInitialSync = true
        Task { await refreshCustomerInfo() }
        Task { _ = await loadOfferings() }
    }

    func loadOfferings() async -> Bool {
        guard PurchaseManager.isSDKConfigured else { return false }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else {
                packages = []
                return false
            }

            let prioritizedIds = [QuitERGYRevenueCat.packageIdWeekly, QuitERGYRevenueCat.packageIdYearly]
            let prioritized = prioritizedIds.compactMap { current.package(identifier: $0) }
            let remaining = current.availablePackages.filter { !prioritizedIds.contains($0.identifier) }
            packages = prioritized + remaining
            return !packages.isEmpty
        } catch {
            packages = []
            return false
        }
    }

    func purchase(package: Package) async {
        guard PurchaseManager.isSDKConfigured else { return }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            updateState(with: result.customerInfo)
        } catch {
            // Ignore errors for now; UI will remain unchanged.
        }
    }

    func purchase(productId: String) async throws {
        guard PurchaseManager.isSDKConfigured else { return }
        let products = try await Purchases.shared.products([productId])
        guard let product = products.first else { return }
        let result = try await Purchases.shared.purchase(product: product)
        updateState(with: result.customerInfo)
    }

    func restorePurchases() async throws {
        guard PurchaseManager.isSDKConfigured else { return }
        let info = try await Purchases.shared.restorePurchases()
        updateState(with: info)
    }

    func refreshCustomerInfo() async {
        guard PurchaseManager.isSDKConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            updateState(with: info)
        } catch {
            // Ignore
        }
    }

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateState(with: customerInfo)
    }

    private func updateState(with info: CustomerInfo) {
        customerInfo = info
        isPremiumUnlocked = info.entitlements[QuitERGYRevenueCat.entitlementPremium]?.isActive == true
    }
}
#else
@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    static func configureIfNeeded() {}

    @Published private(set) var packages: [Package] = [
        .init(
            identifier: QuitERGYRevenueCat.packageIdWeekly,
            storeProduct: .init(productIdentifier: QuitERGYRevenueCat.productIdWeekly, localizedPriceString: "$2.49")),
        .init(
            identifier: QuitERGYRevenueCat.packageIdYearly,
            storeProduct: .init(productIdentifier: QuitERGYRevenueCat.productIdYearly, localizedPriceString: "$29.99"))
    ]
    @Published private(set) var isPremiumUnlocked: Bool = false

    func ensureInitialSync() {}
    func loadOfferings() async -> Bool { true }
    func purchase(package: Package) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        isPremiumUnlocked = true
    }
    func purchase(productId: String) async throws {
        try await purchase(package: packages.first!)
    }
    func restorePurchases() async throws {
        try? await Task.sleep(nanoseconds: 300_000_000)
        isPremiumUnlocked = true
    }
}
#endif

#if !canImport(RevenueCat)
struct Package {
    struct StoreProduct {
        let productIdentifier: String
        let localizedPriceString: String
    }
    let identifier: String
    let storeProduct: StoreProduct
}
#endif

// MARK: - Preview
#Preview {
    NavigationStack {
        PaywallView()
            .environmentObject(PurchaseManager.shared)
    }
}
