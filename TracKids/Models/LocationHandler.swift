//
//  LocationHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/8/21.
//
import MapKit
import CoreLocation
import Firebase
import GeoFire

struct Location{
    let title : String
    let details : String
    let coordinates : CLLocationCoordinate2D
}


class LocationHandler : NSObject,CLLocationManagerDelegate{
    static let shared = LocationHandler()
    var locationManager : CLLocationManager?
    var location : CLLocation?
    var places = [Location]()
    var currentCoordinate: CLLocationCoordinate2D?
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
            print("not determined")
            break
        case .restricted , .denied:
            print("restricted")
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            print("always auth")
            
        case .authorizedWhenInUse:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            print("default")
            break
        }
    }
    var count : Int = 0
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geofire = GeoFire(firebaseRef: ChildLocationReference)
        guard let lastLocation = locations.last else {return}
        currentCoordinate = lastLocation.coordinate
        ChildLocationReference.observe(.value) { (snapshot) in
            guard   let UId =  Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchUserInfo() { (user) in
                let currentUser = user
                if  currentUser.accountType == 1 {
                    geofire.setLocation(lastLocation, forKey: UId) { (error) in
                    if error != nil {print(error!.localizedDescription )}
                        self.count += 1
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error.localizedDescription)
    }
    
    func locationManager(
      _ manager: CLLocationManager,
      monitoringDidFailFor region: CLRegion?,
      withError error: Error
    ) {
      guard let region = region else {
        print("Monitoring failed for unknown region")
        return
      }
      print("Monitoring failed for region with identifier: \(region.identifier)")
    }

    
    var geofences = [CLCircularRegion]()
    func configureGeofencing(for location : CLLocation) {
            var identifier : String = " "
             DataHandler.shared.convertLocationToAdress(for: location) { (place) in
                identifier = "\(place?.title ?? "monitord place")"
                print("Deebug: identifier into  \(identifier)")
                var fenceRegion: CLCircularRegion {
                    let region = CLCircularRegion(
                        center: location.coordinate,
                        radius: 1000,
                        identifier: identifier)
                    
                    region.notifyOnEntry =  true
                    region.notifyOnExit = true
                    return region
                   }
                self.geofences.append(fenceRegion)
                if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                    print("Debug: geofencing not supportted in this device")
                    return
                 }
                self.locationManager?.startMonitoring(for: fenceRegion)
                print("geofencing enabled in this device")
                print("Deebug: identifier after  \(identifier)")

            }
    }
    
    
    func StartObservingPlaces(){
        DataHandler.shared.fetchUserInfo { (user) in
            if user.accountType == 1{
                 let currentUser = user.uid
                DataHandler.shared.fetchObservedPlaces(for: currentUser) { (locations) in
                    guard let locations = locations else {return}
                    for location in locations{
                        self.configureGeofencing(for: location)
                        print("geofencing started")
                            }
                    for fenceRegion in self.geofences{
                        self.locationManager?.startMonitoring(for: fenceRegion)
                        print("ooo \(String(describing: self.locationManager?.monitoredRegions.first?.identifier))")
                                    }
                                }
                        }
                  }
            }

 
    func searchForLocation (with query : String , completion : @escaping(([Location]) -> Void)){
        self.places = []

        let request = MKLocalSearch.Request()
        let region = MKCoordinateRegion(center: currentCoordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        request.region = region
        request.naturalLanguageQuery = query
       
        let search = MKLocalSearch(request: request)
        search.start { [self] (response, error) in
            guard let response = response else { return }
            response.mapItems.forEach { (item) in

                let coordinates = item.placemark.location?.coordinate
                let name = item.placemark.name
                let details = item.placemark.title

                let place = Location(title: name ?? "", details: details ?? "", coordinates: coordinates ?? CLLocationCoordinate2D())

                self.places.append(place)
                completion(places)
          }
        }
    }
 }
