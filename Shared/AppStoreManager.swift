import Foundation

class AppStoreManager {

	/// Initialise and store a shared manager.
	static var sharedManager = AppStoreManager()

	/// Identifier for the app in the App Store.
	var storeIdentifier: String

	/// Initialises an `AppStoreManager` using the `JSMAppStoreIdentifier` found in the app's info.plist.
	/// Fails if the app is a prerelease build, or if no valid identifier could be found.
	init?() {
		let bundle = NSBundle.mainBundle()

		storeIdentifier = bundle.objectForInfoDictionaryKey("JSMAppStoreIdentifier") as? String ?? ""

		if storeIdentifier.isEmpty { return nil }

		if !bundle.debug && bundle.prerelease { return nil }
	}

	/// URL for opening the App Store to the current app's details page
	var storeURL: NSURL {
		return NSURL(string: "https://itunes.apple.com/au/app/app/id\(self.storeIdentifier)?mt=8")!
	}

	// MARK: - User ratings

	/// Get the number of ratings for the current version of the app.
	/// The value will be `nil` if no count has been fetched using `fetchNumberOfUserRatings`, or if this call has not succeeded for the current version.
	var numberOfUserRatings: Int? {
		get {
			guard let dictionary = NSUserDefaults.standardUserDefaults().objectForKey("JSMRatingCount") as? Dictionary<String,Int> else { return nil }
			guard let version = NSBundle.mainBundle().versionString else { return nil }
			return dictionary[version]
		}
	}

	/// Get the number of user ratings for the current app version from the iTunes API and store the value.
	/// This method is best called well in advance of actually needing the value it fetches, to allow for network related delays.
	func fetchNumberOfUserRatings() {
		guard let version = NSBundle.mainBundle().versionString else { return }

		let url = NSURL(string: "https://geo.itunes.apple.com/lookup?id=\(self.storeIdentifier)")!

		let task = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
			guard let data = data where error == nil else { return }

			let convertedData = NSData(bytes: data.bytes, length: data.length)
			do {
				let json = try NSJSONSerialization.JSONObjectWithData(convertedData, options: NSJSONReadingOptions(rawValue: 0))

				guard let dictionary = json as? Dictionary<String, AnyObject> else { return }

				guard let results = dictionary["results"] as? Array<AnyObject> else { return }

				guard let firstResult = results[0] as? Dictionary<String, AnyObject> else { return }

				if firstResult["version"] as? String != version { return }

				guard let userRatingCount = firstResult["userRatingCountForCurrentVersion"] as? Int else { return }

				NSUserDefaults.standardUserDefaults().setObject([ version: userRatingCount ], forKey: "JSMRatingCount")
				NSUserDefaults.standardUserDefaults().synchronize()
			}
			catch { return }
		}

		task.resume()
	}


}
