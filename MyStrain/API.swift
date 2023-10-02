import Foundation
import YouTubeKit
import Search

class API {
    static let shared = API()
    private init() {}
    let YTM = YouTubeModel()
    var myInstance:ChannelInfosResponse?
    var VideosContinuation:ChannelInfosResponse.Videos?

    func autoCompletion(searchword: String, completion: @escaping (Result<[String], Error>) -> Void) {
        
        guard let encodedSearchWord = searchword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let urlString = "https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=" + encodedSearchWord
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    
                    if let jsonArray = json as? [Any], jsonArray.count >= 2, let titlesArray = jsonArray[1] as? [String] {
                        completion(.success(titlesArray))
                    } else {
                        let decodingError = NSError(domain: "AutoCompletionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error extracting titles from JSON"])
                        completion(.failure(decodingError))
                    }
                    
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } else {
            completion(.failure(NetworkError.invalidURL))
        }
    }


    func searchVideos(searchWord: String, completion: @escaping (Result<[VideoInfo], Error>) -> Void)  {
        Task {
            SearchResponse.sendRequest(youtubeModel: YTM, data: [.query: searchWord]) { response, error in
                
                var videoInfoArray = [VideoInfo]()
                var channelArray = [VideoInfo]()
                
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                guard let searchResponse = response else {
                    print("No search response")
                    return
                }
                
                for result in searchResponse.results {
                    switch result {
                    case let videoResult as YTVideo:
                        let videoInfo = VideoInfo(videoId: videoResult.videoId,
                                                  title: videoResult.title!,
                                                  channelName: videoResult.channel.name!,
                                                  channelID: videoResult.channel.channelId!,
                                                  publishDate: videoResult.timePosted ?? " ")
                        videoInfoArray.append(videoInfo)
                    case let channelResult as YTChannel:
                        if channelArray.count < 1 {
                            let channelInfo = VideoInfo(videoId: "CHANNEL",
                                                        title: channelResult.name!,
                                                        channelName: channelResult.name!,
                                                        channelID: channelResult.channelId,
                                                        publishDate: channelResult.thumbnails.last!.url  )
                            channelArray.append(channelInfo)
                        }
                    default:
                        break
                    }
                }
                videoInfoArray.insert(contentsOf: channelArray, at: 0)

                completion(.success(videoInfoArray))
            }
        }
    }
    func searchChannelVideos(channelId: String, completion: @escaping (Result<([VideoInfo], URL?, [PlayListInfo]), Error>) -> Void) {
        Task {

                var videoInfoArray = [VideoInfo]()
                var playlistArray = [PlayListInfo]()
                var ThumbnailURL: URL?

                // Fetch channel information
                let channelResult = await ChannelInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId: channelId])
                self.myInstance = channelResult.0
                ThumbnailURL = myInstance?.avatarThumbnails.last?.url

                let videosResult = await self.myInstance?.getChannelContent(type: .videos, youtubeModel: self.YTM)

                if(videosResult?.0?.channelContentStore[.videos] != nil)
                {
                    
                    let videosContent = videosResult?.0?.channelContentStore[.videos]
                    
                    let contentVid = videosContent as! ChannelInfosResponse.Videos
                    let channelVideos = contentVid.videos

                    for video in channelVideos {
                        let videoInfo = VideoInfo(
                            videoId: video.videoId,
                            title: video.title!,
                            channelName: video.channel.name!,
                            channelID: video.channel.channelId!,
                            publishDate: video.timePosted ?? " "
                        )
                        videoInfoArray.append(videoInfo)
                    }
                }


                // Fetch playlists
                let playlistsResult = await self.myInstance?.getChannelContent(type: .playlists, youtubeModel: self.YTM)
                
                if(playlistsResult?.0?.channelContentStore[.playlists] != nil)
                {
                    let playlistContent = playlistsResult?.0?.channelContentStore[.playlists]
                    

                    let contentPlay = playlistContent as! ChannelInfosResponse.Playlists
                    let channelPlaylist = contentPlay.playlists
                    
                    for playlist in channelPlaylist {
                        let playlistInfo = PlayListInfo(
                            playlistId: playlist.playlistId,
                            playlistName: playlist.title ?? " ",
                            playlistThumbnail: (playlist.thumbnails.last?.url ?? URL(string: "https://img.youtube.com/vi/0/maxresdefault.jpg"))!
                        )
                        playlistArray.append(playlistInfo)
                    }
                }

                completion(.success((videoInfoArray, ThumbnailURL, playlistArray)))

        }
    }
    
    func getYtPlaylist(playlistID: String, completion: @escaping (Result<[VideoInfo], Error>) -> Void)
    {
        
        Task
        {
           var videoArray = [VideoInfo]()
           let playListInfo = await PlaylistInfosResponse.sendRequest(youtubeModel:YTM, data: [.browseId: playlistID])
           let content = playListInfo.0
            for videos in content!.videos
            {
                let videoInfo = VideoInfo(videoId: videos.videoId,
                                          title: videos.title ?? " ",
                                          channelName: videos.channel.name ?? " ",
                                          channelID: videos.channel.channelId ?? " ",
                                          publishDate: videos.timePosted ?? " "
                )
                videoArray.append(videoInfo)
            }
            completion(.success(videoArray))
        }
    }


    func getContinuation(type: String, completion: @escaping (Result<[VideoInfo], Error>) -> Void)
    {
        switch type
        {
        case "Videos":
            break
        case "Playlist":
            break
        default:
            break
        }
    }
    

    func sendmp3Link(videoId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            let stream = try await YouTube(videoID: videoId).livestreams
                                      .filter { $0.streamType == .hls }
                                      .first

            if let mp3Link = stream?.url {
                    completion(.success(mp3Link))
                    
                } else {
                    
                    completion(.failure(NetworkError.noData))
                }
        }
    }

}

struct VideoInfo {
    let videoId: String
    let title: String
    let channelName: String
    let channelID: String
    let publishDate: Any
}
struct PlayListInfo {
    let playlistId: String
    let playlistName: String
    let playlistThumbnail: URL
}

enum NetworkError: Error {
    case invalidURL
    case noData
}


