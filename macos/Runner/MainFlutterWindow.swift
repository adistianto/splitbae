import Cocoa
import FlutterMacOS

/// Hosts a subtle `NSVisualEffectView` behind the Flutter surface so the window keeps native
/// material presence while remaining transparent for Liquid Glass / shader content.
private final class SplitBaeFlutterHostViewController: NSViewController {
  let flutterViewController: FlutterViewController

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(flutterViewController)

    let effectView = NSVisualEffectView()
    effectView.material = .underWindowBackground
    effectView.blendingMode = .behindWindow
    effectView.state = .active
    effectView.translatesAutoresizingMaskIntoConstraints = false

    flutterViewController.view.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(effectView)
    view.addSubview(flutterViewController.view)

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      effectView.topAnchor.constraint(equalTo: view.topAnchor),
      effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      flutterViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      flutterViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      flutterViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
      flutterViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let host = SplitBaeFlutterHostViewController(flutterViewController: flutterViewController)

    styleMask.insert(.fullSizeContentView)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isOpaque = false
    backgroundColor = .clear

    contentViewController = host

    let windowFrame = self.frame
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    AppDelegate.registerReceiptOcrChannel(controller: flutterViewController)

    super.awakeFromNib()
  }
}
