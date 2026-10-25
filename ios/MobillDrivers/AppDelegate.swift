import UIKit
import MachO
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    installExceptionRecorder()

    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    return true
  }
}

// Crash logs from React Native method calls only show that an exception was rethrown;
// the name, reason and throw site are lost. Record them before the process aborts.
// Read with: xcrun devicectl device copy from --domain-type appDataContainer
//   --domain-identifier com.mobill.drivers --source Documents/last_exception.txt
private func installExceptionRecorder() {
  NSSetUncaughtExceptionHandler { exception in
    let header = String(format: "slide=0x%lx", _dyld_get_image_vmaddr_slide(0))
    let lines = [
      ISO8601DateFormatter().string(from: Date()),
      "name=\(exception.name.rawValue)",
      "reason=\(exception.reason ?? "nil")",
      header,
    ] + exception.callStackSymbols
    let text = lines.joined(separator: "\n") + "\n"
    NSLog("UNCAUGHT EXCEPTION\n%@", text)
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      try? text.write(to: dir.appendingPathComponent("last_exception.txt"), atomically: true, encoding: .utf8)
    }
  }
}

// iOS 27 terminates apps built with its SDK that don't use the UIScene lifecycle,
// so the window is created here instead of in the app delegate.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene,
          let appDelegate = UIApplication.shared.delegate as? AppDelegate,
          let factory = appDelegate.reactNativeFactory else { return }

    let window = UIWindow(windowScene: windowScene)
    self.window = window
    appDelegate.window = window

    factory.startReactNative(
      withModuleName: "MobillDrivers",
      in: window,
      launchOptions: nil
    )
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
