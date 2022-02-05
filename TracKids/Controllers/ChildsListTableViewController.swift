//
//  ChildsListTableViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit
import Firebase

class ChildsListTableViewController: UITableViewController {
    
    var childs = [User]()
    var childsID = [String]()
    @IBAction func AddChildPressed(_ sender: UIBarButtonItem) {
       performSegue(withIdentifier: "AddChildPopoverSegue", sender: self)
               }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchChildsInfo()
       navigationItem.title = "Childs List"

    }
    
     func fetchChildsInfo(){
         childs = []
         childsID = []
         guard let uid = Auth.auth().currentUser?.uid else {return}
         DataHandler.shared.fetchChildsInfo(for: uid) { [weak self] child, childID in
             self?.childs.append(child)
             self?.childsID.append(childID)
              DispatchQueue.main.async {
                  self?.tableView.reloadData()
                  if (self?.childs.count)! > 1 {
                      let indexPath = IndexPath(row: (self?.childs.count)! - 1, section: 0)
                 self?.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                 }
              }
         }
     }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    // MARK: - Table view data source
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return childs.count
    }

    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if let childCell =  cell as? ChildsListTableViewCell {
            let child = childs[indexPath.row]
            childCell.textLabel?.text = child.name
            childCell.detailTextLabel?.text = child.phoneNumber
            if let childImageURl = child.imageURL {
                childCell.profileImageView.loadImageUsingCacheWithUrlString(childImageURl)
            }
         }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowChildProfileSegue", sender: self)
    }
  
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
  

   
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let childId = childsID[indexPath.row]
            guard let parentId = Auth.auth().currentUser?.uid else {return}
            DataHandler.shared.removeChild(of: parentId, withId: childId )
            childs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if  segue.identifier == "ShowChildProfileSegue"{
            if let childProfileVC = segue.destination.contents as? ChildProfileViewController{
                if let indexPath = tableView.indexPathForSelectedRow , let cell = tableView.cellForRow(at: indexPath) as? ChildsListTableViewCell  {
                    childProfileVC.childAccount = childs[indexPath.row]
                    childProfileVC.fetchedImage = cell.profileImageView.image
                    TrackingViewController.trackedChildUId = childsID[indexPath.row]
                }
            }
        }
    }
}

