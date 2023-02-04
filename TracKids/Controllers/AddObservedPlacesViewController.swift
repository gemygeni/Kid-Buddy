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
    var addressTitle = ""
    var searchResults : [MKPlacemark] = []
    let LocationManager = LocationHandler.shared.locationManager
    
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
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - function to configure map and center on user location.
    func configureMapView(){
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
        // centering Map On User Location.
        guard let coordinate = self.LocationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        mapView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - function to handle tap on the map to assign location to observe.
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
        //convert location to address to display on observeed places.
        LocationHandler.shared.convertLocationToAddress(for: ObservedLocation) { [weak self] address in
            self?.addressTitle = (address?.title.components(separatedBy: ",").dropLast(2).joined(separator: " "))!
            print("Debug: addressTitle  \(String(describing: self?.addressTitle))")
        }
    }
    
    // MARK: - SearchViewControllerDelegate method triggered when select search result row.
    func searchViewController(_ VC: SearchViewController, didSelectLocationWith coordinates: CLLocationCoordinate2D?, title: String) {
        panel.move(to: .tip, animated: true)
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
        mapView.removeOverlays(mapView.overlays)
        addRadiusOverlay(for: ObservedLocation)
    }
    
    // MARK: - SearchViewControllerDelegate method triggered when search  begin to expand search panel.
    func didBeginSearching(_ VC: SearchViewController) {
        self.panel.move(to: .full, animated: true)
    }
    
    // MARK: - function to upload observed place to database .
    func uploadObservedPlaceData(){
        if let trackedChildId = TrackingViewController.trackedChildUId{
            if self.addressTitle.count > 1 {
                print("Debug: fetched is \( addressTitle) ")
                DataHandler.shared.uploadObservedPlace(ObservedLocation, addressTitle: self.addressTitle, for: trackedChildId)
            }else{
                DataHandler.shared.uploadObservedPlace(ObservedLocation, addressTitle: "no address", for: trackedChildId)
            }
            self.dismiss(animated: true, completion: nil)
            print("Debug: uploaded place successfully")
        }
    }

    // MARK: - MapView delegate Methods.
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
    // MARK: - function to add circular overlay on map with specific location.
    func addRadiusOverlay(for Location: CLLocation) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(MKCircle(center: Location.coordinate, radius: 200))
    }
}

