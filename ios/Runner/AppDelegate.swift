import Flutter
import UIKit

/// One explicit engine, shared between the app delegate (which runs it and
/// registers plugins) and the scene delegate (which displays it).
///
/// On this Flutter version the implicit engine that runs Dart `main()` under the
/// UIScene lifecycle is a *different* instance than any plugin-registration hook
/// reaches (AppDelegate, didInitializeImplicitFlutterEngine, pluginRegistrant),
/// so channels like FirebaseCoreHostApi.initializeCore are unreachable from Dart
/// and main() crashes at Firebase.initializeApp (flutter#185048, #185935). Owning
/// the engine guarantees main() and the plugins live on the same instance, with no
/// dependency on the timing of an auto-created view controller.
let flutterEngine = FlutterEngine(name: "riff")

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_contacts (1.1.9+2) force-unwraps
    // UIApplication.shared.delegate!.window!!.rootViewController! at registration.
    // Under UIScene the app-delegate window is nil, so give it a throwaway one to
    // satisfy the unwrap. Never presented on — the app only calls
    // FlutterContacts.getContacts() (no native picker). The visible window belongs
    // to the scene.
    if window == nil {
      let placeholder = UIWindow(frame: UIScreen.main.bounds)
      placeholder.rootViewController = UIViewController()
      window = placeholder
    }

    // Run main() on our engine, then register plugins on the SAME engine. The
    // platform thread stays inside this method, so registration is complete before
    // any Dart→platform channel message (e.g. Firebase's) is dispatched.
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Displays the shared engine in the scene's window. iOS 26 renders Flutter
/// through a scene-owned window, so the FlutterViewController is created here
/// (not in the AppDelegate, which produced a black screen under the classic
/// lifecycle). super is intentionally NOT called: FlutterSceneDelegate would spin
/// up its own storyboard-backed FlutterViewController on a second engine and run
/// main() twice. Once this view is in the hierarchy Flutter auto-forwards scene
/// life-cycle events to `flutterEngine`, and the other (non-overridden)
/// FlutterSceneDelegate callbacks (openURLContexts, foreground/background) still
/// reach plugins.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let flutterVC = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    let sceneWindow = UIWindow(windowScene: windowScene)
    sceneWindow.rootViewController = flutterVC
    window = sceneWindow
    sceneWindow.makeKeyAndVisible()
  }
}
