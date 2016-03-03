import Foundation

extension NSBundle {

	//! Display name as found in the info.plist against `CFBundleDisplayName`.
	var displayName: String? {
		get {
			return self.objectForInfoDictionaryKey("CFBundleDisplayName") as? String
		}
	}

}
