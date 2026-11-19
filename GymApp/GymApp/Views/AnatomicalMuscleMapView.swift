import SwiftUI

public enum MuscleMapHighlightLevel {
    case primary      // Radiant Red (#EF4444 / #DC2626) - Agonist / Primary
    case secondary    // Radiant Orange (#FF9500 / #F97316) - Synergist / Secondary
    case stabilizer   // Radiant Emerald Green (#10B981) - Stabilisatoren
    case antagonist   // Radiant Cyan (#00B4D8 / #06B6D4) - Reziproke Antagonisten
    case selected     // Radiant Cyan (#00E5FF) - Active Inspection
    case inactive     // Obsidian slate dark blue-gray (#242B35)

    public var fillColor: Color {
        switch self {
        case .primary:
            return Color(red: 0.95, green: 0.22, blue: 0.22)
        case .secondary:
            return Color(red: 1.00, green: 0.58, blue: 0.10)
        case .stabilizer:
            return Color(red: 0.08, green: 0.75, blue: 0.52)
        case .antagonist:
            return Color(red: 0.00, green: 0.75, blue: 0.95)
        case .selected:
            return Color(red: 0.00, green: 0.88, blue: 1.00)
        case .inactive:
            return Color(red: 0.12, green: 0.14, blue: 0.19)
        }
    }

    public var strokeColor: Color {
        switch self {
        case .primary:
            return Color(red: 1.00, green: 0.45, blue: 0.40)
        case .secondary:
            return Color(red: 1.00, green: 0.78, blue: 0.35)
        case .stabilizer:
            return Color(red: 0.30, green: 0.90, blue: 0.70)
        case .antagonist:
            return Color(red: 0.35, green: 0.88, blue: 1.00)
        case .selected:
            return Color(red: 0.40, green: 0.95, blue: 1.00)
        case .inactive:
            return Color(red: 0.20, green: 0.25, blue: 0.34)
        }
    }
}

public enum MuscleMapViewMode: String, CaseIterable, Identifiable {
    case both = "Beide"
    case front = "Anterior"
    case back = "Posterior"

    public var id: String { rawValue }
}

public struct AnatomicalMuscleMapView: View {
    public var title: String
    public var isInteractive: Bool
    public var primaryZones: Set<AnatomicalZone>
    public var secondaryZones: Set<AnatomicalZone>
    public var stabilizerZones: Set<AnatomicalZone>
    public var antagonistZones: Set<AnatomicalZone>
    public var onSelectZone: ((AnatomicalZone) -> Void)?

    @EnvironmentObject private var store: GymStore
    @State private var viewMode: MuscleMapViewMode = .both
    @State private var selectedZone: AnatomicalZone? = nil
    @State private var selectedMuscle: Muscle? = nil
    @State private var inspectedMuscle: DetailedAnatomicalMuscle? = nil
    @State private var showingDetailSheet: Bool = false

    public init(
        title: String = "Skelettale Muskelkarte",
        isInteractive: Bool = true,
        primaryZones: Set<AnatomicalZone> = [],
        secondaryZones: Set<AnatomicalZone> = [],
        stabilizerZones: Set<AnatomicalZone> = [],
        antagonistZones: Set<AnatomicalZone> = [],
        onSelectZone: ((AnatomicalZone) -> Void)? = nil
    ) {
        self.title = title
        self.isInteractive = isInteractive
        self.primaryZones = primaryZones
        self.secondaryZones = secondaryZones
        self.stabilizerZones = stabilizerZones
        self.antagonistZones = antagonistZones
        self.onSelectZone = onSelectZone
    }

    public init(
        stimulusMap: [AnatomicalZone: MuscleZoneStimulus],
        antagonistZones: Set<AnatomicalZone> = [],
        onSelectZone: ((AnatomicalZone) -> Void)? = nil
    ) {
        self.title = "Skelettale Muskelkarte"
        self.isInteractive = true
        var prim = Set<AnatomicalZone>()
        var sec = Set<AnatomicalZone>()
        var stab = Set<AnatomicalZone>()
        for (z, stim) in stimulusMap {
            if stim.effectiveScore >= 0.7 {
                prim.insert(z)
            } else if stim.effectiveScore >= 0.3 {
                sec.insert(z)
            } else if stim.effectiveScore > 0.05 {
                stab.insert(z)
            }
        }
        self.primaryZones = prim
        self.secondaryZones = sec
        self.stabilizerZones = stab
        self.antagonistZones = antagonistZones
        self.onSelectZone = onSelectZone
    }

    private var customStyle: BodyViewStyle {
        BodyViewStyle(
            defaultFillColor: Color(red: 0.12, green: 0.14, blue: 0.19),
            strokeColor: Color(red: 0.22, green: 0.27, blue: 0.36),
            strokeWidth: 0.75,
            selectionColor: Color(red: 0.00, green: 0.88, blue: 1.00),
            selectionStrokeColor: Color(red: 0.40, green: 0.95, blue: 1.00),
            selectionStrokeWidth: 1.8,
            headColor: Color(red: 0.15, green: 0.18, blue: 0.25),
            hairColor: Color(red: 0.10, green: 0.12, blue: 0.17),
            shadowColor: Color(red: 0.00, green: 0.88, blue: 1.00).opacity(0.35),
            shadowRadius: 5
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with 3-Color Legend
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                        Text("ANTERIOR & POSTERIOR MUSKELGRUPPEN")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(GymTheme.textMuted)
                            .tracking(0.8)
                    }

                    Spacer()

                    if isInteractive {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 10))
                            Text("Tippen fuer Info")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(GymTheme.cyanAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(GymTheme.cyanAccent.opacity(0.3), lineWidth: 1))
                    }
                }

                // View Mode Picker [Beide | Anterior | Posterior]
                Picker("Ansicht", selection: $viewMode) {
                    ForEach(MuscleMapViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 2)

                // 4-Tier Legend Badges (2x2 Grid: No truncation, full visibility)
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: 6) {
                    if selectedZone != nil || selectedMuscle != nil {
                        legendBadge(color: Color(red: 0.00, green: 0.88, blue: 1.00), title: "Ausgewaehlt (Cyan)")
                        legendBadge(color: Color(red: 0.95, green: 0.22, blue: 0.22), title: "Antagonist (Rot)")
                        legendBadge(color: Color(red: 1.00, green: 0.58, blue: 0.10), title: "Synergist (Orange)")
                        legendBadge(color: Color(red: 0.08, green: 0.75, blue: 0.52), title: "Stabilisator (Gruen)")
                    } else {
                        legendBadge(color: Color(red: 0.95, green: 0.22, blue: 0.22), title: "Primaerziel (Rot)")
                        legendBadge(color: Color(red: 1.00, green: 0.58, blue: 0.10), title: "Synergist (Orange)")
                        legendBadge(color: Color(red: 0.08, green: 0.75, blue: 0.52), title: "Stabilisator (Gruen)")
                        legendBadge(color: Color(red: 0.00, green: 0.75, blue: 0.95), title: "Antagonist (Cyan)")
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Vector Anatomical Renderers
            plateContainer
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            Divider()
                .background(GymTheme.borderSubtle)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Dynamic Info Pop-up Box (Directly below the anatomical figures)
            if let muscle = inspectedMuscle ?? (selectedZone.flatMap { AnatomicalMuscleCatalog.muscle(for: $0) }) {
                selectedMuscleInfoBox(muscle: muscle)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                defaultFooterGuidance
            }
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.12))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(GymTheme.borderSubtle, lineWidth: 1)
        )
        .sheet(isPresented: $showingDetailSheet) {
            if let muscle = inspectedMuscle {
                MuscleDetailExplanationSheet(
                    muscle: muscle,
                    onFilterByMuscle: { _ in
                        onSelectZone?(muscle.zone)
                        showingDetailSheet = false
                    }
                )
                .environmentObject(store)
            }
        }
    }

    // MARK: - Plates Layout
    @ViewBuilder
    private var plateContainer: some View {
        Group {
            switch viewMode {
            case .both:
                HStack(spacing: 8) {
                    VStack(spacing: 6) {
                        frontPlate
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)

                        HStack(spacing: 4) {
                            Text("ANTERIOR")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(GymTheme.textSecondary)
                            Text("(VORDERSEITE)")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)
                        }
                    }

                    Divider()
                        .background(GymTheme.borderSubtle)
                        .frame(height: 320)

                    VStack(spacing: 6) {
                        backPlate
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)

                        HStack(spacing: 4) {
                            Text("POSTERIOR")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(GymTheme.textSecondary)
                            Text("(RÜCKSEITE)")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

            case .front:
                VStack(spacing: 6) {
                    frontPlate
                        .frame(width: 320, height: 500)

                    HStack(spacing: 4) {
                        Text("ANTERIOR")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.4)
                            .foregroundColor(GymTheme.textSecondary)
                        Text("(VORDERSEITE)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)

            case .back:
                VStack(spacing: 6) {
                    backPlate
                        .frame(width: 320, height: 500)

                    HStack(spacing: 4) {
                        Text("POSTERIOR")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.4)
                            .foregroundColor(GymTheme.textSecondary)
                        Text("(RÜCKSEITE)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 35)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    if abs(horizontal) > abs(vertical) && abs(horizontal) > 40 {
                        if horizontal < 0 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewMode = .back
                            }
                            HapticFeedback.light()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewMode = .front
                            }
                            HapticFeedback.light()
                        }
                    }
                }
        )
    }

    // MARK: - Front Plate Builder
    private var frontPlate: some View {
        var view = BodyView(gender: .male, side: .front, style: customStyle)
            .showSubGroups()

        if let selMuscle = selectedMuscle {
            let singleMuscleSet: Set<Muscle> = [selMuscle]

            let antMuscles = selMuscle.antagonisticMuscles.subtracting(singleMuscleSet)
            let synMuscles = selMuscle.synergisticMuscles.subtracting(singleMuscleSet)
            let stabMuscles = selMuscle.stabilizerMuscles.subtracting(singleMuscleSet)

            // Antagonists (Radiant Red)
            for m in antMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 0.95)
            }
            // Synergists (Radiant Orange)
            for m in synMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
            }
            // Stabilizers (Emerald Green)
            for m in stabMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
            }
            // Selected Single Muscle (Electric Cyan Pulse)
            view = view.selected(singleMuscleSet)
            view = view.pulseSelected()
        } else if let selZone = selectedZone {
            for zone in selZone.antagonisticZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 0.95)
                }
            }
            for zone in selZone.stabilizerZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
                }
            }
            for zone in selZone.synergisticZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
                }
            }
            view = view.selected(Set(selZone.muscleMapMuscles))
            view = view.pulseSelected()
        } else {
            // Default workout preview
            for zone in antagonistZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.antagonist.fillColor, opacity: 0.95)
                }
            }
            for zone in stabilizerZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
                }
            }
            for zone in secondaryZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
                }
            }
            for zone in primaryZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 1.0)
                }
            }
        }

        if isInteractive {
            view = view.onMuscleSelected { muscle, side in
                handleMuscleTap(muscle: muscle, side: side)
            }
        }

        return view
    }

    // MARK: - Back Plate Builder
    private var backPlate: some View {
        var view = BodyView(gender: .male, side: .back, style: customStyle)
            .showSubGroups()

        if let selMuscle = selectedMuscle {
            let singleMuscleSet: Set<Muscle> = [selMuscle]

            let antMuscles = selMuscle.antagonisticMuscles.subtracting(singleMuscleSet)
            let synMuscles = selMuscle.synergisticMuscles.subtracting(singleMuscleSet)
            let stabMuscles = selMuscle.stabilizerMuscles.subtracting(singleMuscleSet)

            // Antagonists (Radiant Red)
            for m in antMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 0.95)
            }
            // Synergists (Radiant Orange)
            for m in synMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
            }
            // Stabilizers (Emerald Green)
            for m in stabMuscles {
                view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
            }
            // Selected Single Muscle (Electric Cyan Pulse)
            view = view.selected(singleMuscleSet)
            view = view.pulseSelected()
        } else if let selZone = selectedZone {
            for zone in selZone.antagonisticZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 0.95)
                }
            }
            for zone in selZone.stabilizerZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
                }
            }
            for zone in selZone.synergisticZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
                }
            }
            view = view.selected(Set(selZone.muscleMapMuscles))
            view = view.pulseSelected()
        } else {
            // Default workout preview
            for zone in antagonistZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.antagonist.fillColor, opacity: 0.95)
                }
            }
            for zone in stabilizerZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.stabilizer.fillColor, opacity: 0.9)
                }
            }
            for zone in secondaryZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.secondary.fillColor, opacity: 0.95)
                }
            }
            for zone in primaryZones {
                for m in zone.muscleMapMuscles {
                    view = view.highlight(m, color: MuscleMapHighlightLevel.primary.fillColor, opacity: 1.0)
                }
            }
        }

        if isInteractive {
            view = view.onMuscleSelected { muscle, side in
                handleMuscleTap(muscle: muscle, side: side)
            }
        }

        return view
    }

    private func legendBadge(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(GymTheme.textSecondary)
        }
    }

    private func roleTag(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .black, design: .monospaced))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private func handleMuscleTap(muscle: Muscle, side: MuscleSide) {
        guard isInteractive else { return }
        HapticFeedback.light()
        withAnimation(.easeInOut(duration: 0.25)) {
            if selectedMuscle == muscle {
                selectedMuscle = nil
                selectedZone = nil
                inspectedMuscle = nil
            } else {
                selectedMuscle = muscle
                let z = Self.resolveZone(for: muscle, on: viewMode == .front ? .front : .back)
                selectedZone = z
                inspectedMuscle = AnatomicalMuscleCatalog.muscle(forMuscle: muscle)
            }
        }
        if let z = selectedZone {
            onSelectZone?(z)
        }
    }

    // MARK: - Dedicated Interactive Muscle Pop-up Box
    private func selectedMuscleInfoBox(muscle: DetailedAnatomicalMuscle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            muscleInfoBoxHeader(muscle: muscle)
            forceCoupleLegendBox(muscle: muscle)
        }
        .padding(14)
    }

    private func muscleInfoBoxHeader(muscle: DetailedAnatomicalMuscle) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(muscle.zone.displayName.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(GymTheme.cyanAccent)
                        .tracking(0.8)

                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(GymTheme.textMuted)

                    Text(muscle.region)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)

                    roleTag(title: "FOKUS", color: GymTheme.cyanAccent)
                }

                Text(muscle.commonName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)

                Text(muscle.latinName)
                    .font(.system(size: 11, weight: .medium))
                    .italic()
                    .foregroundColor(GymTheme.accentGold)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMuscle = nil
                        selectedZone = nil
                        inspectedMuscle = nil
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(GymTheme.textMuted)
                }
                .buttonStyle(.plain)

                Button {
                    inspectedMuscle = muscle
                    showingDetailSheet = true
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Details")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(GymTheme.cyanAccent)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func formatMuscleName(_ muscle: Muscle) -> String {
        let name = muscle.displayName
        let targetZone = Self.resolveZone(for: muscle, on: viewMode == .front ? .back : .front)
        if viewMode == .front && targetZone.isPosterior {
            return "\(name) (Rueckseite)"
        } else if viewMode == .back && targetZone.isAnterior {
            return "\(name) (Vorderseite)"
        }
        return name
    }

    private func forceCoupleLegendBox(muscle: DetailedAnatomicalMuscle) -> some View {
        let antagonists: String
        let synergists: String
        let stabilizers: String

        if let sel = selectedMuscle {
            let overlappingToExclude = Set([sel] + (sel.parentGroup.map { [$0] } ?? []) + sel.subGroups)

            let antList = sel.antagonisticMuscles.subtracting(overlappingToExclude).map { formatMuscleName($0) }.sorted()
            antagonists = antList.isEmpty ? "Keine direkten" : antList.joined(separator: ", ")

            let synList = sel.synergisticMuscles.subtracting(overlappingToExclude).map { formatMuscleName($0) }.sorted()
            synergists = synList.isEmpty ? "Keine direkten" : synList.joined(separator: ", ")

            let stabList = sel.stabilizerMuscles.subtracting(overlappingToExclude).map { formatMuscleName($0) }.sorted()
            stabilizers = stabList.isEmpty ? "Keine direkten" : stabList.joined(separator: ", ")
        } else {
            antagonists = muscle.zone.antagonisticZones.map { $0.displayName }.sorted().joined(separator: ", ")
            synergists = muscle.zone.synergisticZones.map { $0.displayName }.sorted().joined(separator: ", ")
            stabilizers = muscle.zone.stabilizerZones.map { $0.displayName }.sorted().joined(separator: ", ")
        }

        return VStack(alignment: .leading, spacing: 6) {
            if !antagonists.isEmpty {
                forceCoupleRow(
                    label: "ANTAGONIST",
                    color: Color(red: 0.95, green: 0.22, blue: 0.22),
                    targets: antagonists
                )
            }

            if !synergists.isEmpty {
                forceCoupleRow(
                    label: "SYNERGIST",
                    color: Color(red: 1.00, green: 0.58, blue: 0.10),
                    targets: synergists
                )
            }

            if !stabilizers.isEmpty {
                forceCoupleRow(
                    label: "STABILISATOR",
                    color: Color(red: 0.08, green: 0.75, blue: 0.52),
                    targets: stabilizers
                )
            }
        }
        .padding(10)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }

    private func forceCoupleRow(label: String, color: Color, targets: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .padding(.top, 3)

            Text(label)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(width: 82, alignment: .leading)
                .padding(.top, 1)

            Text(targets)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(GymTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var defaultFooterGuidance: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.system(size: 12))
                .foregroundColor(GymTheme.textMuted)
            Text(isInteractive ? "Tippe auf eine beliebige Muskelpartie, um Antagonisten, Synergisten und Stabilisatoren direkt farblich hervorzuheben." : "Rot kennzeichnet Primaerbeweger. Orange zeigt stabilisierende Synergisten.")
                .font(.system(size: 11))
                .foregroundColor(GymTheme.textMuted)
                .lineLimit(2)
            Spacer()
        }
        .padding(14)
    }

    // MARK: - Anatomical Zone Resolver
    public static func resolveZone(for muscle: Muscle, on side: BodySide) -> AnatomicalZone {
        switch muscle {
        case .chest, .upperChest, .lowerChest:
            return .chest
        case .frontDeltoid:
            return .frontDelts
        case .rearDeltoid:
            return .rearDelts
        case .deltoids:
            return side == .back ? .rearDelts : .frontDelts
        case .biceps:
            return .biceps
        case .triceps:
            return .triceps
        case .forearm, .hands:
            return .forearms
        case .abs, .upperAbs, .lowerAbs:
            return .abdominals
        case .obliques, .serratus:
            return .obliques
        case .quadriceps, .innerQuad, .outerQuad, .adductors, .hipFlexors, .knees:
            return .quads
        case .hamstring:
            return .hamstrings
        case .gluteal:
            return .glutes
        case .lowerBack:
            return .lowerBack
        case .upperBack, .rhomboids, .rotatorCuff:
            return .lats
        case .trapezius, .upperTrapezius, .lowerTrapezius, .neck, .head:
            return .traps
        case .tibialis:
            return .calvesAnterior
        case .calves, .ankles, .feet:
            return side == .back ? .calvesPosterior : .calvesAnterior
        }
    }
}

// MARK: - Extension for Zone to Muscle Mapping
extension AnatomicalZone {
    public var muscleMapMuscles: [Muscle] {
        switch self {
        case .chest:
            return [.chest, .upperChest, .lowerChest]
        case .frontDelts:
            return [.frontDeltoid, .deltoids]
        case .biceps:
            return [.biceps]
        case .forearms:
            return [.forearm, .hands]
        case .abdominals:
            return [.abs, .upperAbs, .lowerAbs]
        case .obliques:
            return [.obliques, .serratus]
        case .quads:
            return [.quadriceps, .innerQuad, .outerQuad, .adductors, .hipFlexors, .knees]
        case .calvesAnterior:
            return [.calves, .tibialis, .ankles, .feet]
        case .traps:
            return [.trapezius, .upperTrapezius, .lowerTrapezius, .neck]
        case .rearDelts:
            return [.rearDeltoid]
        case .lats:
            return [.upperBack, .rhomboids, .rotatorCuff]
        case .triceps:
            return [.triceps]
        case .lowerBack:
            return [.lowerBack]
        case .glutes:
            return [.gluteal]
        case .hamstrings:
            return [.hamstring]
        case .calvesPosterior:
            return [.calves, .ankles, .feet]
        }
    }
}

// MARK: - Extension for Granular Muscle Force-Couples
extension Muscle {
    public var antagonisticMuscles: Set<Muscle> {
        switch self {
        case .chest, .lowerChest:
            return [.upperBack, .rearDeltoid, .rhomboids]
        case .upperChest:
            return [.upperBack, .lowerTrapezius, .rearDeltoid]
        case .upperBack:
            return [.chest, .upperChest, .frontDeltoid]
        case .rhomboids:
            return [.serratus, .chest]
        case .rotatorCuff:
            return [.upperBack, .chest]
        case .trapezius, .upperTrapezius:
            return [.lowerTrapezius, .serratus]
        case .lowerTrapezius:
            return [.upperTrapezius, .chest]
        case .deltoids:
            return [.upperBack, .rearDeltoid]
        case .frontDeltoid:
            return [.rearDeltoid, .upperBack]
        case .rearDeltoid:
            return [.frontDeltoid, .upperChest, .chest]
        case .biceps:
            return [.triceps]
        case .triceps:
            return [.biceps, .forearm]
        case .forearm, .hands:
            return [.biceps]
        case .abs, .upperAbs, .lowerAbs:
            return [.lowerBack]
        case .obliques:
            return [.lowerBack]
        case .serratus:
            return [.rhomboids, .lowerTrapezius]
        case .lowerBack:
            return [.abs, .upperAbs, .lowerAbs, .obliques]
        case .gluteal:
            return [.quadriceps, .innerQuad, .outerQuad, .hipFlexors]
        case .hamstring:
            return [.quadriceps, .innerQuad, .outerQuad]
        case .quadriceps, .innerQuad, .outerQuad:
            return [.hamstring, .gluteal]
        case .adductors:
            return [.gluteal, .outerQuad]
        case .hipFlexors:
            return [.gluteal, .hamstring]
        case .calves:
            return [.tibialis]
        case .tibialis:
            return [.calves]
        case .neck, .head:
            return []
        case .ankles, .feet, .knees:
            return []
        }
    }

    public var synergisticMuscles: Set<Muscle> {
        switch self {
        case .chest, .lowerChest:
            return [.frontDeltoid, .triceps]
        case .upperChest:
            return [.frontDeltoid, .triceps, .upperTrapezius]
        case .upperBack:
            return [.biceps, .rhomboids, .rearDeltoid, .lowerTrapezius]
        case .rhomboids:
            return [.upperBack, .lowerTrapezius, .rearDeltoid]
        case .rotatorCuff:
            return [.rearDeltoid]
        case .trapezius:
            return [.upperTrapezius, .rearDeltoid, .neck]
        case .upperTrapezius:
            return [.frontDeltoid, .neck]
        case .lowerTrapezius:
            return [.rhomboids, .upperBack]
        case .deltoids:
            return [.upperChest, .triceps, .upperTrapezius]
        case .frontDeltoid:
            return [.upperChest, .triceps]
        case .rearDeltoid:
            return [.upperBack, .rhomboids, .rotatorCuff]
        case .biceps:
            return [.forearm, .upperBack]
        case .triceps:
            return [.chest, .frontDeltoid]
        case .forearm, .hands:
            return [.biceps]
        case .abs, .upperAbs:
            return [.lowerAbs, .obliques]
        case .lowerAbs:
            return [.upperAbs, .obliques]
        case .obliques:
            return [.abs, .lowerAbs]
        case .serratus:
            return [.upperChest, .frontDeltoid, .obliques]
        case .lowerBack:
            return [.gluteal, .hamstring]
        case .gluteal:
            return [.hamstring, .lowerBack]
        case .hamstring:
            return [.gluteal, .calves]
        case .quadriceps:
            return [.hipFlexors]
        case .innerQuad:
            return [.outerQuad, .adductors]
        case .outerQuad:
            return [.innerQuad, .hipFlexors]
        case .adductors:
            return [.innerQuad, .hipFlexors]
        case .hipFlexors:
            return [.adductors]
        case .calves:
            return [.hamstring]
        case .tibialis:
            return [.quadriceps]
        case .neck, .head:
            return [.upperTrapezius]
        case .ankles, .feet, .knees:
            return []
        }
    }

    public var stabilizerMuscles: Set<Muscle> {
        switch self {
        case .chest, .upperChest, .lowerChest:
            return [.serratus, .abs, .obliques, .rotatorCuff]
        case .upperBack:
            return [.abs, .obliques, .lowerBack, .rotatorCuff]
        case .rhomboids:
            return [.rotatorCuff, .lowerBack, .upperTrapezius]
        case .rotatorCuff:
            return [.rhomboids, .serratus]
        case .trapezius, .upperTrapezius, .lowerTrapezius:
            return [.lowerBack, .abs, .rhomboids]
        case .deltoids, .frontDeltoid, .rearDeltoid:
            return [.rotatorCuff, .upperTrapezius, .abs]
        case .biceps, .triceps:
            return [.rotatorCuff, .abs]
        case .forearm, .hands:
            return [.biceps, .triceps]
        case .abs, .upperAbs, .lowerAbs:
            return [.lowerBack, .gluteal, .serratus]
        case .obliques:
            return [.lowerBack, .gluteal, .adductors]
        case .serratus:
            return [.rotatorCuff, .obliques]
        case .lowerBack:
            return [.abs, .obliques, .adductors, .gluteal]
        case .gluteal:
            return [.abs, .obliques, .adductors]
        case .hamstring:
            return [.lowerBack, .gluteal, .calves]
        case .quadriceps, .innerQuad, .outerQuad:
            return [.gluteal, .abs, .calves]
        case .adductors:
            return [.abs, .lowerAbs, .gluteal]
        case .hipFlexors:
            return [.abs, .lowerBack]
        case .calves:
            return [.gluteal]
        case .tibialis:
            return [.calves, .hamstring]
        case .neck, .head:
            return [.upperTrapezius]
        case .ankles, .feet, .knees:
            return []
        }
    }
}
