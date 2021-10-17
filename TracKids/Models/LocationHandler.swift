//
//  LocationHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/8/21.
//

import CoreLocation
import Firebase
import GeoFire
class LocationHandler : NSObject,CLLocationManagerDelegate{
    static let shared = LocationHandler()
    var locationManager: CLLocationManager!
    var location : CLLocation?
    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .notDetermined:
            print("not determined")
            break
        case .restricted , .denied:
            print("restricted")
            break
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("always auth")
            
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            print("default")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geofire = GeoFire(firebaseRef: childLocationReference)
        childLocationReference.observe(.value) { (snapshot) in
            guard let lastLocation = locations.last else {return}
            guard   let UId =  Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchUserInfo() { (user) in
                let currentUser = user
                if currentUser.accountType == 1 {
                    geofire.setLocation(lastLocation, forKey: UId) { (error) in
                        print("new child created")
                        if error != nil {print(error!.localizedDescription )}
                    }
                }
            }
        }
    }
}
