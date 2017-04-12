import UIKit
import Contacts
import ContactsUI
import MessageUI

/// Class used for managing various preferences within the app

class PreferencesManager: NSObject {

	/// Initialises a `PreferencesManager` connected to the given `NSUserDefaults`.
	/// @param userDefaults The `NSUserDefaults` instance to use for persistant storage.
	/// @return An initialised `PreferencesManager` connected to the given `NSUserDefaults` instance.
	init(_ userDefaults: UserDefaults) {
		self.userDefaults = userDefaults
	}

	/// Initialises a `PreferencesManager` connected to the `NSUserDefaults` for the app group matching the given `suiteName`.
	/// @param suiteName The app group to use for persisting preferences (using `NSUserDefaults`).
	/// @return An initialised `PreferencesManager` connected to an `NSUserDefaults` instance.
	convenience init?(suiteName: String) {
		if suiteName.isEmpty {
			return nil
		}

		guard let sharedDefaults = UserDefaults(suiteName: suiteName) else {
			return nil
		}

		self.init(sharedDefaults)
	}

	/// Initialise and store a shared manager, based on the `suiteName` for the user defaults we want ot use for storage.
	static let sharedManager = PreferencesManager(suiteName: "group.com.jellystyle.Other")

	//! Instance of `NSUserDefaults` used for persistance of preferences.
	var userDefaults: UserDefaults

	// MARK: - Appearance

	//! Color used for display text
	static var textColor: UIColor = UIColor(red:0.290,  green:0.290,  blue:0.290, alpha:1)

	//! Color used for view background
	static var backgroundColor: UIColor = UIColor.groupTableViewBackground
	
	/// Color used for highlights throughout the app
	static var tintColor: UIColor = UIColor(hue:0.664, saturation:0.636, brightness:0.839, alpha:1)

	// MARK: - Messages
	
	//! Array of preset messages to display for quick messaging.
	dynamic var messages: [String] {
		get {
			if let messages = self.userDefaults.array(forKey: "messages") as? [String] {
				return messages
			}
			return [ "🚗💨", "🚙🚛🚗🚓🚚", "👋" ]
		}
		set(messages) {
			self.userDefaults.set(messages, forKey: "messages")
			self.userDefaults.synchronize()
		}
	}
    
    func updateShortcutItems(_ application: UIApplication) {
		guard #available(iOS 9.1, *) else {
			return
		}

		var shortcutItems: [UIMutableApplicationShortcutItem] = []
		for message in self.messages {
			let item = UIMutableApplicationShortcutItem(type: "message-shortcut", localizedTitle: message)
			item.icon = UIApplicationShortcutIcon(type: .compose)
			shortcutItems.append(item)
		}
		application.shortcutItems = shortcutItems
	}

	// MARK: - Contact values

	//! Private storage for the linked contact.
	fileprivate var _contact: CNContact? = nil

	//! The linked address book contact.
	dynamic var contact: CNContact? {
		get {
			if self._contact != nil {
				return self._contact
			}

			guard let identifier = self.userDefaults.string(forKey: "contact-identifier") else {
				return nil
			}
            
			do {
				let store = CNContactStore()

				self._contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: [
					CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
					CNContactThumbnailImageDataKey as CNKeyDescriptor,
					CNContactImageDataAvailableKey as CNKeyDescriptor,
					CNContactPhoneNumbersKey as CNKeyDescriptor,
					CNContactEmailAddressesKey as CNKeyDescriptor
				])

				return self._contact
			} catch {
				return nil
			}
		}
		set(contact) {
			// Attempt to grab the full contact so we prompt for access, if needed.
			let unifiedContact: CNContact?
			do {
				let store = CNContactStore()
				if contact != nil {
					unifiedContact = try store.unifiedContact(withIdentifier: contact!.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
				}
				else {
					unifiedContact = nil
				}
			} catch {
				unifiedContact = nil
			}
			
			self._contact = unifiedContact
			self.callRecipient = nil
			self.messageRecipient = nil
			self.facetimeRecipient = nil

			if contact == nil {
				self.userDefaults.removeObject(forKey: "contact-identifier")
			}

			else {
				self.userDefaults.set(contact!.identifier, forKey: "contact-identifier")
			}

            self.userDefaults.synchronize()
        }
	}

	/// Flag to indicate if the selected contact has an image attached.
	var contactHasThumbnail: Bool {
		guard let contact = self.contact else {
			return false
		}

		return contact.imageDataAvailable
	}

	/// Get the contact thumbnail at a given size.
	/// @param size The diameter for the thumbnail.
	/// @param stroke The width of the stroke in points.
	/// @param edgeInsets Padding to apply around the thumbnail.
	/// @return Contact's image, formatted to match the given parameters.
	func contactThumbnail(_ size: CGFloat, stroke: CGFloat, edgeInsets: UIEdgeInsets = UIEdgeInsets.zero) -> UIImage? {
		guard let contact = self.contact else {
			return nil
		}

		var image = UIImage(named: "empty")!
		if let data = contact.thumbnailImageData, let imageFromData = UIImage(data: data) {
			image = imageFromData
		}

		guard let maskedImage = image.circularImage(size, stroke: stroke) else {
			return nil
		}

		guard let offsetImage = maskedImage.paddedImage(edgeInsets) else {
			return nil
		}

		return offsetImage.withRenderingMode(.alwaysOriginal)
	}

	/// The number used to make phone calls.
	/// This will default to the first value in the `callOptions` array when a value has not been set.
	dynamic var callRecipient: String? {
		get {
            var recipient: String?

            if let message = self.userDefaults.string(forKey: "call-recipient") {
                recipient = message
            }
            else if let option = self.callOptions.first {
                recipient = option
            }

            return (recipient?.characters.count ?? 0 > 0) ? recipient : nil
        }
		set(call) {
			if call == nil {
				self.userDefaults.removeObject(forKey: "call-recipient")
			}

			else {
				self.userDefaults.set(call, forKey: "call-recipient")
			}

            self.userDefaults.synchronize()
		}
	}

	var callURL: URL? {
		get {
			let characterSet = CharacterSet.urlFragmentAllowed
			guard let number = self.callRecipient?.addingPercentEncoding(withAllowedCharacters: characterSet) else {
				return nil
			}

			return URL(string: "tel:\(number)");
		}
	}

	/// The number or email address used to send messages.
	/// This will default to the first value in the `messageOptions` array when a value has not been set.
	dynamic var messageRecipient: String? {
		get {
            var recipient: String?

            if let message = self.userDefaults.string(forKey: "message-recipient") {
				recipient = message
			}
			else if let option = self.messageOptions.first {
                recipient = option
			}

            return (recipient?.characters.count ?? 0 > 0) ? recipient : nil
		}
		set(message) {
			if message == nil {
				self.userDefaults.removeObject(forKey: "message-recipient")
			}

			else {
				self.userDefaults.set(message, forKey: "message-recipient")
			}

            self.userDefaults.synchronize()
		}
	}
    
    var messageURL: URL? {
        get {
            let characterSet = CharacterSet.urlFragmentAllowed
            guard let number = self.messageRecipient?.addingPercentEncoding(withAllowedCharacters: characterSet) else {
                return nil
            }
            
            return URL(string: "sms:\(number)");
        }
    }
    
    /// The number or email address used to make Facetime calls.
    /// This will default to `nil`
    dynamic var facetimeRecipient: String? {
        get {
            var recipient: String?
            
            if let facetime = self.userDefaults.string(forKey: "facetime-recipient") {
                recipient = facetime
            }
            
            return (recipient?.characters.count ?? 0 > 0) ? recipient : nil
        }
        set(facetime) {
            if facetime == nil {
                self.userDefaults.removeObject(forKey: "facetime-recipient")
            }
                
            else {
                self.userDefaults.set(facetime, forKey: "facetime-recipient")
            }
            
            self.userDefaults.synchronize()
        }
    }
    
    var facetimeURL: URL? {
        get {
            let characterSet = CharacterSet.urlFragmentAllowed
            guard let number = self.facetimeRecipient?.addingPercentEncoding(withAllowedCharacters: characterSet) else {
                return nil
            }

            return URL(string: "facetime:\(number)");
        }
    }

	// MARK: - Contact options

	/// Potential values from the linked contact for the `callRecipient` property.
	/// If no contact is linked, returns an empty array.
    var callOptions: [String] {
		get {
			guard let contact = self.contact else {
				return []
			}

            var options: [String?] = []

			options += contact.phoneNumbers.flatMap { entry -> String? in
				return entry.value.stringValue
			}

            return options.flatMap({ $0 })
		}
	}
    
    /// Potential values from the linked contact for the `messageRecipient` property.
    /// If no contact is linked, returns an empty array.
    var messageOptions: [String] {
        get {
            guard let contact = self.contact else {
                return []
            }
            
            var options: [String?] = []

			options += contact.phoneNumbers.flatMap { entry -> String? in
				guard entry.label == CNLabelPhoneNumberiPhone || entry.label == CNLabelPhoneNumberMobile else {
					return nil
				}

				return entry.value.stringValue
			}
			
			options += contact.emailAddresses.flatMap { entry -> String? in
				return entry.value as String
			}

            return options.flatMap({ $0 })
        }
    }
    
    /// Potential values from the linked contact for the `facetimeRecipient` property.
    /// If no contact is linked, returns an empty array.
    var facetimeOptions: [String] {
        get {
            guard let contact = self.contact else {
                return []
            }
            
            var options: [String?] = []
            
			options += contact.phoneNumbers.flatMap { entry -> String? in
				guard entry.label == CNLabelPhoneNumberiPhone || entry.label == CNLabelPhoneNumberMobile else {
					return nil
				}

				return entry.value.stringValue
			}

			options += contact.emailAddresses.flatMap { entry -> String? in
				return entry.value as String
			}

            return options.flatMap({ $0 })
        }
    }

	// MARK: Analytics

    /// Log a count of the number of calls made
    func didStartCall() {
        let key = "analytics-open-call"
        let count = self.userDefaults.integer(forKey: key)
        self.userDefaults.set(count+1, forKey: key)
    }
    
    /// Log a count of the number of calls made
    func didStartFaceTime() {
        let key = "analytics-open-facetime"
        let count = self.userDefaults.integer(forKey: key)
        self.userDefaults.set(count+1, forKey: key)
    }
    
	/// Log a count of the number of times Messages.app was opened
	func didOpenMessages() {
		let key = "analytics-open-messages"
		let count = self.userDefaults.integer(forKey: key)
		self.userDefaults.set(count+1, forKey: key)
	}

	/// Log a count of the number of messages sent
	func didFinishMessaging(_ result: MessageComposeResult) {
		if result != .sent { return }
		let key = "analytics-sent-messages"
		let count = self.userDefaults.integer(forKey: key)
		self.userDefaults.set(count+1, forKey: key)
	}

}
