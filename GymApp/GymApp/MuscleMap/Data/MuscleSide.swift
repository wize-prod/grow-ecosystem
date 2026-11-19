//
//  MuscleSide.swift
//  MuscleMap
//
//  Created by Melih Colpan on 2026-02-09.
//  Copyright © 2026 Melih Colpan. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

/// Represents which side of the body a muscle belongs to.
public enum MuscleSide: String, CaseIterable, Codable, Sendable {
    case left
    case right
    case both

    /// Localized display name.
    public var displayName: String {
        switch self {
        case .left: return "Links"
        case .right: return "Rechts"
        case .both: return "Beidseitig"
        }
    }
}

/// Represents which face of the body to display.
public enum BodySide: String, CaseIterable, Codable, Sendable {
    case front
    case back

    /// Localized display name.
    public var displayName: String {
        switch self {
        case .front: return "Anterior (Vorderseite)"
        case .back: return "Posterior (Rückseite)"
        }
    }
}

/// Represents the body gender model.
public enum BodyGender: String, CaseIterable, Codable, Sendable {
    case male
    case female

    /// Localized display name.
    public var displayName: String {
        switch self {
        case .male: return "Männlich"
        case .female: return "Weiblich"
        }
    }
}
