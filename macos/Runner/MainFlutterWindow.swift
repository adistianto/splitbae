import Cocoa
import FlutterMacOS

/// Bottom `NSVisualEffectView` + transparent Flutter surface so desktop/vibrancy shows through.
private final class SplitBaeFlutterHostViewController: NSViewController {
  let flutterViewController: FlutterViewController

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let root = NSView()
    root.wantsLayer = true
    root.layer?.backgroundColor = NSColor.clear.cgColor
    view = root
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    addChild(flutterViewController)

    let effectView = NSVisualEffectView()
    effectView.material = .underWindowBackground
    effectView.blendingMode = .behindWindow
    effectView.state = .active
    effectView.translatesAutoresizingMaskIntoConstraints = false

    let flutterSurface = flutterViewController.view
    flutterSurface.translatesAutoresizingMaskIntoConstraints = false
    flutterSurface.wantsLayer = true
    flutterSurface.layer?.backgroundColor = NSColor.clear.cgColor

    // Subview order: first = back (vibrancy), second = front (Flutter).
    view.addSubview(effectView)
    view.addSubview(flutterSurface)

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      effectView.topAnchor.constraint(equalTo: view.topAnchor),
      effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      flutterSurface.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      flutterSurface.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      flutterSurface.topAnchor.constraint(equalTo: view.topAnchor),
      flutterSurface.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // FlutterView defaults to black; must clear before the view hierarchy loads for transparency.
    flutterViewController.backgroundColor = .clear

    styleMask.insert(.fullSizeContentView)
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    isOpaque = false
    backgroundColor = .clear
    hasShadow = true

    let host = SplitBaeFlutterHostViewController(flutterViewController: flutterViewController)
    contentViewController = host

    let windowFrame = self.frame
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    AppDelegate.registerReceiptOcrChannel(controller: flutterViewController)

    super.awakeFromNib()
  }
}
