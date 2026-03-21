import Cocoa
import FlutterMacOS

class TrayPanelController {
    private var panel: NSPanel?
    private var flutterEngine: FlutterEngine?
    private var flutterVC: FlutterViewController?
    private var methodChannel: FlutterMethodChannel?

    static let shared = TrayPanelController()

    var isVisible: Bool {
        return panel?.isVisible ?? false
    }

    func setup(mainEngine: FlutterEngine) {
        // Listen for show/hide commands from the main Dart isolate
        methodChannel = FlutterMethodChannel(
            name: "vocabo/tray_panel",
            binaryMessenger: mainEngine.binaryMessenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "toggle":
                guard let args = call.arguments as? [String: Any],
                      let x = args["x"] as? Double,
                      let y = args["y"] as? Double else {
                    self?.toggle(at: nil)
                    result(nil)
                    return
                }
                self?.toggle(at: NSPoint(x: x, y: y))
                result(nil)
            case "show":
                guard let args = call.arguments as? [String: Any],
                      let x = args["x"] as? Double,
                      let y = args["y"] as? Double else {
                    result(FlutterError(code: "INVALID_ARGS", message: "x, y required", details: nil))
                    return
                }
                self?.show(at: NSPoint(x: x, y: y))
                result(nil)
            case "hide":
                self?.hide()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func show(at point: NSPoint) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 500

        // Position: top-left of panel aligned below the tray icon
        // macOS coordinates: origin is bottom-left of screen
        // point.x = tray icon left edge, point.y = tray icon bottom edge
        let frame = NSRect(
            x: point.x,
            y: point.y - panelHeight,
            width: panelWidth,
            height: panelHeight
        )
        panel.setFrame(frame, display: true)
        panel.makeKeyAndOrderFront(nil)

        // Auto-hide when clicking outside
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle(at point: NSPoint?) {
        if isVisible {
            hide()
        } else if let point = point {
            show(at: point)
        }
    }

    private func createPanel() {
        // Create a secondary Flutter engine for the tray panel
        let engine = FlutterEngine(name: "tray_panel", project: nil)
        engine.run(withEntrypoint: "trayPanelMain")
        RegisterGeneratedPlugins(registry: engine)

        flutterEngine = engine
        flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)

        // Create an NSPanel (floating, borderless)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 500),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = flutterVC
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isOpaque = false

        // Round corners
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 16
        panel.contentView?.layer?.masksToBounds = true

        self.panel = panel
    }
}
