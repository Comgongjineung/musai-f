import Firebase
import Flutter
import UIKit
import UnityFramework

@main
@objc class AppDelegate: FlutterAppDelegate {
  var ufw: UnityFramework?
  var unityAppBar: UIView?
  // Unity 초기화
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

  @objc func showUnityWithAppBar(title: String = "musai") {
    initUnity()
    ufw?.showUnityWindow()

    guard let unityRootView = ufw?.appController()?.rootViewController?.view else {
      print("[iOS] Unity root view 없음")
      return
    }

    // 기존 바가 있다면 제거
    unityAppBar?.removeFromSuperview()

    let statusHeight = UIApplication.shared.statusBarFrame.height
    let topOffset: CGFloat = statusHeight + 52 // move bar down by 52pt
    let barHeight: CGFloat = 44
    let bar = UIView(frame: CGRect(x: 0, y: topOffset, width: unityRootView.bounds.width, height: barHeight))
    bar.backgroundColor = .clear // no background block
    bar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

    // 뒤로가기 버튼 (larger icon)
    let back = UIButton(type: .system)
    back.setTitle("\u{276E}", for: .normal) // ‹
    back.setTitleColor(UIColor(red: 254/255.0, green: 253/255.0, blue: 252/255.0, alpha: 1.0), for: .normal) // #FEFDFC
    back.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
    back.frame = CGRect(x: 24, y: (barHeight - 32) / 2, width: 44, height: 32)
    back.addTarget(self, action: #selector(self.onUnityBack), for: .touchUpInside)
    bar.addSubview(back)

    // 타이틀 라벨
    let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bar.bounds.width, height: barHeight))
    titleLabel.textAlignment = .center
    titleLabel.textColor = UIColor(red: 254/255.0, green: 253/255.0, blue: 252/255.0, alpha: 1.0) // #FEFDFC
    titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
    titleLabel.text = title
    titleLabel.autoresizingMask = [.flexibleWidth]
    bar.addSubview(titleLabel)

    unityRootView.addSubview(bar)
    unityRootView.bringSubviewToFront(bar)
    self.unityAppBar = bar
  }

  @objc func onUnityBack() {
    // Unity 종료 및 오버레이 제거 → Flutter로 즉시 복귀
    unityAppBar?.removeFromSuperview()
    unityAppBar = nil

    // Unity 쪽 안전 종료 시도 (relaunch 시 검은 화면 방지)
    if let app = ufw?.appController(), app.responds(to: Selector(("quitApplication:"))) {
      _ = app.perform(Selector(("quitApplication:")), with: 0)
    }

    ufw?.pause(true)
    ufw?.unloadApplication()
    ufw = nil

    // Flutter 루트를 다시 최상위로
    if let flutterVC = window?.rootViewController {
      flutterVC.view.isHidden = false
      window?.bringSubviewToFront(flutterVC.view)
      window?.makeKeyAndVisible()
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
        self.showUnityWithAppBar(title: "musai")

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
      case "CloseUnity":
        self.onUnityBack()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
