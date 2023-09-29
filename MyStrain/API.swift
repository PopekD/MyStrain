import Foundation
import YouTubeKit
import Search

class API {
    static let shared = API()
    private init() {}
    let YTM = YouTubeModel()
    var myInstance:ChannelInfosResponse?
    

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

                    default:
                        break
                    }
                }

                completion(.success(videoInfoArray))
            }
        }
    }
    func searchChannelVideos(channelId: String, completion: @escaping (Result<([VideoInfo], URL?), Error>) -> Void)
    {
  
        Task
        {
            
            var videoInfoArray = [VideoInfo]()
            
            ChannelInfosResponse.sendRequest(youtubeModel: YTM, data: [.browseId: channelId]) { result, error in
                self.myInstance = result!
                
                self.myInstance!.getChannelContent(type: .videos, youtubeModel: self.YTM) { videos, error in
                    if let videosContent = videos!.channelContentStore[.videos] as? ChannelInfosResponse.Videos {
                        let videos = videosContent.videos
                        
                        for video in videos {
                            let videoInfo = VideoInfo(
                                                      videoId: video.videoId,
                                                      title: video.title!,
                                                      channelName: video.channel.name!,
                                                      channelID: video.channel.channelId!,
                                                      publishDate: video.timePosted ?? " ")
                            videoInfoArray.append(videoInfo)
                        }
                        
                    }
                    completion(.success((videoInfoArray, videos?.avatarThumbnails.last?.url)))
                    
                }
            }

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
    let publishDate: String
}


enum NetworkError: Error {
    case invalidURL
    case noData
}


