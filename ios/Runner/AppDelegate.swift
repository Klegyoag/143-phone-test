import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var privacyShield: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(captureStateChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    showPrivacyShield()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if !UIScreen.main.isCaptured { hidePrivacyShield() }
  }

  @objc private func captureStateChanged() {
    UIScreen.main.isCaptured ? showPrivacyShield() : hidePrivacyShield()
  }

  private func showPrivacyShield() {
    guard privacyShield == nil, let window = self.window else { return }
    let shield = UIView(frame: window.bounds)
    shield.backgroundColor = UIColor.systemBackground
    shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    let label = UILabel(frame: shield.bounds.insetBy(dx: 28, dy: 28))
    label.text = "143 · Private"
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
    label.textColor = UIColor.secondaryLabel
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    shield.addSubview(label)
    window.addSubview(shield)
    privacyShield = shield
  }

  private func hidePrivacyShield() {
    privacyShield?.removeFromSuperview()
    privacyShield = nil
  }
}
