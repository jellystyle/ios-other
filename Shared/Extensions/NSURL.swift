import Foundation

extension NSURL {
    
    static var contactOther: NSURL {
        return NSURL(string: "my-other:/contact")!
    }
    
    static var messageOther: NSURL {
        return self.messageOther(with: nil)
    }

    static func messageOther(with body: String?) -> NSURL {
        let components = NSURLComponents(string: "my-other:/message")!
        
        if let body = body {
            components.queryItems = [NSURLQueryItem(name: "body", value: body)]
        }

        return components.URL!
    }

}
