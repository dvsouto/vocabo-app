import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var translationPlugin: TranslationPlugin?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    translationPlugin = TranslationPlugin()
    translationPlugin?.register(with: flutterViewController.engine.binaryMessenger)

    // Setup tray panel controller here — engine is guaranteed to exist
    NSLog("[Vocabo] MainFlutterWindow: Setting up TrayPanelController")
    TrayPanelController.shared.setup(mainEngine: flutterViewController.engine)

    super.awakeFromNib()
  }
}
