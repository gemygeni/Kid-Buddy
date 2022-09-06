//
//  SearchingViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 11/6/21.
//

import UIKit
import MapKit
import CoreLocation
protocol SearchViewControllerDelegate : AnyObject  {
    func searchViewController(_ VC : SearchViewController , didSelectLocationWith coordinates : CLLocationCoordinate2D?, title : String)
    func didBeginsearching(_ VC : SearchViewController)

}

class SearchViewController: UIViewController {
    weak var delegate : SearchViewControllerDelegate?
    var places = [Location]()
    var completionResults = [MKLocalSearchCompletion]()
    private let completer = MKLocalSearchCompleter()
    let label : UILabel = {
       let label = UILabel()
        label.text = "Swipe up to Search For Place ⬆️"
        label.font = .systemFont(ofSize: 20, weight: .regular)
       return label
    }()
    
    
    private var searchTextField : UITextField = {
        let searchTextField = UITextField()
        searchTextField.layer.cornerRadius = 9
        searchTextField.placeholder = "Search For Loacation"
        searchTextField.isUserInteractionEnabled = true
        
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
        searchTextField.addTarget(
          self,
          action: #selector(textFieldDidChange(_:)),
          for: .editingChanged
        )
        completer.delegate = self
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
    
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        self.places = []
        print("sss textFieldDidChange")
        guard let query = textField.text else {

        if completer.isSearching {
           completer.cancel()
        }
        return
      }
        guard let location =  LocationHandler.shared.locationManager?.location else{return}
            let Delta: CLLocationDegrees = 25 / 111
            let span = MKCoordinateSpan(
              latitudeDelta: Delta,
              longitudeDelta: Delta)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            completer.region = region
            completer.queryFragment = query

            self.completionResults.forEach { (place) in
                
                LocationHandler.shared.searchForLocation(with: place.title) {[weak self] (places) in
                    DispatchQueue.main.async {
                        self?.places = places
                        self?.tableView.reloadData()
                    }
                }
           }
      }
  }

// MARK: - UITextFieldDelegate
extension SearchViewController : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchTextField.text = ""
        self.places = []
        self.tableView.reloadData()
            if completer.isSearching {
              completer.cancel()
                return
            }
        searchTextField = textField
        
           }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.delegate?.didBeginsearching(self)
        self.tableView.reloadData()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.places = []
        if let query = searchTextField.text , !searchTextField.text!.isEmpty{
            LocationHandler.shared.searchForLocation(with: query) {[weak self] (places) in
                DispatchQueue.main.async {
                    self?.places = places
                    self?.tableView.reloadData()
                }
            }
        }
        return true
     }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
     //   self.places = []
        self.tableView.reloadData()
        print("rrr textFieldDidEndEditing")
    }
    
  }


extension SearchViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        cell.textLabel?.text = places[indexPath.row].title + " \n" + places[indexPath.row].details
        cell.textLabel?.numberOfLines = 0
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("ggg beefore \(self.places.count)")
        let coordinates = places[indexPath.row].coordinates
        let title = places[indexPath.row].title
        self.delegate?.searchViewController(self, didSelectLocationWith: coordinates, title: title)
   }
}

extension SearchViewController : MKLocalSearchCompleterDelegate{
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.places = []
            let Results = completer.results
            self?.completionResults = Results
            self?.tableView.reloadData()
            print("sss completerDidUpdateResults")
         }
      }

      func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
      ) {
        print("Error suggesting a location: \(error.localizedDescription)")
      }
}
