import Foundation
import FlutterMacOS

#if canImport(Translation)
import Translation
#endif

class TranslationPlugin {
    private var channel: FlutterMethodChannel?

    func register(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "vocabo/translation",
            binaryMessenger: messenger
        )
        channel?.setMethodCallHandler { [weak self] call, result in
            NSLog("[Vocabo] TranslationPlugin: Received method call: %@", call.method)
            switch call.method {
            case "isAvailable":
                self?.handleIsAvailable(result: result)
            case "translate":
                self?.handleTranslate(call: call, result: result)
            case "isLanguagePairInstalled":
                self?.handleIsLanguagePairInstalled(call: call, result: result)
            case "openTranslationSettings":
                result(nil)
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Localization-Settings")!)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handleIsAvailable(result: @escaping FlutterResult) {
        #if canImport(Translation)
        if #available(macOS 26.0, *) {
            result(true)
        } else {
            result(false)
        }
        #else
        result(false)
        #endif
    }

    private func handleIsLanguagePairInstalled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sourceLocale = args["sourceLocale"] as? String,
              let targetLocale = args["targetLocale"] as? String else {
            result(false)
            return
        }

        #if canImport(Translation)
        if #available(macOS 26.0, *) {
            Task {
                let source = Locale.Language(identifier: sourceLocale)
                let target = Locale.Language(identifier: targetLocale)
                let availability = LanguageAvailability()
                let status = await availability.status(from: source, to: target)
                NSLog("[Vocabo] TranslationPlugin: Language pair %@ → %@ status: %@", sourceLocale, targetLocale, String(describing: status))
                DispatchQueue.main.async {
                    result(status == .installed)
                }
            }
            return
        }
        #endif

        result(false)
    }

    private func handleTranslate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String,
              let sourceLocale = args["sourceLocale"] as? String,
              let targetLocale = args["targetLocale"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments: text, sourceLocale, targetLocale",
                details: nil
            ))
            return
        }

        NSLog("[Vocabo] TranslationPlugin: handleTranslate called with text='%@', source='%@', target='%@'", text, sourceLocale, targetLocale)

        #if canImport(Translation)
        NSLog("[Vocabo] TranslationPlugin: canImport(Translation) = true")
        if #available(macOS 26.0, *) {
            NSLog("[Vocabo] TranslationPlugin: macOS 26.0+ available, calling translateWithAppleFramework")
            translateWithAppleFramework(
                text: text,
                sourceLocale: sourceLocale,
                targetLocale: targetLocale,
                result: result
            )
            return
        } else {
            NSLog("[Vocabo] TranslationPlugin: macOS 26.0+ NOT available")
        }
        #else
        NSLog("[Vocabo] TranslationPlugin: canImport(Translation) = false")
        #endif

        result(FlutterError(
            code: "UNAVAILABLE",
            message: "Translation requires macOS 26.0 or later",
            details: nil
        ))
    }

    #if canImport(Translation)
    @available(macOS 26.0, *)
    private func translateWithAppleFramework(
        text: String,
        sourceLocale: String,
        targetLocale: String,
        result: @escaping FlutterResult
    ) {
        Task {
            do {
                NSLog("[Vocabo] TranslationPlugin: Translating '%@' from %@ to %@", text, sourceLocale, targetLocale)
                let source = Locale.Language(identifier: sourceLocale)
                let target = Locale.Language(identifier: targetLocale)

                let availability = LanguageAvailability()
                let status = await availability.status(from: source, to: target)
                NSLog("[Vocabo] TranslationPlugin: Language pair status: %@", String(describing: status))

                guard status != .unsupported else {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "LANGUAGE_NOT_SUPPORTED",
                            message: "Language pair \(sourceLocale) → \(targetLocale) is not supported",
                            details: nil
                        ))
                    }
                    return
                }

                if status == .supported {
                    NSLog("[Vocabo] TranslationPlugin: Languages not installed. Please download them in System Settings > General > Language & Region > Translation Languages")
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "LANGUAGES_NOT_INSTALLED",
                            message: "Translation languages need to be downloaded. Go to System Settings > General > Language & Region > Translation Languages",
                            details: nil
                        ))
                    }
                    return
                }

                let session = TranslationSession(installedSource: source, target: target)
                NSLog("[Vocabo] TranslationPlugin: Session created, calling translate...")
                let response = try await session.translate(text)
                NSLog("[Vocabo] TranslationPlugin: Translation result: %@", response.targetText)

                DispatchQueue.main.async {
                    result([
                        "translatedText": response.targetText,
                        "pronunciation": nil as String? as Any,
                    ])
                }
            } catch {
                NSLog("[Vocabo] TranslationPlugin: Translation error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "TRANSLATION_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }
    #endif
}
