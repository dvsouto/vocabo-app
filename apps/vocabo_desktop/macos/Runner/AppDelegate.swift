import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Setup tray panel controller with the main Flutter engine
    if let mainWindow = NSApp.windows.first,
       let flutterVC = mainWindow.contentViewController as? FlutterViewController {
      TrayPanelController.shared.setup(mainEngine: flutterVC.engine)
    }
  }
}
