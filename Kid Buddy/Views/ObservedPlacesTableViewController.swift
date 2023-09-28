//
//  ObsevedPlacesTableViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/1/21.
//

import UIKit
import CoreLocation
import Firebase

class ObservedPlacesTableViewController: UITableViewController {
    
    var Addresses = [Location?]()
    var placesIds = [String]()
    @IBAction func AddPlacesButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "AddPlacesSegue", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchObservedPlaces()
    }
    
    // MARK: - function to fetch observed laocations from database and convert it to places.
    func fetchObservedPlaces(){
        Addresses = []
        placesIds  = []
        if let trackedChildId = TrackingViewController.trackedChildUId{
            guard let parentId = Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.fetchObservedPlaces(for: trackedChildId, of: parentId) { [weak self] locations, placesKeys in
                guard let locations = locations else{return}
                self?.placesIds = placesKeys
                print("Debug:- \(String(describing: self?.placesIds))")
                
                for location in locations{
                    //convert fetched locations to addresses to display in tableview
                    LocationHandler.shared.convertLocationToAddress(for: location) { address in
                        if   !((self?.Addresses.contains(where: { (address2) -> Bool in
                            if address2?.coordinates.latitude == address?.coordinates.latitude && address2?.coordinates.longitude == address?.coordinates.longitude {
                                return true
                            }
                            return false
                        })) ?? false){
                            
                            self?.Addresses.append(address)
                        }
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
        }
        //limit number of places to 20 only.
        navigationItem.rightBarButtonItem?.isEnabled = Addresses.count < 20
    }
    
    
    // MARK: - Table view data source delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Addresses.count
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "observedPlaceCell", for: indexPath)
        cell.textLabel?.text = self.placesIds[indexPath.row] + " \n" + (self.Addresses[indexPath.row]?.title ?? "No address for this Location") + " " + (self.Addresses[indexPath.row]?.details ?? "")
        cell.textLabel?.numberOfLines = 0
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let uid = Auth.auth().currentUser?.uid else {return}
            guard let childId = TrackingViewController.trackedChildUId else {return}
            let placeId = placesIds[indexPath.row]
            let placeReference = ObservedPlacesReference.child(uid).child(childId).child(placeId)
            placeReference.removeValue {[weak self] error, _ in
                self?.Addresses.remove(at: indexPath.row)
                self?.placesIds.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.reloadData()
            }
        }
    }
}
