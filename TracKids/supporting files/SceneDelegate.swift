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
    var count: Int = 0
    var message: String = ""

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard scene is UIWindowScene else { return }
        locationManager.delegate = self
        UNUserNotificationCenter.current().delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = CLLocationDistance(100)
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Location Manager Delegate Methods.
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
    // MARK: - function to handle sending push notification in background.
    func handleEvent(for region: CLRegion, withType event: String) {
        var childName: String = " "
        DataHandler.shared.fetchUserInfo { user in
            childName = user.name
            self.message = "your child  \(String(describing: childName))  \(event)  \(region.identifier)"
            print("Debug: message in fetch  \(self.message)")
            guard let parentID = user.parentID else {return}
            DataHandler.shared.fetchDeviceID(for: parentID) { parentDeviceToken in
                DataHandler.shared.sendPushNotification(to: parentDeviceToken, sender: childName, body: self.message)
                if UIApplication.shared.applicationState == .active {
                    print("Debug: Geofence active!")
                } else {
                    print("Debug: Geofence inactive!")
                    let notificationContent   = UNMutableNotificationContent()
                    notificationContent.body  = self.message
                    notificationContent.sound = .default
                    notificationContent.badge = UIApplication.shared
                        .applicationIconBadgeNumber + 1 as NSNumber
                    let trigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: 1,
                        repeats: false)
                    let request = UNNotificationRequest(
                        identifier: "location_change",
                        content: notificationContent,
                        trigger: trigger)
                    UNUserNotificationCenter.current().add(request) { error in
                        print("Geofence request! ")
                        if let error = error {
                            print("Error: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate Methods.
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
