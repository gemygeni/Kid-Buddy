//
//  ChildsListTableViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit
import Firebase

class ChildsListTableViewController: UITableViewController {
   
    
    var Childs = [Child]()
    @IBAction func AddChildPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "AddChildSegue", sender: self)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchChildInfo()
       //navigationItem.leftBarButtonItem?.tintColor = UIColor.black
    }
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
//        self.tableView.reloadData()
//    }
    
     func fetchChildInfo(){
         guard let UId = Auth.auth().currentUser?.uid else {return}
         DataHandler.shared.fetchChildInfo(UId: UId) { (child) in
             self.Childs.append(child)
             DispatchQueue.main.async {
                 self.tableView.reloadData()
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
        // #warning Incomplete implementation, return the number of rows
        return Childs.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        if let cell =  cell as? ChildsListTableViewCell {
            
             //Configure the cell...
            let child = Childs[indexPath.row]
            cell.textLabel?.text = child.ChildName
            cell.detailTextLabel?.text = child.ChildPhoneNumber
            
            if let childImageURl = child.ImageURL {
                cell.profileImageView.loadImageUsingCacheWithUrlString(childImageURl)
            }
//
//            if let imageURL = child.ImageURL{
//              if  let url = URL(string: imageURL){
//        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
//            if error != nil {print(error?.localizedDescription) }
//                    guard let imageData = data else{ return}
//            DispatchQueue.main.async {
//                cell.profileImageView.image = UIImage(data: imageData)
//                    }
//                }
//                task.resume()
//              }
//            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowChildProfileSegue", sender: self)
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
        if  segue.identifier == "ShowChildProfileSegue"{
            if let childProfileVC = segue.destination.contents as? ChildProfileViewController{
                if let indexPath = tableView.indexPathForSelectedRow , let cell = tableView.cellForRow(at: indexPath) as? ChildsListTableViewCell  {
                    print(cell.textLabel?.text)
                    childProfileVC.name = cell.textLabel?.text
                    childProfileVC.phone = cell.detailTextLabel?.text
                    childProfileVC.fetchedImage = cell.profileImageView.image
                }
            }
        }
    }
  

}





