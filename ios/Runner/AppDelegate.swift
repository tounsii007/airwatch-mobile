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

  // Snapshot blocker uses willResignActive / didBecomeActive (not the
  // background lifecycle) so phone-call interrupts, Control-Center pulls,
  // notification banners, and the app-switcher snapshot are all covered.
  // willResignActive fires earlier than didEnterBackground (which doesn't
  // fire at all for transient interrupts), and didBecomeActive mirrors it
  // by firing on return from any interruption.
  override func applicationWillResignActive(_ application: UIApplication) {
    addBlurView()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    removeBlurView()
  }

  private func addBlurView() {
    guard blurView == nil else { return }
    let blur = UIView(frame: window?.frame ?? .zero)
    blur.backgroundColor = .black
    blur.tag = 999
    window?.addSubview(blur)
    blurView = blur
  }

  private func removeBlurView() {
    blurView?.removeFromSuperview()
    blurView = nil
  }
}
