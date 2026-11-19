import SwiftUI

// MARK: - Reusable Markdown Content Renderer
public struct MarkdownContentView: View {
    public let markdown: String

    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        let lines = markdown.components(separatedBy: .newlines)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                renderLine(line)
            }
        }
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("### ") {
            Text(LocalizedStringKey(String(trimmed.dropFirst(4))))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(StudyTheme.textPrimary)
                .padding(.top, 2)
        } else if trimmed.hasPrefix("## ") {
            Text(LocalizedStringKey(String(trimmed.dropFirst(3))))
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(StudyTheme.textPrimary)
                .padding(.top, 4)
        } else if trimmed.hasPrefix("# ") {
            Text(LocalizedStringKey(String(trimmed.dropFirst(2))))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.white)
                .padding(.top, 6)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Circle()
                    .fill(StudyTheme.strongBlue)
                    .frame(width: 4, height: 4)
                    .padding(.top, 2)
                Text(LocalizedStringKey(String(trimmed.dropFirst(2))))
                    .font(.system(size: 12))
                    .foregroundColor(StudyTheme.textPrimary)
            }
            .padding(.leading, 6)
        } else if trimmed.isEmpty {
            Spacer().frame(height: 3)
        } else {
            Text(LocalizedStringKey(trimmed))
                .font(.system(size: 12))
                .foregroundColor(StudyTheme.textPrimary)
        }
    }
}

// MARK: - Markdown Notes Editor with Shortcuts & Formatting Toolbar
public struct MarkdownNotesEditorView: View {
    @Binding public var text: String
    public let placeholder: String
    public let onCommit: () -> Void

    @State private var isPreviewMode: Bool = false
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String = "Details / Notizen hinzufügen...", onCommit: @escaping () -> Void = {}) {
        self._text = text
        self.placeholder = placeholder
        self.onCommit = onCommit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Formatting Toolbar
            HStack(spacing: 5) {
                formatButton(title: "B", fontDesign: .default, fontWeight: .bold) {
                    wrapSelection(with: "**")
                }
                .keyboardShortcut("b", modifiers: .command)

                formatButton(title: "I", fontDesign: .default, fontWeight: .medium, isItalic: true) {
                    wrapSelection(with: "*")
                }
                .keyboardShortcut("i", modifiers: .command)

                Divider()
                    .frame(height: 12)
                    .background(Color.white.opacity(0.15))

                formatButton(title: "H1", fontDesign: .monospaced, fontWeight: .bold) {
                    insertPrefix("# ")
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                formatButton(title: "H2", fontDesign: .monospaced, fontWeight: .bold) {
                    insertPrefix("## ")
                }
                .keyboardShortcut("2", modifiers: [.command, .option])

                formatButton(title: "H3", fontDesign: .monospaced, fontWeight: .bold) {
                    insertPrefix("### ")
                }
                .keyboardShortcut("3", modifiers: [.command, .option])

                formatButton(title: "• Liste", fontDesign: .monospaced, fontWeight: .medium) {
                    insertPrefix("- ")
                }

                Spacer()

                // Preview Toggle Button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPreviewMode.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isPreviewMode ? "pencil" : "eye.fill")
                            .font(.system(size: 9.5))
                        Text(isPreviewMode ? "Bearbeiten" : "Vorschau")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(isPreviewMode ? StudyTheme.strongBlue : StudyTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isPreviewMode ? StudyTheme.strongBlue.opacity(0.18) : Color.white.opacity(0.05))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.04))
            .cornerRadius(6)

            // Content Area: TextField or Live Markdown Preview
            if isPreviewMode {
                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Keine Beschreibung eingegeben.")
                        .font(.system(size: 11.5))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(6)
                } else {
                    MarkdownContentView(markdown: text)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(6)
                }
            } else {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.system(size: 12.5))
                    .foregroundColor(Color.white)
                    .lineLimit(2...10)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .padding(6)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
                    .onChange(of: text) { _, _ in
                        onCommit()
                    }
            }
        }
    }

    private func formatButton(title: String, fontDesign: Font.Design, fontWeight: Font.Weight, isItalic: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: fontWeight, design: fontDesign))
                .italic(isItalic)
                .foregroundColor(StudyTheme.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private func wrapSelection(with symbol: String) {
        if text.isEmpty {
            text = "\(symbol)Text\(symbol)"
        } else {
            text.append(" \(symbol)Wichtig\(symbol)")
        }
        onCommit()
    }

    private func insertPrefix(_ prefix: String) {
        if text.isEmpty {
            text = prefix
        } else if text.hasSuffix("\n") {
            text.append(prefix)
        } else {
            text.append("\n\(prefix)")
        }
        onCommit()
    }
}
