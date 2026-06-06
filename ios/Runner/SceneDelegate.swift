import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url {
      NativeUniversalLinkBridge.shared.setInitial(url: url.absoluteString)
    }
    if let activity = connectionOptions.userActivities.first,
       activity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = activity.webpageURL {
      NativeUniversalLinkBridge.shared.setInitial(url: url.absoluteString)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if let url = URLContexts.first?.url {
      NativeUniversalLinkBridge.shared.publish(url: url.absoluteString)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      NativeUniversalLinkBridge.shared.publish(url: url.absoluteString)
    }
    super.scene(scene, continue: userActivity)
  }
}
