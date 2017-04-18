import Foundation

extension URL {
    
    static var contactOther: URL {
        return URL(string: "my-other:/contact")!
    }
    
    static var messageOther: URL {
        return self.messageOther(with: nil)
    }

    static func messageOther(with body: String?) -> URL {
        var components = URLComponents(string: "my-other:/message")!
        
        if let body = body {
            components.queryItems = [URLQueryItem(name: "body", value: body)]
        }

        return components.url!
    }

}
