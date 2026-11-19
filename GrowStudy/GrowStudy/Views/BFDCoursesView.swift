import SwiftUI

public struct BFDCourseData: Identifiable, Equatable {
    public let id: String
    public let stepId: String
    public let courseNumber: String
    public let title: String
    public let dates: String
    public let startDate: Date
    public let leadTimeTarget: String
    public let daysCount: Int
    public let hours: Int
    public let bfdTeam: String
    public let certBadge: String
    public let academicGoal: String
    public let details: String
    public let primaryURL: String
}

public struct BFDCoursesView: View {
    @EnvironmentObject private var store: StudyStore
    @State private var filter: String = "Alle"
    @State private var expandedCourseId: String? = "winf-bfd-249"
    @State private var selectedStepForDetail: RoadmapStep? = nil

    // Die 7 verbindlichen internen BFD-Online-Lehrgänge 2027 (29 Freistellungstage)
    // 6-Monats-Vorsprung-Doktrin: Meisterschaftsziel liegt stets bis zu 6 Monate vor Kursbeginn
    private let courses: [BFDCourseData] = [
        BFDCourseData(
            id: "bfd-249",
            stepId: "winf-bfd-249",
            courseNumber: "BFD Nr. 249",
            title: "Mathematik - Grundlagen - BQ - Online",
            dates: "22.02. – 26.02.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 2, day: 22)) ?? Date(),
            leadTimeTarget: "31.12.2026 (2 Mon. Vorab-Meisterschaft)",
            daysCount: 5,
            hours: 40,
            bfdTeam: "Schwerin",
            certBadge: "BQ Mathe",
            academicGoal: "Vorbereitung Wirtschaftsmathematik (HsH Semester 1)",
            details: "Algebra, Bruchrechnung, Gleichungen & Funktionen. 5 Tage Vollzeit-Freistellung vom Dienst.",
            primaryURL: "https://www.bundeswehr.de/"
        ),
        BFDCourseData(
            id: "bfd-428",
            stepId: "winf-bfd-428",
            courseNumber: "BFD Nr. 428",
            title: "Professional Scrum Master & Product Owner - Online",
            dates: "05.04. – 07.04.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 4, day: 5)) ?? Date(),
            leadTimeTarget: "31.12.2026 (4 Mon. Vorab-Meisterschaft)",
            daysCount: 3,
            hours: 24,
            bfdTeam: "Nürnberg",
            certBadge: "PSM I & PSPO",
            academicGoal: "Vorbereitung Projektmanagement (HsH Semester 2)",
            details: "Scrum Framework, Rollen, Events & Artefakte. Vorbereitung auf die weltweiten Scrum.org Zertifikate.",
            primaryURL: "https://www.scrum.org/"
        ),
        BFDCourseData(
            id: "bfd-574",
            stepId: "winf-bfd-574",
            courseNumber: "BFD Nr. 574",
            title: "Softwareentwicklung - Grundlagen der Programmierung - Online",
            dates: "26.04. – 30.04.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 4, day: 26)) ?? Date(),
            leadTimeTarget: "31.01.2027 (3 Mon. Vorab-Meisterschaft)",
            daysCount: 5,
            hours: 40,
            bfdTeam: "Saarlouis",
            certBadge: "Dev Basics",
            academicGoal: "Vorbereitung Programmieren 1 (HsH Semester 1)",
            details: "Algorithmen, Kontrollstrukturen, Datenstrukturen & Grundlagen objektorientierter Programmierung.",
            primaryURL: "https://www.bundeswehr.de/"
        ),
        BFDCourseData(
            id: "bfd-633",
            stepId: "winf-bfd-633",
            courseNumber: "BFD Nr. 633",
            title: "Mathematik III - Für Ausbildung und Beruf - Online",
            dates: "10.05. – 14.05.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 5, day: 10)) ?? Date(),
            leadTimeTarget: "28.02.2027 (3 Mon. Vorab-Meisterschaft)",
            daysCount: 5,
            hours: 40,
            bfdTeam: "Stuttgart",
            certBadge: "Mathe III",
            academicGoal: "Vertiefung Wirtschaftsmathematik & Optimierung",
            details: "Analysis, Kurvendiskussion, Differenzialrechnung & Lineare Gleichungssysteme auf Hochschulniveau.",
            primaryURL: "https://www.bundeswehr.de/"
        ),
        BFDCourseData(
            id: "bfd-1179",
            stepId: "winf-bfd-1179",
            courseNumber: "BFD Nr. 1179",
            title: "SAP S/4HANA - Grundlagen - Online",
            dates: "27.09. – 01.10.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 9, day: 27)) ?? Date(),
            leadTimeTarget: "31.03.2027 (6 Monate Vorsprung)",
            daysCount: 5,
            hours: 40,
            bfdTeam: "Nürnberg",
            certBadge: "SAP S/4HANA",
            academicGoal: "Vorbereitung Unternehmensprozesse & ERP (HsH Sem. 1 & 4)",
            details: "Navigation im SAP S/4HANA Fiori Launchpad, ERP-Kernmodule, Stammdaten, O2C & P2P Prozessketten.",
            primaryURL: "https://www.sap.com/"
        ),
        BFDCourseData(
            id: "bfd-1279",
            stepId: "winf-bfd-1279",
            courseNumber: "BFD Nr. 1279",
            title: "ITIL® 5 Foundation - Online",
            dates: "11.10. – 13.10.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 10, day: 11)) ?? Date(),
            leadTimeTarget: "30.04.2027 (6 Monate Vorsprung)",
            daysCount: 3,
            hours: 24,
            bfdTeam: "Potsdam",
            certBadge: "ITIL 4/5",
            academicGoal: "IT-Service-Management & IT-Betrieb",
            details: "Service Value System (SVS), die 4 Dimensionen des Service Managements & ITIL Best Practices.",
            primaryURL: "https://www.axelos.com/"
        ),
        BFDCourseData(
            id: "bfd-1461",
            stepId: "winf-bfd-1461",
            courseNumber: "BFD Nr. 1461",
            title: "IREB-Certified Professional for Requirements Engineering - Online",
            dates: "17.11. – 19.11.2027",
            startDate: Calendar.current.date(from: DateComponents(year: 2027, month: 11, day: 17)) ?? Date(),
            leadTimeTarget: "31.05.2027 (6 Monate Vorsprung)",
            daysCount: 3,
            hours: 24,
            bfdTeam: "NRW Köln",
            certBadge: "IREB CPRE",
            academicGoal: "Requirements Engineering & Business Analysis",
            details: "Ermittlung, Dokumentation, Prüfung und Verwaltung von Softwareanforderungen (CPRE-FL).",
            primaryURL: "https://www.ireb.org/"
        )
    ]

    private var daysUntilNextCourse: Int {
        guard let first = courses.first else { return 0 }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: first.startDate).day ?? 0
        return max(0, diff)
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                StudyTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header Banner: BFD 2027 Übersicht
                        headerBanner

                        // Countdown & Freistellungs-Statistik
                        metricsBar

                        // Filter Leiste
                        filterPicker

                        // Kursliste
                        LazyVStack(spacing: 14) {
                            ForEach(courses) { course in
                                courseCard(for: course)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("BFD-Lehrgänge 2027")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedStepForDetail) { step in
                StepDetailSheet(step: step)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Subviews

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(StudyTheme.strongBlue)
                Text("BFD BUNDESWEHR • STUFENPLAN 2027")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(StudyTheme.strongBlue)
                Spacer()
                Text("29 TAGE FREISTELLUNG")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(StudyTheme.strongBlue.opacity(0.12))
                    .foregroundColor(StudyTheme.strongBlue)
                    .cornerRadius(6)
            }

            Text("7 interne Online-Zertifikatslehrgänge")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(StudyTheme.textPrimary)

            Text("Alle 7 Bildungsmaßnahmen finden zu 100 % online statt. Gemäß § 5 SVG besteht voller Freistellungsanspruch vom militärischen Dienstbetrieb ohne Belastung des Urlaubsanspruchs.")
                .font(.system(size: 12))
                .foregroundColor(StudyTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(14)
        .background(StudyTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(StudyTheme.border, lineWidth: 1)
        )
    }

    private var metricsBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NÄCHSTER START")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StudyTheme.textMuted)
                Text("\(daysUntilNextCourse) Tage")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(StudyTheme.accent)
                Text("22.02.2027 (Nr. 249)")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(StudyTheme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(StudyTheme.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text("ZERTIFIKATE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(StudyTheme.textMuted)
                Text("4 Industrie-Certs")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(StudyTheme.successGreen)
                Text("PSM I, SAP, ITIL, IREB")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(StudyTheme.surface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(StudyTheme.border, lineWidth: 1))
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(["Alle", "Online-Vollzeit", "Zertifikate"], id: \.self) { item in
                Button {
                    filter = item
                    HapticFeedback.light()
                } label: {
                    Text(item)
                        .font(.system(size: 12, weight: filter == item ? .bold : .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(filter == item ? StudyTheme.strongBlue : StudyTheme.surface)
                        .foregroundColor(filter == item ? .white : StudyTheme.textSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(filter == item ? Color.clear : StudyTheme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func courseCard(for course: BFDCourseData) -> some View {
        let isExpanded = expandedCourseId == course.id
        let step = store.steps.first(where: { $0.id == course.stepId })
        let isCompleted = step?.isCompleted ?? false

        return VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(course.courseNumber)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(StudyTheme.strongBlue)

                        Text("•")
                            .foregroundColor(StudyTheme.textMuted)

                        Text("BFD-Team \(course.bfdTeam)")
                            .font(.system(size: 11))
                            .foregroundColor(StudyTheme.textMuted)

                        Spacer()

                        Text(course.certBadge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(StudyTheme.accent.opacity(0.12))
                            .foregroundColor(StudyTheme.accent)
                            .cornerRadius(4)
                    }

                    Text(course.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(StudyTheme.textPrimary)
                }
            }

            // Kennzahlen-Zeile
            HStack(spacing: 12) {
                Label(course.dates, systemImage: "calendar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(StudyTheme.textSecondary)

                Label("\(course.daysCount) Tage Freistellung", systemImage: "clock.badge.checkmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(StudyTheme.textSecondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedCourseId == course.id {
                            expandedCourseId = nil
                        } else {
                            expandedCourseId = course.id
                        }
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }

            // 6-Monate-Vorsprung Indikator
            HStack(spacing: 6) {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(StudyTheme.strongBlue)
                    .font(.system(size: 10))
                Text("VORSPRUNG-ZIEL:")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.strongBlue)
                Text(course.leadTimeTarget)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(StudyTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(StudyTheme.strongBlue.opacity(0.08))
            .cornerRadius(6)

            // Ausklappbare Details
            if isExpanded {
                Divider()
                    .background(StudyTheme.border)

                VStack(alignment: .leading, spacing: 8) {
                    Text(course.details)
                        .font(.system(size: 12))
                        .foregroundColor(StudyTheme.textSecondary)
                        .lineSpacing(2)

                    HStack {
                        Image(systemName: "graduationcap")
                            .font(.system(size: 11))
                            .foregroundColor(StudyTheme.accent)
                        Text(course.academicGoal)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StudyTheme.accent)
                    }

                    // Interaktive Subtasks aus dem Store (falls verknüpft)
                    if let step = step {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Maßnahmen-Checkliste:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(StudyTheme.textPrimary)

                            ForEach(step.subtasks) { st in
                                Button {
                                    store.toggleSubtask(stepId: step.id, subtaskId: st.id)
                                    HapticFeedback.light()
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: st.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(st.isDone ? StudyTheme.successGreen : StudyTheme.textMuted)
                                            .font(.system(size: 13))
                                        Text(st.text)
                                            .font(.system(size: 12))
                                            .foregroundColor(st.isDone ? StudyTheme.textMuted : StudyTheme.textPrimary)
                                            .strikethrough(st.isDone)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Links & Dokumente Button
                    if let step = step {
                        Button {
                            selectedStepForDetail = step
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "paperclip")
                                Text("Links & PDFs verwalten (\(step.resources.count + step.submodules.count))")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StudyTheme.strongBlue)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(StudyTheme.strongBlue.opacity(0.08))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    // Kalender-Sync Button
                    HStack {
                        Button {
                            if let step = step {
                                store.toggleStep(id: step.id)
                                HapticFeedback.medium()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isCompleted ? "checkmark.seal.fill" : "seal")
                                Text(isCompleted ? "Als bestanden verbucht" : "Als bestanden markieren")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isCompleted ? StudyTheme.successGreen : StudyTheme.textPrimary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(isCompleted ? StudyTheme.successGreen.opacity(0.12) : StudyTheme.surface)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(StudyTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if let url = URL(string: course.primaryURL) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Text("Info-Portal")
                                    Image(systemName: "arrow.up.right")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(StudyTheme.strongBlue)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(14)
        .background(StudyTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCompleted ? StudyTheme.successGreen.opacity(0.4) : StudyTheme.border, lineWidth: 1)
        )
    }
}
