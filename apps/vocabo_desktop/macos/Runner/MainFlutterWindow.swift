import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Setup tray panel controller here — engine is guaranteed to exist
    NSLog("[Vocabo] MainFlutterWindow: Setting up TrayPanelController")
    TrayPanelController.shared.setup(mainEngine: flutterViewController.engine)

    super.awakeFromNib()
  }
}
