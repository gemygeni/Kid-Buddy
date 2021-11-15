//
//  ObsevedPlacesTableViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/1/21.
//

import UIKit
import CoreLocation

class ObservedPlacesTableViewController: UITableViewController {
    var Addresses = [Location?]()
    var fetchedLocations = [CLLocation?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchObservedPlaces()
       
        
        
    }
    
    func fetchObservedPlaces(){

        Addresses = []
        print("wwwwwwwwR")
        if let trackedChildId = TrackingViewController.trackedChildUId{
            print("ffff \(trackedChildId)")
            DataHandler.shared.fetchObservedPlaces(for: trackedChildId) {[weak self] (locations) in
                guard let locations = locations else{return}
                print("zzz \(locations.count)")
               // self.fetchedLocations = locations
                print("xxx \(locations.count)")
                for location in locations{
                    self?.convertLocationToAdress(for: location) { (address) in

                        if   !(self?.Addresses.contains(where: { (address2) -> Bool in
                            if address2?.coordinates.latitude == address?.coordinates.latitude && address2?.coordinates.longitude == address?.coordinates.longitude {
                                return true
                            }
                            return false
                        }))!{

                            self?.Addresses.append(address)

                           }
                        print("vvvv \(String(describing: self?.Addresses.count))")
                        
                        DispatchQueue.main.async {
                                           print("qqqqqqqqqqqq")
                            self?.tableView.reloadData()
                          }
                        }
                     }
                  }
               }
             }
    
    
    
//    //compact
//    func fetchObservedPlaces(){
//        Addresses = []
//        if let trackedChildId = TrackingViewController.trackedChildUId{
//            DataHandler.shared.fetchObservedPlaces(for: trackedChildId) { (locations) in
//                guard let locations = locations else{return}
//                print("xxx \(String(describing: locations.last))")
//
//                self.Addresses = locations.compactMap({ (location)  in
//              let place =   self.convertLocationToAdress(for: location)
//
//                    print("xxx \(String(describing: place))")
//
//                    return place
//                })
//                print("ttt \(String(describing: self.Addresses))")
//                DispatchQueue.main.async {
//                    print("qqqqqqqqqqqq")
//                self.tableView.reloadData()
//
//                   }
//               }
//          }
//      }
    
    
    func convertLocationToAdress(for location : CLLocation?, completion : @escaping((Location?) -> Void)) {
        let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location!) { (placeMarks, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let placemarks = placeMarks , error == nil else {completion(nil)
                 return}

                let placeData = placemarks[0]
                    var name = ""
                    if let streetDetails = placeData.subThoroughfare{
                        name += streetDetails
                    }
                    if let street = placeData.thoroughfare{
                        name += " \(street)"
                    }
                    if let locality = placeData.locality{
                        name += ", \(locality)"
                    }

                    if let adminRegion = placeData.administrativeArea {
                        name += ", \(adminRegion)"
                    }

                    if let country = placeData.country{
                        name += ", \(country)"
                    }
            let place = Location(title: name, details: "", coordinates: placeData.location?.coordinate ?? CLLocationCoordinate2D())
                completion(place)
            }
    }

//
    
//    //compact
//    func convertLocationToAdress(for location : CLLocation?) -> Location? {
//        let geocoder = CLGeocoder()
//        var address : Location?
//            geocoder.reverseGeocodeLocation(location!) { (placeMarks, error) in
//                if error != nil {print(error!.localizedDescription) }
//                guard let placemarks = placeMarks , error == nil else {
//                 return}
//
//                let placeData = placemarks[0]
//                    var name = ""
//                    if let streetDetails = placeData.subThoroughfare{
//                        name += streetDetails
//                    }
//                    if let street = placeData.thoroughfare{
//                        name += " \(street)"
//                    }
//                    if let locality = placeData.locality{
//                        name += ", \(locality)"
//                    }
//
//                    if let adminRegion = placeData.administrativeArea {
//                        name += ", \(adminRegion)"
//                    }
//
//                    if let country = placeData.country{
//                        name += ", \(country)"
//                    }
//            let place = Location(title: name, details: "", coordinates: placeData.location?.coordinate ?? CLLocationCoordinate2D())
//            address = place
//            }
//        return address
//    }
    
    
    
    
    @IBAction func AddPlacesButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "AddPlacesSegue", sender: self)
    }
    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Addresses.count
          
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
 // var r = [1,2,3,4,5,6,7]
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "observedPlaceCell", for: indexPath)
      //  DispatchQueue.main.async {
        cell.textLabel?.text = (self.Addresses[indexPath.row]?.title ?? "No address for this Location") + " " + (self.Addresses[indexPath.row]?.details ?? "")
      //  cell.textLabel?.text = String(r[indexPath.row])
            cell.textLabel?.numberOfLines = 0
            cell.contentView.backgroundColor = .secondarySystemBackground
            cell.backgroundColor = .secondarySystemBackground
      //  }
        return cell
    }
   

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    
    
  
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}
