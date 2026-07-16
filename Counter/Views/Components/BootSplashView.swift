import SwiftUI

struct BootSplashView: View {
  @AppStorage(AppAppearancePreference.darkModeEnabledKey) private var isDarkModeEnabled = false

  private var colorScheme: ColorScheme {
    isDarkModeEnabled ? .dark : .light
  }

  private var colors: SemanticColors {
    colorScheme.counterSemanticColors
  }

  var body: some View {
    colors.surfacePrimary
      .overlay {
        Image(isDarkModeEnabled ? "LogoDark" : "LogoLight")
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 180)
          .accessibilityLabel("Numo")
      }
      .ignoresSafeArea()
  }
}

#Preview("Light") {
  BootSplashView()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
  BootSplashView()
    .preferredColorScheme(.dark)
}
