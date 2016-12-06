import Foundation

extension NSBundle {

	//! Flag to indicate if the receiver is a debug build.
	var debug: Bool {
		get {
			#if DEBUG
				return true
			#else
				return false
			#endif
		}
	}
    
    //! Flag to indicate if the bundle represents an application.
    var app: Bool {
        get {
            return self.bundleURL.pathExtension == "app"
        }
    }
    
    //! Flag to indicate if the bundle represents an app extension.
    var appex: Bool {
        get {
            return self.bundleURL.pathExtension == "appex"
        }
    }
    
    //! Flag to indicate if the receiver is a prerelease build (usually Testflight).
    var prerelease: Bool {
        get {
            return self.pathForResource("embedded", ofType: "mobileprovision") != nil
        }
    }

	//! Display name as found in the info.plist against `CFBundleDisplayName`.
	var displayName: String? {
		get {
			return self.objectForInfoDictionaryKey("CFBundleDisplayName") as? String
		}
	}

	//! Marketing version number as found in the info.plist against `CFBundleShortVersionString`.
	var versionString: String? {
		get {
			return self.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String
		}
	}

	//! Build number as found in the info.plist against `CFBundleVersion`.
	var buildString: String? {
		get {
			return self.objectForInfoDictionaryKey("CFBundleVersion") as? String
		}
	}

	//! Human-readable version identifier, including build number, prerelease information and marketing version.
	var displayVersion: String? {
		get {
			let configuration: String
			if self.debug {
				configuration = " Development"
			}
			else if self.prerelease {
				configuration = " Prerelease"
			}
			else {
				configuration = ""
			}

			if let version = self.versionString, let build = self.buildString {
				return "v\(version)\(configuration) (\(build))"
			}

			else if let version = self.versionString {
				return "v\(version)\(configuration)"
			}

			else if let build = self.buildString {
				return "\(build)\(configuration)"
			}

			else if configuration.characters.count > 0 {
				return configuration.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			}
			
			return nil;
		}
	}

}
