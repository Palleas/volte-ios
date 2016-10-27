namespace :i18n do
    task :build do
        sh 'swiftgen strings -t dot-syntax-swift3 -o Volte/Localizations.swift Volte/en.lproj/Localizable.strings'
        sh 'swiftgen strings -t dot-syntax-swift3 -o Sharing/Localizations.swift Sharing/en.lproj/Localizable.strings'
    end
end
