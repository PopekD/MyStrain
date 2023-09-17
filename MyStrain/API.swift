import Foundation
import YouTubeKit
import Search

class API {
    static let shared = API()
    private init() {}
    let YTM = YouTubeModel()
    
    func searchVideos(searchWord: String, completion: @escaping (Result<[String:String], Error>) -> Void)  {
        Task {
            SearchResponse.sendRequest(youtubeModel: YTM, data: [.query: searchWord]) { response, error in
                var SearchResponseData =  [String: String]()
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
                        SearchResponseData[videoResult.videoId] = String(videoResult.title!)
                        
                    default:
                        break
                    }
                }
                completion(.success(SearchResponseData))
            }
        }
    }






    func sendmp3Link(videoId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        Task {
            let stream = try await YouTube(videoID: videoId).streams
                    .filterAudioOnly()
                    .highestAudioBitrateStream()
            
                if let mp3Link = stream?.url {
                    completion(.success(mp3Link))
                    
                } else {
                    
                    completion(.failure(NetworkError.noData))
                }
        }
    }

}

struct YouTubeSearchResponse: Decodable {
    struct Item: Decodable {
        struct Snippet: Decodable {
            let title: String?
        }
        struct ID: Decodable {
            let videoId: String?
        }
    }
    let items: [Item]
}

enum NetworkError: Error {
    case invalidURL
    case noData
}


