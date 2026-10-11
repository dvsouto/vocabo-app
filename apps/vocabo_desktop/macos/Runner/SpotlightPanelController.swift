import Carbon.HIToolbox
import Cocoa
import FlutterMacOS

/// Borderless panel that takes keyboard focus without activating the app,
/// so the app the user was in stays frontmost, like Spotlight.
class SpotlightPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Translation spotlight opened by a global hotkey (Control + Option + Space).
///
/// The hotkey uses Carbon's `RegisterEventHotKey`, which does not require the
/// Accessibility permission. The UI runs on its own Flutter engine
/// (`spotlightMain`) and reports its content height so the panel only covers
/// what is drawn.
class SpotlightPanelController {
    static let shared = SpotlightPanelController()

    private var panel: SpotlightPanel?
    private var flutterEngine: FlutterEngine?
    private var flutterVC: FlutterViewController?
    private var translationPlugin: TranslationPlugin?

    private var mainChannel: FlutterMethodChannel?
    private var eventsChannel: FlutterMethodChannel?

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?

    private var globalMonitor: Any?
    private var resignObserver: NSObjectProtocol?

    private let shadowInset: CGFloat = 24
    private let contentWidth: CGFloat = 640
    private var contentHeight: CGFloat = 72
    private let maxContentHeight: CGFloat = 520

    private var panelWidth: CGFloat { contentWidth + shadowInset * 2 }
    private var panelHeight: CGFloat { contentHeight + shadowInset * 2 }

    var isVisible: Bool { panel?.isVisible ?? false }

    func setup(mainEngine: FlutterEngine) {
        mainChannel = FlutterMethodChannel(
            name: "vocabo/spotlight",
            binaryMessenger: mainEngine.binaryMessenger
        )
        mainChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "setEnabled":
                let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
                self?.setHotKeyEnabled(enabled)
                result(nil)
            case "show":
                self?.show()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Hotkey

    private func setHotKeyEnabled(_ enabled: Bool) {
        if enabled {
            registerHotKey()
        } else {
            unregisterHotKey()
            hide()
        }
    }

    private func registerHotKey() {
        guard hotKeyRef == nil else { return }

        if hotKeyHandler == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, _, userData in
                    guard let userData = userData else { return noErr }
                    let controller = Unmanaged<SpotlightPanelController>
                        .fromOpaque(userData)
                        .takeUnretainedValue()
                    DispatchQueue.main.async { controller.toggle() }
                    return noErr
                },
                1,
                &eventType,
                Unmanaged.passUnretained(self).toOpaque(),
                &hotKeyHandler
            )
        }

        let hotKeyId = EventHotKeyID(signature: OSType(0x5643_4253), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey),
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        NSLog("[Vocabo] Spotlight: hotkey registration status %d", status)
    }

    private func unregisterHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    // MARK: - Visibility

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        if panel == nil { createPanel() }
        guard let panel = panel else { return }

        panel.setFrame(frameForCurrentScreen(), display: true)
        panel.makeKeyAndOrderFront(nil)
        eventsChannel?.invokeMethod("shown", arguments: nil)
        startMonitoring()
    }

    func hide() {
        stopMonitoring()
        guard let panel = panel, panel.isVisible else { return }
        panel.orderOut(nil)
        eventsChannel?.invokeMethod("hidden", arguments: nil)
    }

    /// Centered horizontally, with its top at about a quarter of the screen
    /// with the mouse cursor, so it opens where the user is looking.
    private func frameForCurrentScreen() -> NSRect {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) })
            ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let top = visible.maxY - visible.height * 0.22 + shadowInset
        return NSRect(
            x: visible.midX - panelWidth / 2,
            y: top - panelHeight,
            width: panelWidth,
            height: panelHeight
        )
    }

    private func setContentHeight(_ height: CGFloat) {
        let clamped = min(max(height, 56), maxContentHeight)
        guard clamped != contentHeight else { return }
        contentHeight = clamped

        guard let panel = panel else { return }
        var frame = panel.frame
        let top = frame.maxY
        frame.size.height = panelHeight
        frame.origin.y = top - panelHeight
        panel.setFrame(frame, display: true)
    }

    // MARK: - Monitors

    private func startMonitoring() {
        stopMonitoring()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hide()
        }

        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.hide()
        }
    }

    private func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let observer = resignObserver {
            NotificationCenter.default.removeObserver(observer)
            resignObserver = nil
        }
    }

    // MARK: - Panel

    private func createPanel() {
        let engine = FlutterEngine(name: "spotlight", project: nil)
        engine.run(withEntrypoint: "spotlightMain")
        RegisterGeneratedPlugins(registry: engine)

        translationPlugin = TranslationPlugin()
        translationPlugin?.register(with: engine.binaryMessenger)

        flutterEngine = engine
        flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        flutterVC?.backgroundColor = .clear

        eventsChannel = FlutterMethodChannel(
            name: "vocabo/spotlight_events",
            binaryMessenger: engine.binaryMessenger
        )

        let actionsChannel = FlutterMethodChannel(
            name: "vocabo/spotlight_actions",
            binaryMessenger: engine.binaryMessenger
        )
        actionsChannel.setMethodCallHandler { [weak self] call, result in
            let args = call.arguments as? [String: Any]
            switch call.method {
            case "hide":
                result(nil)
                self?.hide()
            case "setHeight":
                if let height = args?["height"] as? Double {
                    self?.setContentHeight(CGFloat(height))
                }
                result(nil)
            case "vocabularyChanged":
                result(nil)
                self?.mainChannel?.invokeMethod("vocabularyChanged", arguments: nil)
            case "openWord":
                result(nil)
                self?.hide()
                self?.mainChannel?.invokeMethod("openWord", arguments: args)
                if let mainWindow = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
                    mainWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let panel = SpotlightPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = flutterVC
        panel.isFloatingPanel = true
        panel.level = .modalPanel
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        self.panel = panel
    }
}
