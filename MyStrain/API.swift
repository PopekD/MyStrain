import Foundation

class API {
    static let shared = API()
    private init() {}

    private let apiKey = ""

    func searchVideos(searchWord: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let baseURL = "https://www.googleapis.com/youtube/v3/search"
        let parameters: [String: Any] = [
            "key": apiKey,
            "q": searchWord,
            "part": "snippet",
            "type": "video",
            "maxResults": 5 
        ]

        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }

        guard let url = urlComponents.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let searchResults = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
                var videoDictionary: [String: String] = [:]

                for item in searchResults.items {
                    if let videoId = item.id.videoId, let videoTitle = item.snippet.title
                    {
                        videoDictionary[videoId] = videoTitle
                    }
                }

                completion(.success(videoDictionary))
            } catch let decoderError {
                completion(.failure(decoderError))
            }
        }.resume()
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
        let snippet: Snippet
        let id: ID
    }
    let items: [Item]
}

enum NetworkError: Error {
    case invalidURL
    case noData
}
