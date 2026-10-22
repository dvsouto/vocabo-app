import Flutter
import Foundation
import UIKit

#if canImport(Translation)
import Translation
#endif

/// Bridges the Apple Translation framework to Dart over the `vocabo/translation`
/// MethodChannel. Mirrors the macOS implementation; on-device translation is
/// requires iOS 26 (`TranslationSession(installedSource:target:)`); earlier iOS
/// versions report the feature as unavailable so Dart can fall back.
class TranslationPlugin {
    private var channel: FlutterMethodChannel?

    func register(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "vocabo/translation",
            binaryMessenger: messenger
        )
        channel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "isAvailable":
                self?.handleIsAvailable(result: result)
            case "translate":
                self?.handleTranslate(call: call, result: result)
            case "isLanguagePairInstalled":
                self?.handleIsLanguagePairInstalled(call: call, result: result)
            case "openTranslationSettings":
                self?.handleOpenTranslationSettings(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handleIsAvailable(result: @escaping FlutterResult) {
        #if canImport(Translation)
        if #available(iOS 26.0, *) {
            result(true)
        } else {
            result(false)
        }
        #else
        result(false)
        #endif
    }

    /// iOS has no deep link to the translation languages pane, so this opens
    /// the app's own page in the Settings app.
    private func handleOpenTranslationSettings(result: @escaping FlutterResult) {
        result(nil)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    private func handleIsLanguagePairInstalled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sourceLocale = args["sourceLocale"] as? String,
              let targetLocale = args["targetLocale"] as? String else {
            result(false)
            return
        }

        #if canImport(Translation)
        if #available(iOS 26.0, *) {
            Task {
                let source = Locale.Language(identifier: sourceLocale)
                let target = Locale.Language(identifier: targetLocale)
                let availability = LanguageAvailability()
                let status = await availability.status(from: source, to: target)
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

        #if canImport(Translation)
        if #available(iOS 26.0, *) {
            translateWithAppleFramework(
                text: text,
                sourceLocale: sourceLocale,
                targetLocale: targetLocale,
                result: result
            )
            return
        }
        #endif

        result(FlutterError(
            code: "UNAVAILABLE",
            message: "Translation requires iOS 26.0 or later",
            details: nil
        ))
    }

    #if canImport(Translation)
    @available(iOS 26.0, *)
    private func translateWithAppleFramework(
        text: String,
        sourceLocale: String,
        targetLocale: String,
        result: @escaping FlutterResult
    ) {
        Task {
            do {
                let source = Locale.Language(identifier: sourceLocale)
                let target = Locale.Language(identifier: targetLocale)

                let availability = LanguageAvailability()
                let status = await availability.status(from: source, to: target)

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
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "LANGUAGES_NOT_INSTALLED",
                            message: "Translation languages need to be downloaded. Go to Settings > Apps > Translate > Downloaded Languages",
                            details: nil
                        ))
                    }
                    return
                }

                let session = TranslationSession(installedSource: source, target: target)
                let response = try await session.translate(text)

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
