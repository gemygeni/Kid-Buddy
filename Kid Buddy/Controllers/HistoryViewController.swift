//
//  HistoryViewController.swift
//  Kid Buddy
//
//  Created by AHMED GAMAL  on 11/22/21.
//

import UIKit
import MapKit
import Firebase
import GeoFire
class HistoryViewController: UIViewController {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    var annotations = [ChildAnnotation]()
    var historyPoints = [CLLocationCoordinate2D]()
    var count = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        configureMapView()
    }
    @IBAction func clearHistoryPressed(_ sender: Any) {
        print("Debug: clear history pressed")
        clearHistory()
    }
    @IBAction func changeMapTypeButtonPressed(_ sender: Any) {
        if mapView.mapType == .standard {
            mapView.mapType = .hybrid
        } else if mapView.mapType == .hybrid {
            mapView.mapType = .standard
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if Auth.auth().currentUser?.uid == nil {
            historyPoints = []
            annotations = []
            mapView.removeAnnotations(mapView.annotations)
        }
        fetchLocationHistory()
        guard let childId = TrackingViewController.trackedChildUId else {return}
        DataHandler.shared.fetchChildAccount(with: childId) {[weak self] user in
            self?.tabBarItem.title = user.name + " History"
            self?.navigationItem.title = user.name
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.tabBarItem.title = "History"
    }

    // MARK: - function to configure map view.
    func configureMapView() {
        mapView.delegate = self
        self.mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
    }
    // MARK: - function to fetch Location History from database.
    func fetchLocationHistory() {
        spinner.startAnimating()
        self.historyPoints = []
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
        guard let childId = TrackingViewController.trackedChildUId else {
            self.spinner.stopAnimating()
            return}
        guard let parentID = Auth.auth().currentUser?.uid else {return}
        let geofire = GeoFire(firebaseRef: historyReference.child(parentID).child(childId))
        historyReference.child(parentID).child(childId).observe(.childAdded) {[weak self] snapshot in
            let key = snapshot.key
            geofire.getLocationForKey(key) { [weak self] location, _ in
                guard let fetchedLocation = location else {return}
                let annotation = ChildAnnotation(uid: childId, coordinate: fetchedLocation.coordinate)
                self?.mapView.addAnnotation(annotation)
                let timeBySeconds = Double(key)
                let date = Date(timeIntervalSince1970: timeBySeconds ?? 0.00)
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone.current
                formatter.dateFormat = "E HH:mm a"
                let timestamp = formatter.string(from: date)
                annotation.title = timestamp
                LocationHandler.shared.convertLocationToAddress(for: location) { place in
                    annotation.subtitle = place?.title
                }
                let point = fetchedLocation.coordinate
                self?.historyPoints.append(point)
                self?.drawOverlay(with: self!.historyPoints)
            }
        }
        self.spinner.stopAnimating()
    }

    // MARK: - function to draw overlay on the map with points of location history.
    func drawOverlay(with points: [CLLocationCoordinate2D] ) {
        let historyPoints = self.historyPoints
        let polyline = MKPolyline(coordinates: historyPoints, count: historyPoints.count)
        mapView.addOverlay(polyline)
        var polylineRect = polyline.boundingMapRect
        polylineRect.size.width *= 1.1
        polylineRect.size.height *= 1.1
        self.mapView.setRegion(MKCoordinateRegion(polylineRect), animated: true)
    }

    // MARK: - function to remove location history from database.
    func clearHistory() {
        LocationHandler.shared.clearHistory {[weak self] in
            guard let coordinate = LocationHandler.shared.locationManager?.location?.coordinate else { return }
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000)
            self?.mapView.setRegion(region, animated: true)
            if  self?.mapView.overlays != nil {
                self?.mapView.removeOverlays((self?.mapView.overlays)!)
            }
            if  self?.mapView.annotations != nil {
                self?.mapView.removeAnnotations((self?.mapView.annotations)!)
            }
        }
    }
}

// MARK: - MKMapViewDelegate Methods.
extension HistoryViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "historyAnnotation") as? MKMarkerAnnotationView
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "historyAnnotation")
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .system)
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.glyphText = "⏰"
        annotationView?.markerTintColor = .orange
        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 0.07, green: 0.73, blue: 0.86, alpha: 1.0)
        renderer.lineWidth = 4.0
        renderer.lineWidth = 5.0
        return renderer
    }
}
