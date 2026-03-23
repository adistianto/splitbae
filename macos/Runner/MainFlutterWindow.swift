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
  private var _didApplyMinSizeFix = false

  override func awakeFromNib() {
    // Ensure the NSWindow is fully initialized from the nib (frame/rect, etc.)
    // before we query it or apply any Flutter-specific configuration.
    super.awakeFromNib()

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

    // Keep the window from collapsing to an "empty" 1x1 size during
    // initial AppKit layout (observed on debug startup).
    let desiredSize = NSSize(width: 800, height: 600)
    self.minSize = desiredSize

    // Ensure the host view immediately matches the window content bounds.
    // Without this, the host view can end up with a ~0x0 size, causing
    // the window to collapse to {1,1} after AppKit layout.
    if let cv = self.contentView {
      host.view.frame = cv.bounds
      host.view.autoresizingMask = [.width, .height]
    }

    // Log any resize after startup; we want to see when/why it collapses.
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResizeNotification,
      object: self,
      queue: .main
    ) { _ in
      let contentBounds = self.contentView?.bounds ?? NSRect.zero

      if !self._didApplyMinSizeFix,
         contentBounds.size.width < 50,
         contentBounds.size.height < 50 {
        self._didApplyMinSizeFix = true
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        if let screenFrame {
          let x = screenFrame.origin.x + (screenFrame.size.width - desiredSize.width) / 2
          let y = screenFrame.origin.y + (screenFrame.size.height - desiredSize.height) / 2
          // Schedule restore after the current AppKit resize/layout cycle.
          // Doing it immediately inside didResize can get overridden back to {1,1}.
          DispatchQueue.main.async {
            self.setFrame(
              NSRect(x: x, y: y, width: desiredSize.width, height: desiredSize.height),
              display: true
            )
            self.setContentSize(desiredSize)
            self.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.contentView?.layoutSubtreeIfNeeded()
          }
        }
      }
    }

    // Center and ensure the window is on-screen.
    // Our observed `self.frame` can end up as { {x, y}, {1,1} } on debug startup
    // (invisible window). Force a reasonable window rect based on screen.
    let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
    if let screenFrame {
      let x = screenFrame.origin.x + (screenFrame.size.width - desiredSize.width) / 2
      let y = screenFrame.origin.y + (screenFrame.size.height - desiredSize.height) / 2
      self.setFrame(NSRect(x: x, y: y, width: desiredSize.width, height: desiredSize.height),
                     display: true)
      self.setContentSize(desiredSize)
    }

    self.center()
    self.orderFrontRegardless()
    self.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    // #endregion agent log

    RegisterGeneratedPlugins(registry: flutterViewController)
    AppDelegate.registerReceiptOcrChannel(controller: flutterViewController)
  }
}
