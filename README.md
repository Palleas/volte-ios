# Volte (iOS)

A prototype iOS app for Volte.

![Volte logo](volte-logo.png)

## How to get started

1. Make sure you have [Carthage](https://github.com/Carthage/Carthage/) installed and Xcode 8.
2. Clone the app and run `carthage bootstrap --platform ios --no-use-binaries`
3. Install [Bundler](http://bundler.io/) then run `bundle install`
4. Open Volte.xcodeproj, build and run

## Beta Testers

Right now the recipients of the messages you post are stored in the [Volte/testers.json](Volte/testers.json) file.

## Misc 

### Localization

Localization strings are in their respective `Localizable.strings` file. To rebuild the [Localizations.swift](Volte/Localizations.swift) file:

1. Install [swiftgen](https://github.com/AliSoftware/SwiftGen/)
2. Run `bundle exec rake i18n:build`

## Credits 

* [Romain Pouclet](https://romain-pouclet.com) 
* [Marc Weistroff](http://www.delatech.net/en/)

## License 

Volte iOS is distributed under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.en.html), see [LICENSE](LICENSE) file.
