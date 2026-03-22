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
        NSLog("[Vocabo] TrayPanelController: Setting up method channel on main engine")

        methodChannel = FlutterMethodChannel(
            name: "vocabo/tray_panel",
            binaryMessenger: mainEngine.binaryMessenger
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            NSLog("[Vocabo] TrayPanelController: Received method call: %@", call.method)

            switch call.method {
            case "toggle":
                var point: NSPoint? = nil
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? Double,
                   let y = args["y"] as? Double {
                    point = NSPoint(x: x, y: y)
                    NSLog("[Vocabo] TrayPanelController: Toggle at position (%.1f, %.1f)", x, y)
                } else {
                    NSLog("[Vocabo] TrayPanelController: Toggle without position")
                }
                self?.toggle(at: point)
                result(nil)
            case "show":
                if let args = call.arguments as? [String: Any],
                   let x = args["x"] as? Double,
                   let y = args["y"] as? Double {
                    self?.show(at: NSPoint(x: x, y: y))
                }
                result(nil)
            case "hide":
                self?.hide()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        NSLog("[Vocabo] TrayPanelController: Method channel setup complete")
    }

    func show(at point: NSPoint) {
        NSLog("[Vocabo] TrayPanelController: show() called at (%.1f, %.1f)", point.x, point.y)

        if panel == nil {
            NSLog("[Vocabo] TrayPanelController: Creating panel for the first time")
            createPanel()
        }

        guard let panel = panel else {
            NSLog("[Vocabo] TrayPanelController: ERROR - Panel is nil after creation")
            return
        }

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 500

        // Find the screen that contains the tray icon position
        // Dart sends coordinates in top-left system; convert to macOS bottom-left
        let primaryScreen = NSScreen.screens.first
        let primaryHeight = primaryScreen?.frame.height ?? 900
        let menuBarHeight: CGFloat = NSStatusBar.system.thickness

        // Convert Dart top-left coords to macOS bottom-left coords
        // In macOS, all screens share a coordinate space with origin at bottom-left of primary screen
        let macOsX = point.x
        let macOsY = primaryHeight - point.y - menuBarHeight

        // Ensure panel doesn't go off-screen to the right
        let screen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: macOsX, y: macOsY)) }) ?? primaryScreen
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let clampedX = min(macOsX, screenFrame.maxX - panelWidth)

        let frame = NSRect(
            x: clampedX,
            y: macOsY - panelHeight,
            width: panelWidth,
            height: panelHeight
        )

        NSLog("[Vocabo] TrayPanelController: primaryHeight: %.1f, menuBar: %.1f, screen: %@",
              primaryHeight, menuBarHeight, NSStringFromRect(screenFrame))
        NSLog("[Vocabo] TrayPanelController: Setting panel frame to (%.1f, %.1f, %.1f, %.1f)",
              frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)

        panel.setFrame(frame, display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)

        NSLog("[Vocabo] TrayPanelController: Panel is now visible: %@", panel.isVisible ? "YES" : "NO")
    }

    func hide() {
        NSLog("[Vocabo] TrayPanelController: hide() called")
        panel?.orderOut(nil)
    }

    func toggle(at point: NSPoint?) {
        if isVisible {
            NSLog("[Vocabo] TrayPanelController: Panel is visible, hiding")
            hide()
        } else if let point = point {
            NSLog("[Vocabo] TrayPanelController: Panel is hidden, showing")
            show(at: point)
        } else {
            NSLog("[Vocabo] TrayPanelController: No position provided, cannot show")
        }
    }

    private func createPanel() {
        NSLog("[Vocabo] TrayPanelController: Creating secondary Flutter engine")

        let engine = FlutterEngine(name: "tray_panel", project: nil)
        let started = engine.run(withEntrypoint: "trayPanelMain")
        NSLog("[Vocabo] TrayPanelController: Engine started with entrypoint 'trayPanelMain': %@",
              started ? "YES" : "NO")

        RegisterGeneratedPlugins(registry: engine)
        NSLog("[Vocabo] TrayPanelController: Plugins registered for secondary engine")

        flutterEngine = engine
        flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)

        // Setup actions channel on the secondary engine
        let actionsChannel = FlutterMethodChannel(
            name: "vocabo/tray_panel_actions",
            binaryMessenger: engine.binaryMessenger
        )
        actionsChannel.setMethodCallHandler { [weak self] call, result in
            NSLog("[Vocabo] TrayPanelController: Action received: %@", call.method)
            switch call.method {
            case "openApp":
                self?.hide()
                if let mainWindow = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
                    mainWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
                result(nil)
            case "quitApp":
                NSApp.terminate(nil)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 500),
            styleMask: [.titled, .fullSizeContentView],
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
        NSLog("[Vocabo] TrayPanelController: Panel created successfully")
    }
}
