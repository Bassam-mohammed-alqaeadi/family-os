import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pairingBrightnessChannel = "com.familyos.family_os/pairing_brightness"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(
        name: pairingBrightnessChannel,
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { call, result in
        switch call.method {
        case "maximize":
          let previous = UIScreen.main.brightness
          UIScreen.main.brightness = 1.0
          result(Double(previous))
        case "restore":
          let arguments = call.arguments as? [String: Any]
          if let previous = arguments?["brightness"] as? Double {
            UIScreen.main.brightness = CGFloat(previous)
          }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
