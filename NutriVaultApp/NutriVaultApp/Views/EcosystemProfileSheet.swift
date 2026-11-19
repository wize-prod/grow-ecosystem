import SwiftUI

// MARK: - Circular Percentage & Profile Button (Growcery)
public struct NutriCircularProfileButton: View {
    @State private var showingProfile = false
    @State private var ecosystemLevel: SharedEcosystemLevelPayload = GrowSuiteBridge.shared.loadEcosystemLevel()
    @ObservedObject private var userAccount = UserAccountService.shared
    @ObservedObject private var store = LocalStore.shared

    public init() {}

    public var body: some View {
        let dayProtein = store.todayProtein
        let target = max(1.0, store.targetProtein)
        let ratio = min(1.0, dayProtein / target)
        let percentage = Int((dayProtein / target) * 100)

        Button {
            HapticFeedbackService.shared.mechanicalClick()
            showingProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)

                Circle()
                    .stroke(Theme.border.opacity(0.5), lineWidth: 3.5)
                    .frame(width: 42, height: 42)

                Circle()
                    .trim(from: 0, to: CGFloat(ratio))
                    .stroke(
                        ratio >= 1.0 ? Theme.sageGreen : Theme.warmSand,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: ratio)

                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            EcosystemProfileSheet()
        }
        .onAppear {
            refreshLevel()
            DarwinNotificationCenter.observe(DarwinNotificationCenter.ecosystemLevelUpdated) {
                refreshLevel()
            }
        }
    }

    private func refreshLevel() {
        self.ecosystemLevel = GrowSuiteBridge.shared.loadEcosystemLevel()
    }
}

// MARK: - Models for Nutrient Intake History
public enum NutrientMetric: String, CaseIterable, Identifiable, Hashable, Equatable {
    case protein = "Protein"
    case kcal = "Kalorien"
    case carbs = "Kohlenhydrate"
    case fat = "Fette"
    case fiber = "Ballaststoffe"

    public var id: String { rawValue }

    public var unit: String {
        switch self {
        case .protein: return "g"
        case .kcal: return "kcal"
        case .carbs: return "g"
        case .fat: return "g"
        case .fiber: return "g"
        }
    }

    public var color: Color {
        switch self {
        case .protein: return Theme.sageGreen
        case .kcal: return Theme.warmSand
        case .carbs: return Color(red: 0.28, green: 0.52, blue: 0.92)
        case .fat: return Color(red: 0.88, green: 0.42, blue: 0.32)
        case .fiber: return Color(red: 0.60, green: 0.74, blue: 0.44)
        }
    }

    @MainActor
    public func target(store: LocalStore) -> Double {
        switch self {
        case .protein: return max(1.0, store.targetProtein)
        case .kcal: return max(1.0, store.targetKcal)
        case .carbs: return max(1.0, store.targetCarbs)
        case .fat: return max(1.0, store.targetFat)
        case .fiber: return 30.0
        }
    }

    public func value(for log: MealLogEntry) -> Double {
        switch self {
        case .protein: return log.protein
        case .kcal: return log.kcal
        case .carbs: return log.carbs
        case .fat: return log.fat
        case .fiber: return log.fiber
        }
    }
}

public enum NutrientTimePeriod: String, CaseIterable, Identifiable, Hashable, Equatable {
    case day = "Tag"
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"

    public var id: String { rawValue }
}

public struct NutrientChartDataPoint: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let value: Double
}

// MARK: - Ecosystem Profile Sheet (Unified 1-999 Level System)
public struct EcosystemProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = LocalStore.shared
    @ObservedObject private var userAccount = UserAccountService.shared
    @State private var ecosystemLevel: SharedEcosystemLevelPayload = GrowSuiteBridge.shared.loadEcosystemLevel()
    @State private var showingAccountLogin = false

    // Nährstoff-Verlauf Status
    @State private var selectedPeriod: NutrientTimePeriod = .week
    @State private var selectedMetric: NutrientMetric = .protein
    @State private var selectedDataPointIndex: Int? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Hero Profile Header
                        heroHeaderSection

                        // 1.1 Account & Google Calendar Connect Action
                        accountSettingsSection

                        // 2. 4-Pfeiler Ecosystem Matrix
                        ecosystemMatrixSection

                        // 3. Nährstoff-Aufnahme Verlauf & Ziel-Vergleich (Graph)
                        nutrientIntakeHistorySection

                        // 4. Nutrition & Care Drilldown (Growcery Deep-Dive)
                        nutritionDrilldownSection

                        // 5. Synchronisations-Status
                        syncFooterSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Ecosystem Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.sageGreen)
                }
            }
            .sheet(isPresented: $showingAccountLogin) {
                AccountLoginSheet()
            }
            .onAppear {
                store.syncTagesbilanzToBridge()
                refresh()
                DarwinNotificationCenter.observe(DarwinNotificationCenter.ecosystemLevelUpdated) {
                    refresh()
                }
            }
        }
    }

    private func refresh() {
        self.ecosystemLevel = GrowSuiteBridge.shared.loadEcosystemLevel()
    }

    // MARK: - Hero Header
    private var heroHeaderSection: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Theme.surfaceElevated)
                .frame(width: 64, height: 64)
                .overlay(
                    Text(userAccount.currentAccount.initial)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                )
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(userAccount.currentAccount.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Text("B.Sc. Wirtschaftsinformatik & BFD 2027")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.sageGreen)

                Text("System- & Ernährungsstatus")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }

            Spacer()
        }
        .padding(14)
        .wellnessCard()
    }

    // MARK: - Account & Google Calendar Section
    private var accountSettingsSection: some View {
        Button {
            HapticFeedbackService.shared.mechanicalClick()
            showingAccountLogin = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.surfaceElevated)
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.sageGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Konto & Google Kalender")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        Text("ISOLIERT")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.sageGreen)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(3)
                    }

                    if userAccount.currentAccount.googleAccountEmail.isEmpty {
                        Text("Kein Google Kalender verknüpft • Antippen zum Einrichten")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    } else {
                        Text(userAccount.currentAccount.googleAccountEmail)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(12)
            .wellnessCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 4-Pfeiler Ecosystem Matrix
    private var ecosystemMatrixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ECOSYSTEM TELEMETRIE & STATUS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                    .tracking(0.8)
                Spacer()
                Text("Synchron")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.sageGreen)
            }

            // 4-Card Pillar Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                pillarTelemetryCard(
                    title: "Grow (Gym)",
                    status: "Training aktiv",
                    icon: "figure.strengthtraining.traditional",
                    accentColor: Color(red: 0.25, green: 0.45, blue: 0.90)
                )

                pillarTelemetryCard(
                    title: "Growcery (Nutrition)",
                    status: "Makros erfasst",
                    icon: "leaf.fill",
                    accentColor: Theme.sageGreen
                )

                pillarTelemetryCard(
                    title: "GrowStudy (Akademik)",
                    status: "Aufgaben synchron",
                    icon: "book.closed.fill",
                    accentColor: Theme.warmSand
                )

                pillarTelemetryCard(
                    title: "GrowFinance (Finanzen)",
                    status: "Budget aktiv",
                    icon: "shield.lefthalf.filled",
                    accentColor: Color(red: 0.85, green: 0.65, blue: 0.30)
                )
            }
        }
        .padding(14)
        .wellnessCard()
    }

    private func pillarTelemetryCard(title: String, status: String, icon: String, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
                Spacer()
                Circle()
                    .fill(accentColor)
                    .frame(width: 5, height: 5)
            }
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.textMuted)
            Text(status)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.surfaceElevated)
        )
    }

    // MARK: - Nährstoff-Aufnahme Verlauf & Zielvergleich
    private var nutrientIntakeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            nutrientHistoryHeader
            nutrientMetricSelector
            nutrientHistoryChartBody
        }
        .padding(14)
        .wellnessCard()
    }

    private var nutrientHistoryHeader: some View {
        HStack {
            Text("NÄHRSTOFF-VERLAUF & ZIEL-ANALYSE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
                .tracking(0.8)

            Spacer()

            HStack(spacing: 2) {
                ForEach(NutrientTimePeriod.allCases, id: \.id) { period in
                    let isSelected = selectedPeriod == period
                    Button {
                        HapticFeedbackService.shared.lightDetent()
                        selectedPeriod = period
                        selectedDataPointIndex = nil
                    } label: {
                        Text(period.rawValue)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Theme.bg : Theme.textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule().fill(isSelected ? selectedMetric.color : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(2)
            .background(Capsule().fill(Theme.surfaceElevated))
        }
    }

    private var nutrientMetricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(NutrientMetric.allCases, id: \.id) { metric in
                    let isSelected = selectedMetric == metric
                    Button {
                        HapticFeedbackService.shared.lightDetent()
                        selectedMetric = metric
                        selectedDataPointIndex = nil
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(metric.color)
                                .frame(width: 7, height: 7)

                            Text(metric.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? metric.color.opacity(0.18) : Theme.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? metric.color : Theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var nutrientHistoryChartBody: some View {
        let target = selectedMetric.target(store: store)
        let points = chartDataPoints
        let maxVal = points.map(\.value).max() ?? 0.0
        let scaleMax = max(target * 1.35, maxVal * 1.15, 1.0)
        let graphHeight: CGFloat = 145

        return VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                // Background horizontal guide lines
                VStack {
                    Divider().background(Theme.border.opacity(0.35))
                    Spacer()
                    Divider().background(Theme.border.opacity(0.20))
                    Spacer()
                    Divider().background(Theme.border.opacity(0.35))
                }
                .frame(height: graphHeight)

                // EMPFOHLENE ZIEL-LINIE (Empfohlenes Ziel)
                let goalY = graphHeight * CGFloat(1.0 - min(1.0, max(0.0, target / scaleMax)))
                HStack(spacing: 4) {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                        .foregroundColor(selectedMetric.color.opacity(0.85))
                        .frame(height: 1)

                    Text("Ziel: \(Int(target)) \(selectedMetric.unit)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedMetric.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceElevated)
                        .overlay(Capsule().stroke(selectedMetric.color.opacity(0.4), lineWidth: 0.8))
                }
                .offset(y: max(0, min(graphHeight - 12, goalY - 8)))
                .zIndex(2)

                // ECHTER LINIENGRAPH (Real Continuous Line Chart mit Gradient-Area & Datenpunkten)
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = graphHeight
                    let count = points.count
                    let stepX = count > 1 ? (w - 32) / CGFloat(count - 1) : 0
                    let coords: [CGPoint] = points.enumerated().map { idx, pt in
                        let x = 16 + CGFloat(idx) * stepX
                        let norm = min(1.0, max(0.0, pt.value / scaleMax))
                        let y = h * (1.0 - CGFloat(norm))
                        return CGPoint(x: x, y: y)
                    }

                    // 1. Flaechen-Gradient unter der realen Trendlinie
                    if coords.count >= 2 {
                        Path { path in
                            path.move(to: CGPoint(x: coords[0].x, y: h))
                            path.addLine(to: coords[0])
                            for pt in coords.dropFirst() {
                                path.addLine(to: pt)
                            }
                            if let last = coords.last {
                                path.addLine(to: CGPoint(x: last.x, y: h))
                            }
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    selectedMetric.color.opacity(0.25),
                                    selectedMetric.color.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // 2. Durchgehende reale Trendlinie
                        Path { path in
                            path.move(to: coords[0])
                            for pt in coords.dropFirst() {
                                path.addLine(to: pt)
                            }
                        }
                        .stroke(
                            selectedMetric.color,
                            style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round)
                        )
                    } else if let single = coords.first {
                        // Ein einzelner Datenpunkt: Solide horizontale Referenzlinie
                        Path { path in
                            path.move(to: CGPoint(x: 16, y: single.y))
                            path.addLine(to: CGPoint(x: w - 16, y: single.y))
                        }
                        .stroke(
                            selectedMetric.color,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                    }

                    // 3. Interaktive Datenknoten auf der Linie
                    ForEach(Array(points.enumerated()), id: \.element.id) { idx, point in
                        if idx < coords.count {
                            let pt = coords[idx]
                            let isSelected = selectedDataPointIndex == idx
                            let meetsGoal = point.value >= target

                            ZStack {
                                if isSelected {
                                    Circle()
                                        .stroke(selectedMetric.color.opacity(0.35), lineWidth: 6)
                                        .frame(width: 22, height: 22)
                                }

                                Circle()
                                    .fill(Theme.surfaceElevated)
                                    .frame(width: isSelected ? 12 : 9, height: isSelected ? 12 : 9)
                                    .overlay(
                                        Circle()
                                            .stroke(meetsGoal ? selectedMetric.color : selectedMetric.color.opacity(0.7), lineWidth: isSelected ? 2.5 : 2.0)
                                    )

                                if isSelected || points.count <= 7 {
                                    Text("\(Int(point.value))")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(isSelected ? selectedMetric.color : Theme.textMuted)
                                        .offset(y: -16)
                                }
                            }
                            .position(pt)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticFeedbackService.shared.lightDetent()
                                if selectedDataPointIndex == idx {
                                    selectedDataPointIndex = nil
                                } else {
                                    selectedDataPointIndex = idx
                                }
                            }
                        }
                    }
                }
                .frame(height: graphHeight)

                // X-Achsen Beschriftungen unter der Trendlinie
                HStack(spacing: 0) {
                    ForEach(Array(points.enumerated()), id: \.element.id) { idx, point in
                        let isSelected = selectedDataPointIndex == idx
                        VStack(spacing: 2) {
                            Text(point.title)
                                .font(.system(size: 8.5, weight: isSelected ? .bold : .medium, design: .monospaced))
                                .foregroundColor(isSelected ? selectedMetric.color : Theme.textSecondary)

                            Text(point.subtitle)
                                .font(.system(size: 7, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticFeedbackService.shared.lightDetent()
                            selectedDataPointIndex = (selectedDataPointIndex == idx) ? nil : idx
                        }
                    }
                }
                .padding(.horizontal, 8)
                .offset(y: graphHeight + 6)
            }
            .frame(height: graphHeight + 36)
            .padding(.top, 10)

            Divider().background(Theme.border.opacity(0.4))

            nutrientHistoryStatusFooter(target: target, points: points)
        }
    }

    private func nutrientHistoryStatusFooter(target: Double, points: [NutrientChartDataPoint]) -> some View {
        let activeValue: Double = {
            if let idx = selectedDataPointIndex, idx < points.count {
                return points[idx].value
            } else if selectedPeriod == .day {
                return points.reduce(0.0) { $0 + $1.value }
            } else {
                let total = points.reduce(0.0) { $0 + $1.value }
                return points.isEmpty ? 0.0 : (total / Double(points.count))
            }
        }()

        let delta = activeValue - target
        let pct = target > 0 ? Int((activeValue / target) * 100) : 0
        let isAboveOrMet = activeValue >= target

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDataPointIndex != nil ? "Ausgewählter Wert" : (selectedPeriod == .day ? "Gesamtaufnahme Heute" : "Durchschnitt pro Tag"))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textMuted)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", activeValue))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(selectedMetric.unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)

                    Text("(\(pct)% vom Ziel)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isAboveOrMet ? Theme.sageGreen : Theme.warmSand)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: isAboveOrMet ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))

                    Text(isAboveOrMet ? "ÜBER EMPFEHLUNG" : "UNTER EMPFEHLUNG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(isAboveOrMet ? Theme.sageGreen : Theme.warmSand)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (isAboveOrMet ? Theme.sageGreen : Theme.warmSand).opacity(0.15)
                )
                .cornerRadius(5)

                Text(isAboveOrMet ? "+\(String(format: "%.1f", delta)) \(selectedMetric.unit) über Ziel" : "-\(String(format: "%.1f", abs(delta))) \(selectedMetric.unit) Defizit")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Datenpunkte-Berechnung für Nährstoff-Verlauf
    private var chartDataPoints: [NutrientChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .day:
            let todayLogs = store.logs(for: now)
            let slots: [(String, String, Int, Int)] = [
                ("06-09", "Früh", 6, 9),
                ("09-12", "Vorm.", 9, 12),
                ("12-15", "Mittag", 12, 15),
                ("15-18", "Nachm.", 15, 18),
                ("18-21", "Abend", 18, 21),
                ("21-24", "Nacht", 21, 24)
            ]
            return slots.map { label, sub, startH, endH in
                let val = todayLogs.filter { log in
                    let h = calendar.component(.hour, from: log.timestamp)
                    return h >= startH && h < endH
                }.reduce(0.0) { $0 + selectedMetric.value(for: $1) }
                return NutrientChartDataPoint(id: label, title: label, subtitle: sub, value: val)
            }

        case .week:
            var points: [NutrientChartDataPoint] = []
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "de_DE")
            dayFormatter.dateFormat = "EE"

            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                    let logs = store.logs(for: date)
                    let total = logs.reduce(0.0) { $0 + selectedMetric.value(for: $1) }
                    let dayName = dayFormatter.string(from: date).capitalized
                    let dateNum = calendar.component(.day, from: date)
                    points.append(NutrientChartDataPoint(
                        id: store.dateKey(for: date),
                        title: dayName,
                        subtitle: "\(dateNum).",
                        value: total
                    ))
                }
            }
            return points

        case .month:
            var points: [NutrientChartDataPoint] = []
            for w in (0..<4).reversed() {
                let startDayOffset = w * 7
                let endDayOffset = (w + 1) * 7
                var weekSum = 0.0
                var dayCount = 0

                for d in startDayOffset..<endDayOffset {
                    if let date = calendar.date(byAdding: .day, value: -d, to: now) {
                        let logs = store.logs(for: date)
                        weekSum += logs.reduce(0.0) { $0 + selectedMetric.value(for: $1) }
                        dayCount += 1
                    }
                }
                let avg = dayCount > 0 ? (weekSum / Double(dayCount)) : 0.0
                let weekLabel = w == 0 ? "Aktuell" : "W-\(w)"
                points.append(NutrientChartDataPoint(
                    id: "week_\(w)",
                    title: weekLabel,
                    subtitle: "Ø/Tag",
                    value: avg
                ))
            }
            return points.reversed()

        case .year:
            var points: [NutrientChartDataPoint] = []
            let monthFormatter = DateFormatter()
            monthFormatter.locale = Locale(identifier: "de_DE")
            monthFormatter.dateFormat = "MMM"

            for m in (0..<6).reversed() {
                if let monthDate = calendar.date(byAdding: .month, value: -m, to: now) {
                    let monthLogs = store.mealLogs.filter {
                        calendar.isDate($0.timestamp, equalTo: monthDate, toGranularity: .month)
                    }
                    let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                    let total = monthLogs.reduce(0.0) { $0 + selectedMetric.value(for: $1) }
                    let avg = total / Double(daysInMonth)
                    let name = monthFormatter.string(from: monthDate)
                    points.append(NutrientChartDataPoint(
                        id: "month_\(m)",
                        title: name,
                        subtitle: "Ø/Tag",
                        value: avg
                    ))
                }
            }
            return points
        }
    }

    // MARK: - Nutrition & Care Drilldown
    private var nutritionDrilldownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ERNÄHRUNG & REGENERATION TELEMETRIE")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textMuted)
                .tracking(0.8)

            let today = Date()
            let p = store.protein(for: today)
            let waterMl = store.todayWater()
            let suppCount = store.supplementLogs[store.dateKey(for: today)]?.count ?? 0

            VStack(spacing: 8) {
                metricRow(title: "Protein-Adhärenz", detail: "\(Int(p)) / \(Int(store.targetProtein)) g", progress: min(1.0, p / max(1.0, store.targetProtein)))
                metricRow(title: "Hydration (Wasser)", detail: String(format: "%.1f / %.1f L", waterMl / 1000.0, store.targetWaterMl / 1000.0), progress: min(1.0, waterMl / max(1.0, store.targetWaterMl)))
                metricRow(title: "Zirkadiane Supplements", detail: "\(suppCount) Dosen eingenommen", progress: min(1.0, Double(suppCount) / 4.0))
            }
        }
        .padding(14)
        .wellnessCard()
    }

    private func metricRow(title: String, detail: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text(detail)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.surfaceElevated)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.sageGreen)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(height: 3.5)
        }
    }

    // MARK: - Sync Footer
    private var syncFooterSection: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.sageGreen)
                .frame(width: 5, height: 5)
            Text("Darwin Cross-App IPC • Synchronisiert mit Grow, GrowStudy & GrowFinance")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Theme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
