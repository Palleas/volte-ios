// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable nesting
// swiftlint:disable variable_name
// swiftlint:disable valid_docs

struct L10n {

  struct Alert {
    /// Dismiss
    static let Dismiss = L10n.tr("alert.dismiss")
  }

  struct Sharing {

    struct Error {
      /// An error occured
      static let Title = L10n.tr("sharing.error.title")
      /// You are not authenticated in Volte app.
      static let NotAuthenticated = L10n.tr("sharing.error.not_authenticated")
      /// An error occured while trying to send the message.
      static let Composing = L10n.tr("sharing.error.composing")
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
