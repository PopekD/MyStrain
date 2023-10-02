//
//  ViewController.swift
//  MyStrain
//
//  Created by Nini on 22.8.2023.
//

import UIKit
import QuartzCore

class ViewController: UIViewController, UISearchBarDelegate,
                      UITableViewDelegate, UITableViewDataSource, MusicPlayerVCDelegate{
    
    func performSegueToChannel(videoArray: [VideoInfo], channelName: String, Url: URL?, playlistInfo: [PlayListInfo]) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChannelVC") as! ChannelVC
        vc.ChannelName = channelName
        if let imageURL = Url {
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {

                    DispatchQueue.main.async {
                        vc.ChannelThumbnail = image
                        vc.VideoArray = videoArray
                        vc.PlaylistInfo = playlistInfo
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }.resume()
        }
    }

    
    
    @IBOutlet weak var Search: UISearchBar!
    @IBOutlet weak var Results: UITableView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Search.delegate = self
        Results.delegate = self
        Results.backgroundColor = UIColor.clear
        Results.dataSource = self
        Results.allowsSelection = true
        MusicPlayerVC.homeDelegate = self
    }

    var searchSection = 0
    var searchResults = [VideoInfo]()
    var suggestedResults = [String]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchSection
        {
        case 0:
            return suggestedResults.count
            break
        case 1:
            return searchResults.count
            break
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        switch searchSection
        {
        case 0:
            let search = suggestedResults[indexPath.row]
            content.text = search
            content.image = UIImage(systemName: "magnifyingglass.circle")
            content.imageProperties.tintColor = UIColor.darkGray
            cell.backgroundColor = UIColor.clear
            cell.contentConfiguration = content
            break;
        case 1:
            let search = searchResults[indexPath.row]
            content.text = search.title
            cell.backgroundColor = UIColor.clear
            let urlString: URL?
            let width: Int?
            let height: Int?

            if search.videoId == "CHANNEL" {
                urlString = search.publishDate as! URL// publishDate = Channel Thumbnail I was too lazy to make another struct
                content.imageProperties.cornerRadius = 130
                content.textProperties.font = UIFont.systemFont(ofSize: 25, weight: UIFont.Weight.heavy)
                width = 130
                height = 130
            } else {
                urlString = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/hqdefault.jpg")
                width = 80
                height = 80
            }

            

            
            // Load the image asynchronously from the URL
            if let imageURL = urlString {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        // Set the image on the main queue
                        let targetSize = CGSize(width: width!, height: height!) // Specify the desired size

                        let scaledImage = image.scalePreservingAspectRatio(
                            targetSize: targetSize
                        )
                        
                        DispatchQueue.main.async {
                            content.image = scaledImage
                            cell.contentConfiguration = content
                        }
                    }
                }.resume()
            }
            break;
        default:
            return cell
        }
        
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch searchSection
        {
        case 0:
            let search = suggestedResults[indexPath.row]
            Search.text = search
            let loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator.startAnimating()
            tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
            SearchClicked(word: search)
            break;
        case 1:
            let search = searchResults[indexPath.row]

            let loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator.startAnimating()
            tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
            
            switch search.videoId
            {
            case "CHANNEL":
                Task
                {
                    API.shared.searchChannelVideos(channelId: search.channelID) { result in
                        switch result
                        {
                        case .success(let videoDictionary):
                            DispatchQueue.main.async {
                                tableView.cellForRow(at: indexPath)?.accessoryView = nil
                                self.performSegueToChannel(videoArray: videoDictionary.0,channelName: search.channelName, Url: videoDictionary.1, playlistInfo: videoDictionary.2)
                            }
                        case .failure( _):
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Error", message: "Sorry, it seems this channel doesn't have any videos available at the moment.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                tableView.cellForRow(at: indexPath)?.accessoryView = nil
                            }
                            return
                        }
                    }
                    
                }
                break
            default:
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "MusicPlayerVC") as! MusicPlayerVC
                vc.delegate = self
                API.shared.sendmp3Link(videoId: search.videoId) { result in
                    
                    switch result {
                    case .success(let mp3Link):
                        // Load the view controller from the storyboard
                        vc.url = mp3Link
                        
                        
                        // Fetch and set the image asynchronously
                        if let imageURL = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/maxresdefault.jpg") {
                            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                                if let error = error {
                                    print("Image download error: \(error)")
                                    // Handle the error as needed
                                } else if let data = data {
                                    let image = UIImage(data: data)
                                    DispatchQueue.main.async {
                                        vc.img = image
                                        vc.SongTitle = search.title
                                        vc.from = "cell"
                                        vc.dateText = search.publishDate as! String
                                        vc.channelName = search.channelName
                                        vc.channelId = search.channelID
                                        tableView.cellForRow(at: indexPath)?.accessoryView = nil
                                        self.navigationController?.present(vc, animated: true)
                                        
                                    }
                                }
                            }.resume()
                        }
                    case .failure(let error):
                        // Handle the API error
                        tableView.cellForRow(at: indexPath)?.accessoryView = nil
                        print("API Error: \(error)")
                    }
                }
            }
            break
        default:
            return
        }
        

    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchSection = 1
        Results.reloadData()
        view.endEditing(true)
    }


    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchSection = 0
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: searchBar.text, afterDelay: 0.5) // Pass the search text as an argument
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        SearchClicked(word: searchBar.text!)
    }
    func SearchClicked(word: String)
    {
        view.endEditing(true)
        API.shared.searchVideos(searchWord: word) { result in
            switch result {
            case .success(let videoDictionary):
                self.searchSection = 1
                self.searchResults = videoDictionary
                self.suggestedResults = [String]()
                DispatchQueue.main.async {
                    self.Results.reloadData()
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    @objc func performSearch(_ searchText: String?) {
        
        API.shared.autoCompletion(searchword: searchText!){result in
            switch result
            {
            case .success(let suggestedTitles):
                self.suggestedResults = suggestedTitles
                
                DispatchQueue.main.async {
                    self.Results.reloadData()
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    

}



extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
extension Notification.Name {
    static let playbackStateChanged = Notification.Name("playbackStateChanged")
}

