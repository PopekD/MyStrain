//
//  ChannelVC.swift
//  MyStrain
//
//  Created by Dawid on 27.9.2023.
//


import UIKit

class ChannelVC: UIViewController, UITableViewDelegate, UITableViewDataSource{
    var ChannelName: String?
    var ChannelThumbnail: UIImage?
    var VideoArray: [VideoInfo]?
    var PlaylistInfo: [PlayListInfo]?
    var Selected = "Videos"
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var ThumbNail: UIImageView!
    @IBOutlet weak var Results: UITableView!
    @IBOutlet weak var SelectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Results.dataSource = self
        Results.delegate = self
        setupPopUpButton()
        setupData()

    }
    
    func setupPopUpButton() {
        let Videos = { (action: UIAction) in
            self.Selected = "Videos"
            self.Results.reloadData()
            print(self.VideoArray?.count)
        }
        let PlayList = { (action: UIAction) in
            self.Selected = "Playlist"
            self.Results.reloadData()
        }
                
        SelectButton.menu = UIMenu(children: [
            UIAction(title: "Videos", handler: Videos),
            UIAction(title: "Playlists", handler: PlayList)
        ])
        SelectButton.showsMenuAsPrimaryAction = true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Selected {
        case "Videos":
            return VideoArray!.count
        case "Playlist":
            return PlaylistInfo!.count
        default:
            return 0
        }

    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        var url: URL?
        switch Selected {
        case "Videos":
            let search = VideoArray![indexPath.row]
            content.text = search.title
            cell.backgroundColor = UIColor.clear
            url = URL(string: "https://i.ytimg.com/vi/"+search.videoId+"/hqdefault.jpg")
            break
        case "Playlist":
            let search = PlaylistInfo![indexPath.row]
            content.text = search.playlistName
            cell.backgroundColor = UIColor.clear
            url = search.playlistThumbnail
        default:
            return cell
        }


        if let imageURL = url {
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
        
        
        
        // Show a loading indicator while the API call is in progress (optional)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        tableView.cellForRow(at: indexPath)?.accessoryView = loadingIndicator
        
        switch Selected {
        case "Videos":
            let search = VideoArray![indexPath.row]
            let urlString = URL(string: "https://i.ytimg.com/vi/\(search.videoId)/hqdefault.jpg")
            var img: UIImage?
            if let imageURL = urlString {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        img = image
                    }
                }.resume()
            }
            AudioManager.shared.resetQue()
            AudioManager.shared.addToQueue(id: search.videoId)
            AudioManager.shared.playNextPlaylist() {result in
                switch(result)
                {
                case(.success(_)):
                    DispatchQueue.main.async {
                        AudioManager.shared.showMusciPlayer(navigation: self.navigationController!,from: "cell", videoThumbnail: img!)
                        loadingIndicator.stopAnimating()
                    }
                case(.failure(let error)):
                    print(error.localizedDescription)
                }
            }
                
        break
        case "Playlist":
            let search = PlaylistInfo![indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "PlaylistVC") as! PlaylistVC

            API.shared.getYtPlaylist(playlistID: search.playlistId) { result in

                switch result {
                case .success(let videoResults):
                    
                    let imageURL = search.playlistThumbnail

                    
                        URLSession.shared.dataTask(with: imageURL) { data, response, error in
                            if let error = error {
                                print("Image download error: \(error)")
                                // Handle the error as needed
                            } else if let data = data {
                                let image = UIImage(data: data)
                                DispatchQueue.main.async {
                                    vc.PlaylistIMG = image
                                    vc.PlaylistName = search.playlistName
                                    vc.Videos = videoResults
                                    
                                    tableView.cellForRow(at: indexPath)?.accessoryView = nil
                                    self.navigationController?.pushViewController(vc, animated: true)
                                }
                            }
                        }.resume()
                    
                case .failure(let error):
                    // Handle the API error
                    print("API Error: \(error)")
                }
            }
            
            break
        default:
            return
        }
        
        
    }
    private func setupData()
    {
        Name.text = ChannelName!
        ThumbNail.layer.masksToBounds = true
        ThumbNail.layer.cornerRadius = 10
        ThumbNail.image = ChannelThumbnail!
        ThumbNail.contentMode = .scaleToFill
    }
}
