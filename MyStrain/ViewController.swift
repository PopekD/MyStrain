//
//  ViewController.swift
//  MyStrain
//
//  Created by Nini on 22.8.2023.
//

import UIKit


class ViewController: UIViewController, UISearchBarDelegate,
                      UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var Search: UISearchBar!
    @IBOutlet weak var Results: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Search.delegate = self
        Results.delegate = self
        Results.dataSource = self
        Results.allowsSelection = true
        self.hideKeyboardWhenTapped()
        
    }
    
    var searchResults: [String:String] = [:]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let videoUrls = Array(searchResults.keys)
        let key = Array(searchResults.keys)[indexPath.row]
        content.text = searchResults[key]!
        
        
        // Load the image asynchronously from the URL
        if let imageURL = URL(string: "https://i.ytimg.com/vi/"+videoUrls[indexPath.row]+"/hqdefault.jpg") {
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
        
        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoUrls = Array(searchResults.keys)
        
        let selectedVideoUrl = videoUrls[indexPath.row]
        
        // Show a loading indicator while the API call is in progress (optional)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MusicPlayerVC") as! MusicPlayerVC
        // Call the API asynchronously
        API.shared.sendmp3Link(videoId: selectedVideoUrl) { result in

            switch result {
            case .success(let mp3Link):
                // Load the view controller from the storyboard
                vc.url = mp3Link
                
                // Fetch and set the image asynchronously
                if let imageURL = URL(string: "https://i.ytimg.com/vi/\(selectedVideoUrl)/maxresdefault.jpg") {
                    URLSession.shared.dataTask(with: imageURL) { data, response, error in
                        if let error = error {
                            print("Image download error: \(error)")
                            // Handle the error as needed
                        } else if let data = data {
                            let image = UIImage(data: data)
                            DispatchQueue.main.async {
                                vc.img = image
                                // Remove the loading indicator
                                tableView.cellForRow(at: indexPath)?.accessoryView = nil
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        }
                    }.resume()
                }
            case .failure(let error):
                // Handle the API error
                print("API Error: \(error)")
            }
        }
    }





    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: searchBar.text, afterDelay: 0.5) // Pass the search text as an argument
    }

    @objc func performSearch(_ searchText: String?) {
        guard let searchText = searchText else { return }
        
        API.shared.searchVideos(searchWord: searchText) { result in
            switch result {
            case .success(let videoDictionary):
                self.searchResults = videoDictionary
                DispatchQueue.main.async {
                    
                    self.Results.reloadData()
                }
            case .failure(let error):
                print("Error: \(error)")
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
