//
//  SearchingViewController.swift
//  Kid Buddy
//
//  Created by AHMED GAMAL  on 11/6/21.
//

import UIKit
import MapKit
import CoreLocation
// MARK: - SearchViewControllerDelegate Methods
protocol SearchViewControllerDelegate: AnyObject {
    // MARK: delegate function trigerred when a location row been selected.
    func searchViewController(_ VC: SearchViewController, didSelectLocationWith coordinates: CLLocationCoordinate2D?, title: String)
    // MARK: delegate function trigerred when searching begin.
    func didBeginSearching(_ VC: SearchViewController)
}

class SearchViewController: UIViewController {
    weak var delegate: SearchViewControllerDelegate?
    var places: [Location] = []
    var searchResults: [MKLocalSearchCompletion] = []

    private let searchCompleter = MKLocalSearchCompleter()
    let label: UILabel = {
        let label = UILabel()
        label.text = "Tap on the Map or Swipe up ⬆️ to Search"
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()

    private var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.layer.cornerRadius = 9
        searchBar.placeholder = "Search For Loacation"
        searchBar.isUserInteractionEnabled = true
        searchBar.backgroundColor = .tertiarySystemBackground
        searchBar.textContentType = .location
        searchBar.returnKeyType = .search
        return searchBar
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .secondarySystemBackground
        searchCompleter.delegate = self
        view.backgroundColor = .secondarySystemBackground
        view.addSubview(label)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        self.places = []
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        label.sizeToFit()
        label.frame = CGRect(x: 10, y: 10, width: label.frame.size.width, height: label.frame.size.height)
        searchBar.frame = CGRect(x: 10, y: 20 + label.frame.size.height, width: view.frame.size.width - 20, height: 50)
        let tableY = searchBar.frame.origin.y + searchBar.frame.size.height + 5
        tableView.frame = CGRect(x: 0, y: tableY, width: view.frame.size.width, height: view.frame.size.height - tableY)
    }
}

// MARK: - TableView Delegate Methods.
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, _ in
            let coordinates = response?.mapItems[0].placemark.coordinate
            let title = completion.title
            self.delegate?.searchViewController(self, didSelectLocationWith: coordinates, title: title )
            print(String(describing: coordinates))
        }
    }
}

// MARK: - UISearchBarDelegate Methods.
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchCompleter.queryFragment = searchText
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        ((self.delegate?.didBeginSearching(self)) != nil)
    }
}

// MARK: - MKLocalSearchCompleterDelegate Methods.
extension SearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
        print("Debug: completerDidUpdateResults")
    }
    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        print("Debug: Error suggesting a location: \(error.localizedDescription)")
    }
}
