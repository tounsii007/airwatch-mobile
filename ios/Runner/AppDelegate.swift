import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var blurView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    let blur = UIView(frame: window?.frame ?? .zero)
    blur.backgroundColor = .black
    blur.tag = 999
    window?.addSubview(blur)
    blurView = blur
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
