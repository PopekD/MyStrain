//
//  ViewController.swift
//  MyStrain
//
//  Created by Nini on 22.8.2023.
//

import UIKit


class ViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {

        
    @IBOutlet weak var Search: UISearchBar!
    @IBOutlet weak var Results: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Search.delegate = self
        Results.backgroundColor = UIColor.clear
        Results.delegate = self
        Results.dataSource = self
        Results.isHidden = true;
    }
    
    var searchResults: [String:String] = [:]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let key = Array(searchResults.keys)[indexPath.row]
        cell.textLabel?.text = searchResults[key]
        cell.contentView.backgroundColor = UIColor.clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let videoUrls = Array(searchResults.keys)
        let selectedVideoUrl = videoUrls[indexPath.row]
        
        let musicPlayer = MusicPlayerVC(id: selectedVideoUrl)
        navigationController?.pushViewController(musicPlayer, animated: true)
    }


    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Results.isHidden = false
        API.shared.searchVideos(searchWord: searchBar.text ?? "") { result in
            switch result {
            case .success(let videoDictionary):
                self.searchResults = videoDictionary
            case .failure(let error):
                print("Error: \(error)")
            }
        }
        Results.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text?.isEmpty ?? true {
            Results.isHidden = true
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        Results.isHidden = true
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
    
}

