import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Apple Pencil 필기 오버레이(아이패드). 손가락 터치는 Flutter로 통과시킨다.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PencilCanvasPlugin") {
      PencilCanvasPlugin.register(with: registrar)
    }
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    guard let window = application.windows.first(where: { $0.isKeyWindow }) else { return }
    if privacyOverlay != nil { return }
    if let launchView = Bundle.main.loadNibNamed("LaunchScreen", owner: nil)?.first as? UIView {
      launchView.frame = window.bounds
      launchView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      window.addSubview(launchView)
      privacyOverlay = launchView
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
