//
//  SceneDelegate.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    var count : Int = 0
    var message : String = ""
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
       
        guard let _ = (scene as? UIWindowScene) else { return }
        locationManager.delegate = self
        UNUserNotificationCenter.current().delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = CLLocationDistance(100)
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
      UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      UNUserNotificationCenter.current().removeAllDeliveredNotifications()

    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

    // MARK: - Location Manager Delegate
    extension SceneDelegate: CLLocationManagerDelegate {
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let lastLocation = locations.last else {return}
            LocationHandler.shared.uploadChildLocation(for: lastLocation)
            LocationHandler.shared.uploadLocationHistory(for: lastLocation)
           }

      func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
      ) {
        if region is CLCircularRegion {
            handleEvent(for: region, withType: "arrived")
            print("geo exit")
        }
      }

      func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
      ) {
        if region is CLCircularRegion {
          handleEvent(for: region, withType: "left")
            print("geo exit")
        }
      }
    
    func handleEvent(for region: CLRegion, withType event : String) {
        var childName : String = " "
        DataHandler.shared.fetchUserInfo { (user) in
            childName = user.name
            self.message = "your child  \(String(describing: childName))  \(event)  \(region.identifier)"
            print(" message in fetch  \(self.message)")
            guard let parentID = user.parentID else{return}
            DataHandler.shared.fetchDeviceID(for: parentID) { parentDeviceToken in
            DataHandler.shared.sendPushNotification(to: parentDeviceToken, sender: childName, body: self.message)
             }
           }
        }
    } 

extension SceneDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if var badgeCount = UserDefaults.standard.value(forKey: "badgeCount") as? Int {
            badgeCount += 1
            UserDefaults.standard.setValue(badgeCount, forKey: "badgeCount")
            UIApplication.shared.applicationIconBadgeNumber = badgeCount
        }
        completionHandler([[.banner, .sound]])
    }
      
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse,
      withCompletionHandler completionHandler: @escaping () -> Void
    ) {
       if var badgeCount = UserDefaults.standard.value(forKey: "badgeCount") as? Int {
            badgeCount += 1
            UserDefaults.standard.setValue(badgeCount, forKey: "badgeCount")
            UIApplication.shared.applicationIconBadgeNumber = badgeCount
        }
       
      completionHandler()
    }
    
    


}
