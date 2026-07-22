import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif

/// Short system sounds for logging and undo, gated by `AppAppearancePreference.soundStyle`.
enum AppSounds {
  static func log() {
    play(AppAppearancePreference.soundStyle.logSoundID)
  }

  static func undo() {
    play(AppAppearancePreference.soundStyle.undoSoundID)
  }

  private static func play(_ soundID: UInt32?) {
    guard let soundID else { return }
    #if canImport(AudioToolbox)
    AudioServicesPlaySystemSound(soundID)
    #endif
  }
}
