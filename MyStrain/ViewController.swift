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
    
    func performSegueToChannel(videoArray: [VideoInfo], channelName: String, Url: URL?) {
        
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
        self.hideKeyboardWhenTapped()
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
        case 1:
            return searchResults.count
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
        case 1:
            let search = searchResults[indexPath.row]
            content.text = search.title
            cell.backgroundColor = UIColor.clear
            
            
            
            // Load the image asynchronously from the URL
            if let imageURL = URL(string: "https://i.ytimg.com/vi/"+search.videoId+"/hqdefault.jpg") {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        // Set the image on the main queue
                        let targetSize = CGSize(width: 80, height: 80) // Specify the desired size

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
        case 1:
            let search = searchResults[indexPath.row]
            
            // Show a loading indicator while the API call is in progress (optional)
            let loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator.startAnimating()
            tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
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
                                    vc.dateText = search.publishDate
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
                    print("API Error: \(error)")
                }
            }
        default:
            return
        }
        

    }





    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty
        {
            searchSection = 0
            Results.reloadData()
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: searchBar.text, afterDelay: 0.5) // Pass the search text as an argument
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        SearchClicked(word: searchBar.text!)
    }
    func SearchClicked(word: String)
    {
        API.shared.searchVideos(searchWord: word) { result in
            switch result {
            case .success(let videoDictionary):
                self.searchSection = 1
                self.searchResults = [VideoInfo]()
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

extension UIViewController {
    func hideKeyboardWhenTapped(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard()
    {
        view.endEditing(true)
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

