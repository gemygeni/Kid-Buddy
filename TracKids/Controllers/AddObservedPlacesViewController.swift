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
        var addressTitle : String?
        var searchResults : [MKPlacemark] = []
        override func viewDidLoad() {
            super.viewDidLoad()
            configureMapView()
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
            // centering Map On User Location
            guard let coordinate = self.LocationManager?.location?.coordinate else { return }
            let region = MKCoordinateRegion(center: coordinate,
                                            latitudinalMeters: 2000,
                                            longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
                   let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                   mapView.addGestureRecognizer(tapGesture)
             }
        
      @objc func handleTap(gestureReconizer: UITapGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
                let location = gestureReconizer.location(in: mapView)
                let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
                // Add annotation:
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
        let ObservedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
          
              self.ObservedLocation = ObservedLocation
            mapView.addAnnotation(annotation)
        addRadiusOverlay(for: ObservedLocation)
          LocationHandler.shared.convertLocationToAdress(for: ObservedLocation) { [weak self] address in
              
    self?.addressTitle = address?.title.components(separatedBy: ",").dropLast(2).joined(separator: " ")
              print("Debug : addressTitle  \(String(describing: self?.addressTitle))")
          }
      }

    func searchViewController(_ VC: SearchViewController, didSelectLocationWith coordinates: CLLocationCoordinate2D?, title: String) {
        guard let coordinates = coordinates else {return}
        self.addressTitle  = title
        let ObservedLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        self.ObservedLocation = ObservedLocation
        self.observedPlaces.append(coordinates)
        mapView.removeAnnotations(mapView.annotations)
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        mapView.addAnnotation(pin)
        mapView.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
        panel.move(to: .tip, animated: true)
        mapView.removeOverlays(mapView.overlays)
        addRadiusOverlay(for: ObservedLocation)
    }
        
    
    func didBeginsearching(_ VC: SearchViewController) {
        self.panel.move(to: .full, animated: true)
    }

        func uploadObservedPlaceData(){
            if let trackedChildId = TrackingViewController.trackedChildUId{
                let addressTitle = self.addressTitle ?? "cool"
                //String(describing: self.ObservedLocation.altitude)
                DataHandler.shared.uploadObservedPlace(ObservedLocation, addressTitle: addressTitle, for: trackedChildId)
                self.dismiss(animated: true, completion: nil)
                print("Debug: uploaded place successfully")
            }
        }
    
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
          if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
          }
          return MKOverlayRenderer(overlay: overlay)
        }
        
        func addRadiusOverlay(for Location: CLLocation) {
            mapView.removeOverlays(mapView.overlays)
           mapView.addOverlay(MKCircle(center: Location.coordinate, radius: 200))
        }
    }

