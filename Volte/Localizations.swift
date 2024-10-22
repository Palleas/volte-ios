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

  struct Compose {

    struct Attachment {
      /// Remove attachment
      static let Remove = L10n.tr("compose.attachment.remove")
    }

    struct Error {
      /// Unable to post message
      static let Title = L10n.tr("compose.error.title")
      /// We were ynable to post your message, please try again later.
      static let Message = L10n.tr("compose.error.message")
    }
  }

  struct Login {

    struct Failure {
      /// Invalid Credentials
      static let Title = L10n.tr("login.failure.title")
      /// Please make sure your credentials are correct and try again
      static let Message = L10n.tr("login.failure.message")
    }
  }

  struct Timeline {
    /// Your timeline is empty. ☹️
    static let Empty = L10n.tr("timeline.empty")

    struct Compose {
      /// What are you up to?
      static let WhatAreYouUpTo = L10n.tr("timeline.compose.what_are_you_up_to")
      /// Compose
      static let Title = L10n.tr("timeline.compose.title")
    }

    struct Date {
      /// %d seconds ago
      static func SecondsAgo(p0: Int) -> String {
        return L10n.tr("timeline.date.seconds_ago", p0)
      }
      /// %d minutes ago
      static func MinutesAgo(p0: Int) -> String {
        return L10n.tr("timeline.date.minutes_ago", p0)
      }
      /// %d hours ago
      static func HoursAgo(p0: Int) -> String {
        return L10n.tr("timeline.date.hours_ago", p0)
      }
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
