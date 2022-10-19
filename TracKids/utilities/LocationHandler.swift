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
        var locationHistory = [CLLocation]()
        var places = [Location]()
        var geofences = [CLCircularRegion]()
        var count1 = 0
        override init() {
            super.init()
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.allowsBackgroundLocationUpdates = true
            locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager?.distanceFilter = CLLocationDistance(200)
        }
        // MARK: - locationManager delegate Methods.
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
                DataHandler.shared.fetchUserInfo { [weak self](user) in
                    if user.accountType == 1 {
                        self?.locationManager?.startUpdatingLocation()
                        self?.locationManager?.startMonitoringSignificantLocationChanges()
                        self?.locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
                        print("always auth")
                    }
                }
            case .authorizedWhenInUse:
                locationManager?.startUpdatingLocation()
                locationManager?.startMonitoringSignificantLocationChanges()
                locationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
                locationManager?.requestAlwaysAuthorization()
            @unknown default:
                print("default")
                break
            }
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let lastLocation = locations.first else {return}
            self.uploadChildLocation(for: lastLocation)
            self.uploadLocationHistory(for: lastLocation)
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            
            print("Debug: error \(String(describing: error.localizedDescription))")
        }
        
        func locationManager(
            _ manager: CLLocationManager,
            monitoringDidFailFor region: CLRegion?,
            withError error: Error
        ) {
            guard let region = region else {
                print("Debug: Monitoring failed for unknown region")
                return
            }
            print("Debug: Monitoring failed for region with identifier: \(region.identifier)")
        }
        
        
        
        // MARK: - function to upload Location History to realtime database.
        func uploadLocationHistory(for location : CLLocation){
            count1 += 1
            DataHandler.shared.fetchUserInfo { [weak self] user in
                guard let parentID = user.parentID else {return}
                let UId = user.uid
                let timestamp = String(Int(Date().timeIntervalSince1970))
                let historyReference = HistoryReference.child( parentID).child(UId)
                if self?.count1 == 1 {
                    historyReference.observe(.childAdded) { snapshot in
                        let locationTime = snapshot.key
                        if Int(timestamp)! - (24*60*60) >  Int(locationTime)! {
                            historyReference.child(locationTime).removeValue()
                        }
                    }
                }
                let geoFire = GeoFire(firebaseRef: historyReference)
                let key = HistoryReference.childByAutoId().child(timestamp).key
                geoFire.setLocation(location, forKey: key ?? "locationkey")
            }
        }
        
        // MARK: - function to remove Location History from realtime database.
        func clearHistory (completion : @escaping () -> Void){
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard let trackedChildID = TrackingViewController.trackedChildUId else {return}
            let historyReference = HistoryReference.child( uid).child(trackedChildID)
            historyReference.removeValue { error, reference in
                if  error != nil {
                    print(print("Debug: error \(String(describing: error!.localizedDescription))")
)
                }
                else{
                    completion()
                }
            }
        }
        
        // MARK: - function to upload Child Location to realtime database.
        func uploadChildLocation(for location : CLLocation)  {
            DataHandler.shared.fetchUserInfo { user in
                guard let parentID = user.parentID else{return}
                let geofire = GeoFire(firebaseRef: ChildLocationReference.child(parentID))
                let UId = user.uid
                geofire.setLocation(location, forKey: UId) { (error) in
                    if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                }
            }
        }
        
        
        // MARK: - function to configure Geofencing to specific location to get notified about.
        func configureGeofencing(for location : CLLocation) {
            var identifier : String = " "
            LocationHandler.shared.convertLocationToAddress(for: location) {[weak self] (place) in
                identifier = "\(place?.title.components(separatedBy: ",").dropLast(2).joined(separator: " ") ?? "monitored place")"
                var fenceRegion: CLCircularRegion {
                    let region = CLCircularRegion(
                        center: location.coordinate,
                        radius: 500,
                        identifier: identifier)
                    region.notifyOnEntry =  true
                    region.notifyOnExit = true
                    return region
                    }
                self?.geofences.append(fenceRegion)
                if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                    print("Debug: geofencing not supportted in this device")
                    return
                  }
                self?.locationManager?.startMonitoring(for: fenceRegion)
                print("Debug: identifier after  \(identifier)")
            }
        }
        
        // MARK: - function to fetch observed location from database and get notified when reach or leave it.
        func StartObservingPlaces(){
            guard let monitoredRegions = LocationHandler.shared.locationManager else{return}
            for region in monitoredRegions.monitoredRegions{
                monitoredRegions.stopMonitoring(for: region)
               }
            DataHandler.shared.fetchUserInfo { [weak self] user in
                if user.accountType == 1{
                    let childId = user.uid
                    let parentId = user.parentID
                    DataHandler.shared.fetchObservedPlaces(for: childId, of: parentId!) {[weak self] locations, _ in
                        print("Debug: geofencing user \(String(describing: locations?.first))")
                        guard let locations = locations else {return}
                        for location in locations{
                            self?.configureGeofencing(for: location)
                            print("Debug: geofencing started")
                           }
                        for fenceRegion in self!.geofences{
                            self?.locationManager?.startMonitoring(for: fenceRegion)
                            print("geofencing \(String(describing: self?.locationManager?.monitoredRegions.first?.identifier))")
                        }
                    }
                }
            }
        }
      
        
        // MARK: - function to search for address to be observed.
        func searchForLocation (with query : String , completion : @escaping(([Location]) -> Void)){
            self.places = []
            let request = MKLocalSearch.Request()
            let region = MKCoordinateRegion(center: locationManager?.location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            request.region = region
            request.naturalLanguageQuery = query
            let search = MKLocalSearch(request: request)
            search.start { [weak self] (response, error) in
                guard let response = response else { return }
                response.mapItems.forEach { (item) in
                    let coordinates = item.placemark.location?.coordinate
                    let name = item.placemark.name
                    let details = item.placemark.title
                    let place = Location(title: name ?? "", details: details ?? "", coordinates: coordinates ?? CLLocationCoordinate2D())
                    self?.places.append(place)
                    completion(self!.places)
                }
            }
        }
        
        // MARK: - function to convert observed location to readable address.
        func convertLocationToAddress(for location : CLLocation?, completion : @escaping((Location?) -> Void)) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location!) { (placeMarks, error) in
                if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                guard let placemarks = placeMarks , error == nil
                else {completion(nil)
                    return}
                
                let placeData = placemarks[0]
                var name = ""
                
                if let streetDetails = placeData.subThoroughfare{
                    name += "\(streetDetails), "
                }
                
                if let street = placeData.thoroughfare{
                    name += "\(street), "
                }
                
                if let LocalDetails = placeData.subLocality {
                    name += "\(LocalDetails), "
                }
                
                if let locality = placeData.locality{
                    name += "\(locality), "
                }
                
                let place = Location(title: name, details: "", coordinates: placeData.location?.coordinate ?? CLLocationCoordinate2D())
                completion(place)
            }
        }
    }
 
