import Foundation
import UIKit
import SwiftUI

public struct WorkoutExportService {

    // MARK: - PDF Generation (Single-File Export)
    public static func generateWorkoutPDF(for session: WorkoutSession, measuredWeightKg: Double?) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // Standard A4
        let margin: CGFloat = 36.0
        let contentWidth = pageRect.width - (margin * 2.0)

        let sanitizedTitle = session.title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let dateFormatterFile = DateFormatter()
        dateFormatterFile.dateFormat = "yyyyMMdd_HHmm"
        let dateFileStr = dateFormatterFile.string(from: session.startTime)
        let filename = "Workout_\(sanitizedTitle)_\(dateFileStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                var cursorY: CGFloat = margin

                func checkPageBreak(neededHeight: CGFloat) {
                    if cursorY + neededHeight > pageRect.height - margin - 25.0 {
                        drawFooter(pageRect: pageRect, margin: margin)
                        context.beginPage()
                        cursorY = margin
                    }
                }

                // 1. Header Bar: Small Category & Workout Name
                let categoryAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 9.0, weight: .bold),
                    .foregroundColor: UIColor(red: 0.20, green: 0.65, blue: 0.85, alpha: 1.0)
                ]
                NSAttributedString(string: "SOMA WORKOUT-PROTOKOLL • AGENT STANDARD", attributes: categoryAttrs)
                    .draw(at: CGPoint(x: margin, y: cursorY))
                cursorY += 14.0

                // Workout Name
                let titleFont = UIFont.systemFont(ofSize: 20.0, weight: .bold)
                let titleHeight = drawText(
                    session.title.uppercased(),
                    x: margin,
                    y: cursorY,
                    width: contentWidth,
                    font: titleFont,
                    color: UIColor.black
                )
                cursorY += titleHeight + 4.0

                // Formatted Date
                let df = DateFormatter()
                df.locale = Locale(identifier: "de_DE")
                df.dateFormat = "EEEE, d. MMMM yyyy • HH:mm 'Uhr'"
                let dateStr = df.string(from: session.startTime)
                let dateFont = UIFont.systemFont(ofSize: 11.0, weight: .medium)
                let dateHeight = drawText(
                    dateStr,
                    x: margin,
                    y: cursorY,
                    width: contentWidth,
                    font: dateFont,
                    color: UIColor.darkGray
                )
                cursorY += dateHeight + 12.0

                // 2. Key Metrics Grid Box (5 Columns: Dauer, Volumen, Rekorde, RPE, Koerpergewicht)
                let gridY = cursorY
                let gridHeight: CGFloat = 52.0
                let gridRect = CGRect(x: margin, y: gridY, width: contentWidth, height: gridHeight)

                let bgPath = UIBezierPath(roundedRect: gridRect, cornerRadius: 6.0)
                UIColor(white: 0.96, alpha: 1.0).setFill()
                bgPath.fill()
                UIColor(white: 0.82, alpha: 1.0).setStroke()
                bgPath.lineWidth = 0.8
                bgPath.stroke()

                let colWidth = contentWidth / 5.0
                let weightString: String = {
                    if let w = measuredWeightKg {
                        let formatted = w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w).replacingOccurrences(of: ".", with: ",")
                        return "\(formatted) kg"
                    }
                    return "" // Left blank if not measured
                }()

                let metrics: [(label: String, value: String)] = [
                    ("DAUER", "\(session.durationMinutes) min"),
                    ("VOLUMEN", "\(Int(round(session.totalTonnageKg))) kg"),
                    ("REKORDE", "\(session.prCount) PRs"),
                    ("GESAMT-RPE", "\(session.perceivedExertionRPE) / 10"),
                    ("KÖRPERGEWICHT", weightString)
                ]

                for (idx, m) in metrics.enumerated() {
                    let colX = margin + CGFloat(idx) * colWidth
                    if idx > 0 {
                        let sepPath = UIBezierPath()
                        sepPath.move(to: CGPoint(x: colX, y: gridY + 6.0))
                        sepPath.addLine(to: CGPoint(x: colX, y: gridY + gridHeight - 6.0))
                        UIColor(white: 0.85, alpha: 1.0).setStroke()
                        sepPath.lineWidth = 0.6
                        sepPath.stroke()
                    }

                    _ = drawText(
                        m.label,
                        x: colX + 4.0,
                        y: gridY + 8.0,
                        width: colWidth - 8.0,
                        font: UIFont.monospacedSystemFont(ofSize: 8.0, weight: .bold),
                        color: UIColor.gray,
                        alignment: .center
                    )

                    _ = drawText(
                        m.value,
                        x: colX + 4.0,
                        y: gridY + 24.0,
                        width: colWidth - 8.0,
                        font: UIFont.systemFont(ofSize: 13.0, weight: .bold),
                        color: UIColor.black,
                        alignment: .center
                    )
                }

                cursorY += gridHeight + 14.0

                // 3. Notizen & Somatik Section
                let somaticNotesText = session.somaticNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                if !somaticNotesText.isEmpty {
                    checkPageBreak(neededHeight: 50.0)

                    let notesHeaderHeight = drawSectionHeader("NOTIZEN & SOMATIK", x: margin, y: cursorY, width: contentWidth)
                    cursorY += notesHeaderHeight + 4.0

                    let notesFont = UIFont.systemFont(ofSize: 10.5, weight: .regular)
                    let notesBodyHeight = drawText(
                        somaticNotesText,
                        x: margin + 8.0,
                        y: cursorY + 6.0,
                        width: contentWidth - 16.0,
                        font: notesFont,
                        color: UIColor.black
                    )

                    let noteBoxRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: notesBodyHeight + 12.0)
                    let notePath = UIBezierPath(roundedRect: noteBoxRect, cornerRadius: 4.0)
                    UIColor(white: 0.98, alpha: 1.0).setFill()
                    notePath.fill()
                    UIColor(white: 0.85, alpha: 1.0).setStroke()
                    notePath.lineWidth = 0.6
                    notePath.stroke()

                    _ = drawText(
                        somaticNotesText,
                        x: margin + 8.0,
                        y: cursorY + 6.0,
                        width: contentWidth - 16.0,
                        font: notesFont,
                        color: UIColor.black
                    )

                    cursorY += noteBoxRect.height + 12.0
                }

                // 4. Biomechanische Rollen (Agonist, Synergist, Stabilisator, Antagonist)
                checkPageBreak(neededHeight: 70.0)
                let roles = MuscleStimulusEngine.shared.resolveWorkoutFunctionalRoles(for: session)
                let rolesHeaderH = drawSectionHeader("BIOMECHANISCHE ROLLENVERTEILUNG (WORKOUT-EBENE)", x: margin, y: cursorY, width: contentWidth)
                cursorY += rolesHeaderH + 6.0

                let rolesList: [(title: String, items: [AnatomicalZone], color: UIColor)] = [
                    ("Primaerziel (Agonisten)", roles.agonists, UIColor(red: 0.15, green: 0.55, blue: 0.85, alpha: 1.0)),
                    ("Synergisten", roles.synergists, UIColor(red: 0.85, green: 0.50, blue: 0.15, alpha: 1.0)),
                    ("Stabilisatoren", roles.stabilizers, UIColor(red: 0.20, green: 0.65, blue: 0.40, alpha: 1.0)),
                    ("Antagonisten", roles.antagonists, UIColor(red: 0.80, green: 0.25, blue: 0.25, alpha: 1.0))
                ]

                for r in rolesList {
                    let names = r.items.map { $0.displayName }
                    let namesStr = names.isEmpty ? "Keine registriert" : names.joined(separator: ", ")

                    let roleLine = "\(r.title): \(namesStr)"
                    let h = drawText(
                        roleLine,
                        x: margin + 4.0,
                        y: cursorY,
                        width: contentWidth - 8.0,
                        font: UIFont.systemFont(ofSize: 9.5, weight: .regular),
                        color: UIColor.darkGray
                    )
                    cursorY += h + 3.0
                }
                cursorY += 10.0

                // 5. Uebungen & Saetze
                checkPageBreak(neededHeight: 80.0)
                let exHeaderH = drawSectionHeader("UEBUNGEN & ABSOLVIERTE SAETZE (\(session.exercises.count))", x: margin, y: cursorY, width: contentWidth)
                cursorY += exHeaderH + 8.0

                for (idx, exRecord) in session.exercises.enumerated() {
                    let ex = exRecord.exercise
                    let (prim, sec, _) = MuscleStimulusEngine.shared.resolveThreeTierZones(for: ex)
                    let ant = MuscleStimulusEngine.shared.resolveAntagonists(for: prim)

                    let setsCount = exRecord.sets.count
                    let estBlockHeight = 44.0 + CGFloat(setsCount + 1) * 18.0
                    checkPageBreak(neededHeight: min(estBlockHeight, 140.0))

                    // Exercise Header
                    let exTitle = "\(idx + 1). \(ex.name)"
                    _ = drawText(
                        exTitle,
                        x: margin,
                        y: cursorY,
                        width: contentWidth,
                        font: UIFont.systemFont(ofSize: 12.0, weight: .bold),
                        color: UIColor.black
                    )
                    cursorY += 16.0

                    // Meta: Target & Equipment & Roles
                    let primNames = prim.map { $0.displayName }.joined(separator: ", ")
                    let secNames = !sec.isEmpty ? sec.map { $0.displayName }.joined(separator: ", ") : ex.secondaryMuscles.map { $0.rawValue }.joined(separator: ", ")
                    let metaText = "Muskelgruppe: \(ex.targetMuscle.rawValue) | Equipment: \(ex.equipment.rawValue)\nAgonisten: \(primNames.isEmpty ? "-" : primNames) • Synergisten: \(secNames.isEmpty ? "-" : secNames) • Antagonisten: \(ant.isEmpty ? "-" : ant.map { $0.displayName }.joined(separator: ", "))"

                    let metaH = drawText(
                        metaText,
                        x: margin,
                        y: cursorY,
                        width: contentWidth,
                        font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
                        color: UIColor(white: 0.35, alpha: 1.0)
                    )
                    cursorY += metaH + 6.0

                    // Sets Table
                    let tableColWidths: [CGFloat] = [45.0, 75.0, 85.0, 70.0, 80.0, 50.0]
                    let tableHeaders = ["SATZ", "GEWICHT", "WDH / DAUER", "RPE", "STATUS", "REKORD"]
                    let rowHeight: CGFloat = 16.0

                    // Header Row
                    let headerRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: rowHeight)
                    UIColor(white: 0.92, alpha: 1.0).setFill()
                    UIRectFill(headerRect)

                    var curX = margin
                    for (cIdx, hText) in tableHeaders.enumerated() {
                        let w = tableColWidths[cIdx]
                        _ = drawText(
                            hText,
                            x: curX + 2.0,
                            y: cursorY + 2.0,
                            width: w - 4.0,
                            font: UIFont.monospacedSystemFont(ofSize: 7.5, weight: .bold),
                            color: UIColor.darkGray,
                            alignment: cIdx == 0 ? .center : (cIdx >= 3 ? .center : .left)
                        )
                        curX += w
                    }
                    cursorY += rowHeight

                    // Data Rows
                    for (sIdx, setRec) in exRecord.sets.enumerated() {
                        checkPageBreak(neededHeight: rowHeight + 4.0)

                        if sIdx % 2 == 1 {
                            let stripeRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: rowHeight)
                            UIColor(white: 0.98, alpha: 1.0).setFill()
                            UIRectFill(stripeRect)
                        }

                        let sideStr = setRec.side.map { " (\($0))" } ?? ""
                        let weightStr = setRec.weightKg > 0 ? "\(String(format: "%.1f", setRec.weightKg).replacingOccurrences(of: ".0", with: "")) kg" : "BW"
                        let repsTimeStr = setRec.isTimeBased ? "\(setRec.durationSeconds ?? setRec.reps)s" : "\(setRec.reps) Wdh"
                        let rpeStr = setRec.rpe.map { String(format: "%.1f", $0) } ?? "-"
                        let statusStr = setRec.isCompleted ? "Erledigt" : "Offen"
                        let prStr = setRec.isPR ? "PR" : "-"

                        let rowValues = [
                            "\(setRec.setNumber)\(sideStr)",
                            weightStr,
                            repsTimeStr,
                            rpeStr,
                            statusStr,
                            prStr
                        ]

                        var rX = margin
                        for (cIdx, val) in rowValues.enumerated() {
                            let w = tableColWidths[cIdx]
                            let isPR = cIdx == 5 && setRec.isPR
                            _ = drawText(
                                val,
                                x: rX + 2.0,
                                y: cursorY + 2.0,
                                width: w - 4.0,
                                font: isPR ? UIFont.monospacedSystemFont(ofSize: 8.0, weight: .bold) : UIFont.monospacedSystemFont(ofSize: 8.0, weight: .regular),
                                color: isPR ? UIColor(red: 0.85, green: 0.55, blue: 0.0, alpha: 1.0) : UIColor.black,
                                alignment: cIdx == 0 ? .center : (cIdx >= 3 ? .center : .left)
                            )
                            rX += w
                        }

                        // Divider line under row
                        let linePath = UIBezierPath()
                        linePath.move(to: CGPoint(x: margin, y: cursorY + rowHeight))
                        linePath.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY + rowHeight))
                        UIColor(white: 0.88, alpha: 1.0).setStroke()
                        linePath.lineWidth = 0.5
                        linePath.stroke()

                        cursorY += rowHeight
                    }

                    cursorY += 12.0
                }

                // Final Footer on Last Page
                drawFooter(pageRect: pageRect, margin: margin)
            }

            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Drawing Helpers
    private static func drawSectionHeader(_ title: String, x: CGFloat, y: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
            .foregroundColor: UIColor(red: 0.15, green: 0.50, blue: 0.80, alpha: 1.0)
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        str.draw(at: CGPoint(x: x, y: y))

        let line = UIBezierPath()
        line.move(to: CGPoint(x: x, y: y + 14.0))
        line.addLine(to: CGPoint(x: x + width, y: y + 14.0))
        UIColor(red: 0.15, green: 0.50, blue: 0.80, alpha: 0.35).setStroke()
        line.lineWidth = 0.8
        line.stroke()

        return 16.0
    }

    private static func drawText(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let rect = str.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        str.draw(in: CGRect(x: x, y: y, width: width, height: rect.height))
        return ceil(rect.height)
    }

    private static func drawFooter(pageRect: CGRect, margin: CGFloat) {
        let footerY = pageRect.height - margin + 6.0
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        let footerStr = "Soma GymApp • Autonomer Trainingsbericht • Hochpraezise Biomechanik"
        NSAttributedString(string: footerStr, attributes: footerAttrs)
            .draw(at: CGPoint(x: margin, y: footerY))
    }
}
