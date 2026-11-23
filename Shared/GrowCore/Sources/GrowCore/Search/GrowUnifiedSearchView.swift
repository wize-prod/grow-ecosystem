import Foundation
import SwiftUI

public struct GrowUnifiedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery: String = ""
    @State private var selectedFilter: String = "ALL"
    @State private var searchResults: [SearchResultItem] = []
    @State private var isSearching: Bool = false
    @State private var isSearchingCloud: Bool = false
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    private let engine = GrowUnifiedSearchEngine.shared
    private let filterOptions = [
        ("ALL", "Alle"),
        ("EXERCISE", "Kraft"),
        ("SUPPLEMENT", "Supps"),
        ("PANTRY", "Vorrat"),
        ("TRANSACTION", "Finanzen"),
        ("TASK", "Aufgaben")
    ]

    public init() {}

    public var filteredResults: [SearchResultItem] {
        if selectedFilter == "ALL" {
            return searchResults
        }
        return searchResults.filter { $0.entityType == selectedFilter }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Search Bar & Filter Bar
                searchHeader

                // 2. Cloud Search Activity Indicator
                if isSearchingCloud {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text("Durchsuche Supabase Cloud-Katalog...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(secondaryBg.opacity(0.3))
                }

                // 3. Results List
                if isSearching && searchResults.isEmpty {
                    ProgressView()
                        .padding(.top, 40)
                    Spacer()
                } else if filteredResults.isEmpty && !searchQuery.isEmpty && !isSearchingCloud {
                    VStack(spacing: 8) {
                        Text("Keine Treffer für '\(searchQuery)'")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredResults) { item in
                            Button(action: {
                                handleItemSelection(item)
                            }) {
                                denseResultRow(item)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Globaler Index")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
            }
        }
    }

    private func handleItemSelection(_ item: SearchResultItem) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        if item.entityType == "EXERCISE" {
            NotificationCenter.default.post(
                name: NSNotification.Name("GrowUnifiedSearchSelectExercise"),
                object: item.title,
                userInfo: [
                    "title": item.title,
                    "entityId": item.entityId,
                    "metadata": item.metadata
                ]
            )
            dismiss()
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 8) {
            // Search Input Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))

                #if os(iOS)
                TextField("Suche nach Übungen, Supps, Vorrat, Aufgaben...", text: $searchQuery)
                    .font(.system(size: 14, design: .monospaced))
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchQuery) { newValue in
                        performSearch(query: newValue)
                    }
                #else
                TextField("Suche nach Übungen, Supps, Vorrat, Aufgaben...", text: $searchQuery)
                    .font(.system(size: 14, design: .monospaced))
                    .onChange(of: searchQuery) { newValue in
                        performSearch(query: newValue)
                    }
                #endif

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(secondaryBg)
            .cornerRadius(8)
            .padding(.horizontal, 12)

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filterOptions, id: \.0) { opt in
                        Button(action: {
                            selectedFilter = opt.0
                        }) {
                            Text(opt.1)
                                .font(.system(size: 11, weight: selectedFilter == opt.0 ? .bold : .medium, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(selectedFilter == opt.0 ? Color.primary : secondaryBg)
                                .foregroundColor(selectedFilter == opt.0 ? systemBg : Color.primary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 6)

            Divider()
        }
        .padding(.top, 8)
    }

    private func denseResultRow(_ item: SearchResultItem) -> some View {
        let isCloud = item.categoryBadge == "Kraft (Cloud)"
        return HStack(alignment: .top, spacing: 10) {
            // Entity Badge
            Text(item.categoryBadge)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isCloud ? Color.cyan.opacity(0.18) : badgeColor(for: item.entityType).opacity(0.15))
                .foregroundColor(isCloud ? Color.cyan : badgeColor(for: item.entityType))
                .cornerRadius(4)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Text(item.subtitle)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.secondary.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(secondaryBg.opacity(0.5))
        .cornerRadius(6)
    }

    private var secondaryBg: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }

    private var systemBg: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.white
        #endif
    }

    private func badgeColor(for type: String) -> Color {
        switch type {
        case "EXERCISE": return Color.orange
        case "SUPPLEMENT": return Color.green
        case "PANTRY": return Color.teal
        case "TRANSACTION": return Color.yellow
        case "TASK": return Color.purple
        default: return Color.blue
        }
    }

    private func performSearch(query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            searchResults = []
            isSearchingCloud = false
            searchDebounceTask?.cancel()
            return
        }

        // 1. Immediate Synchronous Local SQLite Search
        let localResults = engine.search(query: clean, limit: 40)
        self.searchResults = localResults

        // 2. Asynchronous Cloud Catalog Search (Supabase)
        guard clean.count >= 2, (selectedFilter == "ALL" || selectedFilter == "EXERCISE") else {
            return
        }

        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }

            await MainActor.run {
                self.isSearchingCloud = true
            }

            let cloudResults = await engine.searchCloudExercises(query: clean)
            if Task.isCancelled { return }

            await MainActor.run {
                let existingTitles = Set(self.searchResults.map { $0.title.lowercased() })
                let deduplicatedCloud = cloudResults.filter { !existingTitles.contains($0.title.lowercased()) }
                self.searchResults = self.searchResults + deduplicatedCloud
                self.isSearchingCloud = false
            }
        }
    }
}
