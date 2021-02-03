//
//  HomeViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/30/21.
//

import UIKit
import MapKit
import Firebase
import CoreLocation


class TrackingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleLocationServices()
        
        configureMapView()
        
        
    }
    
    @IBOutlet weak var mapView: MKMapView!
    let LocationManager = CLLocationManager()
    
    @IBOutlet weak var addChild: UIButton!
    
    @IBAction func AddChildPressed(_ sender: UIButton) {
        if !IsLoggedIn(){
            performSegue(withIdentifier: "showSignIn", sender: sender)
            print("please log in")
        }
        else {
            LocationManager.requestAlwaysAuthorization()
            print("you are logged in")
        }
    }
    
    private func IsLoggedIn() -> Bool {
        
        if Auth.auth().currentUser?.uid == nil {
            return false
        }
        else {
            return true
        }
    }
    
    func configureMapView(){
        mapView.addSubview(addChild)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
    }
    
    
}
extension TrackingViewController : CLLocationManagerDelegate {
    func handleLocationServices(){
        guard CLLocationManager.locationServicesEnabled() else {
            print("location services disabled")
            return
        }
        LocationManager.delegate = self
        LocationManager.requestWhenInUseAuthorization()
        LocationManager.requestAlwaysAuthorization()
        if LocationManager.authorizationStatus == .authorizedAlways{
            LocationManager.startUpdatingLocation()
            LocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("hhhhhhhhhhhhhhhhh already authed")
        }
        else{
            
            print("auth requested")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .notDetermined:
            
            LocationManager.requestWhenInUseAuthorization()
        case .restricted , .denied:
            break
        case .authorizedAlways:
            LocationManager.startUpdatingLocation()
            LocationManager.desiredAccuracy = kCLLocationAccuracyBest
            
        case .authorizedWhenInUse:
            LocationManager.requestAlwaysAuthorization()
        @unknown default:
            LocationManager.requestWhenInUseAuthorization()
        }
    }
}


