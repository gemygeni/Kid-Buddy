//
//  SearchingViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/6/21.
//

import UIKit
import CoreLocation
protocol SearchViewControllerDelegate : AnyObject  {
    func searchViewController(_ VC : SearchViewController , didSelectLocationWith coordinates : CLLocationCoordinate2D?)
   
}

class SearchViewController: UIViewController {
    weak var delegate : SearchViewControllerDelegate?
    var locations = [Location]()
    let label : UILabel = {
       let label = UILabel()
        label.text = "Search For Loacation"
        label.font = .systemFont(ofSize: 24, weight: .semibold)
       return label
    }()
    
    
    let searchTextField : UITextField = {
        let searchTextField = UITextField()
        searchTextField.layer.cornerRadius = 9
        searchTextField.placeholder = "Search For Loacation"
        searchTextField.backgroundColor = .tertiarySystemBackground
        searchTextField.leftView = UIView(frame: CGRect(x: 10, y: 10, width: 10, height: 50))
        searchTextField.leftViewMode = .always
        searchTextField.returnKeyType = .search
        return searchTextField
    }()
    
    let tableView : UITableView = {
       let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(label)
        view.addSubview(searchTextField)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .secondarySystemBackground
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        label.sizeToFit()
        label.frame = CGRect(x: 10, y: 10, width: label.frame.size.width, height: label.frame.size.height)
        searchTextField.frame = CGRect(x: 10 , y: 20 + label.frame.size.height, width: view.frame.size.width-20, height: 50)
        let tableY = searchTextField.frame.origin.y + searchTextField.frame.size.height+5
        tableView.frame = CGRect(x: 0, y:  tableY  , width: view.frame.size.width, height: view.frame.size.height - tableY)
    }
}

extension SearchViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchTextField.text = ""
        self.locations = []
        self.tableView.reloadData()
           }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.locations = []
        searchTextField.resignFirstResponder()
        if let query = searchTextField.text , !searchTextField.text!.isEmpty{
            LocationHandler.shared.searchForLocation(with: query) {[weak self] (locations) in
                DispatchQueue.main.async {
                    self?.locations = locations
                    self?.tableView.reloadData()
                }
            }
        }
        return true
    }
}


extension SearchViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        cell.textLabel?.text = locations[indexPath.row].title + " \n" + locations[indexPath.row].details
        cell.textLabel?.numberOfLines = 0
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let coordinates = locations[indexPath.row].coordinates
        self.delegate?.searchViewController(self, didSelectLocationWith: coordinates)
   }
}
