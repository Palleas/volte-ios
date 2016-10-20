// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable nesting
// swiftlint:disable variable_name
// swiftlint:disable valid_docs

struct L10n {

  struct Timeline {
    /// Your timeline is empty. ☹️
    static let Empty = L10n.tr("timeline.empty")

    struct Compose {
      /// What are you up to?
      static let WhatAreYouUpTo = L10n.tr("timeline.compose.what_are_you_up_to")
      /// Compose
      static let Title = L10n.tr("timeline.compose.title")
    }
  }
}

extension L10n {
  fileprivate static func tr(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:enable type_body_length
// swiftlint:enable nesting
// swiftlint:enable variable_name
// swiftlint:enable valid_docs
