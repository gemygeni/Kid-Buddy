//
//  AppDelegate.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import IQKeyboardManagerSwift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let NOTIFICATION_URL = "https://fcm.googleapis.com/fcm/send"
                                   
    static var DEVICEID = String()
    
    static let SERVERKEY = "AAAAv5tBZAc:APA91bGm3eTsLaqQMDCjXHvHRfpxyIx5GqOo87Owdb8UWb1ZQyGav9eR2jk6yJgMiMK3M6rt5aS-dOl1BjupMBaTDgaDYKrT8-gI5IztH-s9ZZozPFAqp5HSmm1WI08xMCPTGLuXEqvL"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        Database.database().isPersistenceEnabled = true
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        registerForPushNotifications()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.setValue(0, forKey: "badgeCount")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    
    func application(_ app: UIApplication, open url: URL, options:
                        [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Your incoming link parameter is \(url.absoluteString)")

        let isDynamicLink = DynamicLinks.dynamicLinks().shouldHandleDynamicLink(fromCustomSchemeURL: url)
        
        if isDynamicLink {
            let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)
        print("dynamic with allready installed")
        return handleDynamicLink(dynamicLink)
 
            
        }
      return false
    }

    private func application(_ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
      let dynamicLinks = DynamicLinks.dynamicLinks()
      let handled = dynamicLinks.handleUniversalLink(userActivity.webpageURL!) { (dynamicLink, error) in
        if (dynamicLink != nil) && !(error != nil) {
            print("dynamic with non installed")
            self.handleDynamicLink(dynamicLink)
        }
      }
        
      if !handled {
        // Handle incoming URL with other methods as necessary
        // ...
      }
      return handled
    }


    func handleDynamicLink(_ dynamicLink: DynamicLink?) -> Bool {
      guard let dynamicLink = dynamicLink else { return false }
      guard let deepLink = dynamicLink.url else { return false }
        print("Your incoming link parameter22 is \(deepLink.absoluteString)")
        guard
          dynamicLink.matchType == .unique ||
          dynamicLink.matchType == .default
        else {
          return false
        }
      return true
    }
    
    //push notification stuff
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        var authOptions: UNAuthorizationOptions?
        if #available(iOS 12.0, *) {
            authOptions = [.alert, .badge, .sound, .criticalAlert]
            print("granted critical")
        } else {
            authOptions = [.alert, .badge, .sound]
        }
        
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: authOptions!) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
          }
       }

    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
 }



extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { (token, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error.localizedDescription)")
            } else if let token = token {
                AppDelegate.DEVICEID = token
                guard let uid = Auth.auth().currentUser?.uid else {return}
                let Reference = UserReference.child(uid)
                Reference.updateChildValues(["deviceID" : token])
                print("Token is \(token)")
            }
        }
    }
    
    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      print("Failed to register: \(error)")
    }
  }

extension AppDelegate: MessagingDelegate {
  func messaging(
    _ messaging: Messaging,
    didReceiveRegistrationToken fcmToken: String?
  ) {
    let tokenDict = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: tokenDict)
  }
    
    
    }
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        Messaging.messaging().token { (token, error) in
                if let error = error {
                    print("Error fetching remote instance ID: \(error.localizedDescription)")
                } else if let newToken = token {
                    AppDelegate.DEVICEID = newToken
                    guard let uid = Auth.auth().currentUser?.uid else {return}
                    let Reference = UserReference.child(uid)
                    Reference.updateChildValues(["deviceID" : newToken])
                }
            }
       }
