import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var screenSecurityOverlay: UIView?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.unvault/screen_security",
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "enableProtection":
                self?.enableScreenProtection()
                result(nil)
            case "disableProtection":
                self?.disableScreenProtection()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func enableScreenProtection() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureDidChange),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        // Check current state
        if UIScreen.main.isCaptured {
            showOverlay()
        }
    }

    private func disableScreenProtection() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        hideOverlay()
    }

    @objc private func screenCaptureDidChange() {
        if UIScreen.main.isCaptured {
            showOverlay()
        } else {
            hideOverlay()
        }
    }

    private func showOverlay() {
        guard screenSecurityOverlay == nil, let window = self.window else { return }
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let label = UILabel()
        label.text = "Screen recording detected"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        ])

        window.addSubview(overlay)
        screenSecurityOverlay = overlay
    }

    private func hideOverlay() {
        screenSecurityOverlay?.removeFromSuperview()
        screenSecurityOverlay = nil
    }
}
