import SwiftUI

extension ColorScheme {
  var counterSemanticColors: SemanticColors {
    SemanticColors.forColorScheme(self)
  }
}
