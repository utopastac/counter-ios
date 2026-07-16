import SwiftUI

/// Tier 1 — primitive palette. Never use directly in views; reference via semantic tokens.
enum BaseColor {
  static let white = Color.white
  static let black = Color.black

  enum Brand {
    static let blue500 = Color(red: 0.227, green: 0.447, blue: 0.984)
  }

  enum Orange {
    static let orange500 = Color(red: 1.0, green: 0.55, blue: 0.25)
  }

  enum Green {
    static let green500 = Color.green
  }

  enum Red {
    static let red500 = Color.red
  }

  enum Mint {
    static let mint500 = Color.mint
  }

  enum Yellow {
    static let yellow500 = Color(red: 1.0, green: 0.80, blue: 0.0)
  }

  enum Neutral {
    static let darkBackdrop = Color(red: 0.07, green: 0.07, blue: 0.08)
    static let darkSheet = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let lightBackdrop = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let keypadKey = Color(red: 0.90, green: 0.90, blue: 0.90)
    static let mutedSurface = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let darkMutedSurface = Color(red: 0.14, green: 0.14, blue: 0.15)
    /// Light-mode toggle track when off — soft neutral gray.
    static let toggleTrackOffLight = Color(red: 224 / 255, green: 224 / 255, blue: 224 / 255)
    /// Dark-mode toggle track when off — lifted gray that reads on dark surfaces.
    static let toggleTrackOffDark = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)
  }

  /// White with fixed alpha steps — mirrors `color.base.white-alpha.*` in tokens.json.
  enum WhiteAlpha {
    static let a950 = Color.white.opacity(0.95)
    static let a650 = Color.white.opacity(0.65)
    static let a550 = Color.white.opacity(0.55)
    static let a500 = Color.white.opacity(0.50)
    static let a450 = Color.white.opacity(0.45)
    static let a250 = Color.white.opacity(0.25)
    static let a140 = Color.white.opacity(0.14)
    static let a120 = Color.white.opacity(0.12)
    static let a100 = Color.white.opacity(0.10)
  }

  enum BlackAlpha {
    static let a500 = Color.black.opacity(0.50)
    static let a180 = Color.black.opacity(0.18)
    static let a140 = Color.black.opacity(0.14)
    static let a120 = Color.black.opacity(0.12)
    static let a100 = Color.black.opacity(0.10)
    static let a080 = Color.black.opacity(0.08)
    static let a060 = Color.black.opacity(0.06)
    static let a040 = Color.black.opacity(0.04)
  }
}
