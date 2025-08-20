import Firebase
import Flutter
import UIKit
import UnityFramework

@main
@objc class AppDelegate: FlutterAppDelegate {
  var ufw: UnityFramework?
  func initUnity() {
    if ufw == nil {
      guard let bundlePath = Bundle.main.path(forResource: "UnityFramework", ofType: "framework", inDirectory: "Frameworks"),
            let bundle = Bundle(path: bundlePath) else {
        print("[iOS] UnityFramework bundle 못찾거나 경로 잘못됨")
        return
      }

      if !bundle.isLoaded { bundle.load() }

      guard let ufwClass = bundle.principalClass as? UnityFramework.Type else {
        print("[iOS] UnityFramework 못찾음")
        return
      }

      if ufw == nil {
        ufw = ufwClass.getInstance()
      }

      ufw?.setDataBundleId("com.unity3d.framework")
      ufw?.runEmbedded(withArgc: CommandLine.argc,
                       argv: CommandLine.unsafeArgv,
                       appLaunchOpts: nil)
      print("[iOS] UnityFramework 시작함")
    }
  }
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Unity MethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.musai_f/unity_ar",
                                       binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "SetJwtToken":
        guard let token = call.arguments as? String, !token.isEmpty else {
          print("[iOS] 유니티에 전달할 토큰이 잘못됨")
          result(FlutterError(code: "INVALID_TOKEN", message: "JWT must be a non-empty String", details: nil))
          return
        }
        // 엔진 초기화 후 실행
        self.initUnity()
        self.ufw?.showUnityWindow()

        if let ufw = self.ufw {
          ufw.sendMessageToGO(withName: "ARCamera",
                              functionName: "SetJwtToken",
                              message: token)
          print("[iOS] JWT 토큰 Unity에 전달 성공  (len=\(token.count))")
          result(true)
        } else {
          print("[iOS] UnityFramework이 없어서 토큰 전송 실패")
          result(FlutterError(code: "UNITY_ERROR", message: "UnityFramework not initialized", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
