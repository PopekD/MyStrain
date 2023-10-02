//
//  PlaylistVC.swift
//  MyStrain
//
//  Created by Dawid on 2.10.2023.
//

import Foundation
import UIKit

class PlaylistVC: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var Videos = [VideoInfo]()
    var PlaylistIMG: UIImage?
    var PlaylistName: String?
    
    @IBOutlet weak var Results: UITableView!
    @IBOutlet weak var PlaylistNameUI: UILabel!
    @IBOutlet weak var PlaylistIMGUI: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Results.delegate = self
        Results.dataSource = self
        setUpUI()
    }
    
    func setUpUI()
    {
        PlaylistNameUI.text = PlaylistName!
        PlaylistIMGUI.layer.masksToBounds = true
        PlaylistIMGUI.layer.cornerRadius = 10
        PlaylistIMGUI.image = PlaylistIMG!
        PlaylistIMGUI.contentMode = .scaleToFill
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        let search = Videos[indexPath.row]
        
        content.text = search.title
        cell.backgroundColor = UIColor.clear
        
        let url = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/hqdefault.jpg")
        
        if let imageURL = url {
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {

                    let targetSize = CGSize(width: 80, height: 80)

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
        
        let search = Videos[indexPath.row]

        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MusicPlayerVC") as! MusicPlayerVC
        vc.delegate = MusicPlayerVC.homeDelegate
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
    
}
