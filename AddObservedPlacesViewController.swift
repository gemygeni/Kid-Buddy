    //
    //  AddObservedPlacesViewController.swift
    //  TracKids
    //
    //  Created by AHMED GAMAL  on 11/1/21.
    //

    import UIKit
    import MapKit
    import Firebase
    import FloatingPanel

    class AddObservedPlacesViewController: UIViewController, MKMapViewDelegate, SearchViewControllerDelegate {
        let panel = FloatingPanelController()
        var observedPlaces = [CLLocationCoordinate2D]()
        var ObservedLocation = CLLocation()
        var searchResults : [MKPlacemark] = []
        
        override func viewDidLoad() {
            super.viewDidLoad()
            configureMapView()
            centerMapOnUserLocation()
            let searchVC = SearchViewController()
            searchVC.delegate = self
            panel.set(contentViewController: searchVC)
            panel.addPanel(toParent: self)
            panel.move(to: .tip , animated: false)
        }

    
        
        @IBOutlet weak var mapView: MKMapView!
        
        @IBAction func cancelButtonPressed(_ sender: UIButton) {
            self.dismiss(animated: true, completion: nil)
        }
        @IBAction func AddButtonPressed(_ sender: UIButton) {
            uploadObservedPlaceData()
        }
        
        @IBAction func changeMapTypeButtonPressed(_ sender: Any) {
            if mapView.mapType == .standard{
                mapView.mapType = .hybrid
            }
            else if mapView.mapType == .hybrid {
                mapView.mapType = .standard
            }
        }
        
        let LocationManager = LocationHandler.shared.locationManager
        
        
        
        func configureMapView(){
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            mapView.isZoomEnabled = true
        }
        
        func centerMapOnUserLocation() {
            guard let coordinate = self.LocationManager?.location?.coordinate else { return }
            let region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
        }
        
        func searchViewController(_ VC: SearchViewController, didSelectLocationWith coordinates: CLLocationCoordinate2D?) {
            guard let coordinates = coordinates else {return}
            let ObservedLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            self.ObservedLocation = ObservedLocation
            self.observedPlaces.append(coordinates)
            mapView.removeAnnotations(mapView.annotations)
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            mapView.addAnnotation(pin)
            mapView.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
            panel.move(to: .tip, animated: true)
        }
        
        
        func uploadObservedPlaceData(){
            if let trackedChildId = TrackingViewController.trackedChildUId{
                DataHandler.shared.uploadObservedPlace(ObservedLocation, for: trackedChildId)
                self.dismiss(animated: true, completion: nil)
                print("uploaded place successfully")
            }
        }
        
    }

