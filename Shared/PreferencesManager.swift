import UIKit
import Contacts

/// Class used for managing various preferences within the app

class PreferencesManager {

	/// Initialises a `PreferencesManager` connected to the given `NSUserDefaults`.
	/// @param userDefaults The `NSUserDefaults` instance to use for persistant storage.
	/// @return An initialised `PreferencesManager` connected to the given `NSUserDefaults` instance.
	init(_ userDefaults: NSUserDefaults) {
		self.userDefaults = userDefaults
	}

	/// Initialises a `PreferencesManager` connected to the `NSUserDefaults` for the app group matching the given `suiteName`.
	/// @param suiteName The app group to use for persisting preferences (using `NSUserDefaults`).
	/// @return An initialised `PreferencesManager` connected to an `NSUserDefaults` instance.
	convenience init?(suiteName: String) {
		if suiteName.isEmpty {
			return nil
		}

		guard let sharedDefaults = NSUserDefaults(suiteName: suiteName) else {
			return nil
		}

		self.init(sharedDefaults)
	}

	/// Initialise and store a shared manager, based on the `suiteName` for the user defaults we want ot use for storage.
	static let sharedManager = PreferencesManager(suiteName: "group.com.jellystyle.Melissa")

	//! Instance of `NSUserDefaults` used for persistance of preferences.
	var userDefaults: NSUserDefaults

	// MARK: - Appearance

	/// Convenience endpoint for accessing the user-stored tintColor, which falls back to a default.
	class var tintColor: UIColor {
		get {
			return PreferencesManager.sharedManager?.tintColor ?? UIColor(red: 0.122, green: 0.463, blue: 0.804, alpha: 1)
		}
	}

	/// User-selected tint color for giving the app a little bit of customisation.
	var tintColor: UIColor? {
		get {
			return nil
		}
	}

	// MARK: - Messages
	
	//! Array of preset messages to display for quick messaging.
	var messages: [String] {
		get {
			if let messages = self.userDefaults.arrayForKey("messages") as? [String] {
				return messages
			}
			return []
		}
		set(messages) {
			self.userDefaults.setObject(messages, forKey: "messages")
			self.userDefaults.synchronize()
		}
	}

	// MARK: - Contact values

	//! Private storage for the linked contact.
	private var _contact: CNContact? = nil

	//! The linked address book contact.
	var contact: CNContact? {
		get {
			if self._contact != nil {
				return self._contact
			}

			guard let identifier = self.userDefaults.stringForKey("contact-identifier") else {
				return nil
			}

			do {
				let store = CNContactStore()

				self._contact = try store.unifiedContactWithIdentifier(identifier, keysToFetch: [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName), CNContactThumbnailImageDataKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey])

				return self._contact
			} catch {
				return nil
			}
		}
		set(contact) {
			self._contact = contact
			self.callRecipient = nil
			self.messageRecipient = nil

			if contact == nil {
				self.userDefaults.removeObjectForKey("contact-identifier")
			}

			else {
				self.userDefaults.setObject(contact!.identifier, forKey: "contact-identifier")
			}

            self.userDefaults.synchronize()
        }
	}

	func contactThumbnail(size: CGFloat, stroke: CGFloat, edgeInsets: UIEdgeInsets = UIEdgeInsetsZero) -> UIImage? {
		guard let contact = self.contact else {
			return nil
		}

		guard let imageData = contact.thumbnailImageData, let image = UIImage(data: imageData) else {
			return nil
		}

		guard let maskedImage = image.circularImage(size, stroke: stroke) else {
			return nil
		}

		guard let offsetImage = maskedImage.paddedImage(edgeInsets) else {
			return nil
		}

		return offsetImage.imageWithRenderingMode(.AlwaysOriginal)
	}

	/// The number used to make phone calls.
	/// This will default to the first value in the `callOptions` array when a value has not been set.
	var callRecipient: String? {
		get {
            var recipient: String?

            if let message = self.userDefaults.stringForKey("call-recipient") {
                recipient = message
            }
            else if let option = self.callOptions.first {
                recipient = option
            }

            return recipient
        }
		set(call) {
			if call == nil {
				self.userDefaults.removeObjectForKey("call-recipient")
			}

			else {
				self.userDefaults.setObject(call, forKey: "call-recipient")
			}

            self.userDefaults.synchronize()
		}
	}

	var callURL: NSURL? {
		get {
			let characterSet = NSCharacterSet.URLFragmentAllowedCharacterSet()
			guard let number = self.callRecipient?.stringByAddingPercentEncodingWithAllowedCharacters(characterSet) else {
				return nil
			}

			return NSURL(string: "tel:\(number)");
		}
	}

	/// The number or email address used to send messages.
	/// This will default to the first value in the `messageOptions` array when a value has not been set.
	var messageRecipient: String? {
		get {
            var recipient: String?

            if let message = self.userDefaults.stringForKey("message-recipient") {
				recipient = message
			}
			else if let option = self.messageOptions.first {
                recipient = option
			}

            return recipient
		}
		set(message) {
			if message == nil {
				self.userDefaults.removeObjectForKey("message-recipient")
			}

			else {
				self.userDefaults.setObject(message, forKey: "message-recipient")
			}

            self.userDefaults.synchronize()
		}
	}

	var messageURL: NSURL? {
		get {
			let characterSet = NSCharacterSet.URLFragmentAllowedCharacterSet()
			guard let number = self.messageRecipient?.stringByAddingPercentEncodingWithAllowedCharacters(characterSet) else {
				return nil
			}

			return NSURL(string: "sms:\(number)");
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

            options += contact.phoneNumbers.map({
                (labelledValue) in
                return (labelledValue.value as? CNPhoneNumber)?.stringValue
            })

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

            options += contact.phoneNumbers.filter({
                (labelledValue) in
                return labelledValue.label == CNLabelPhoneNumberiPhone || labelledValue.label == CNLabelPhoneNumberMobile
            }).map({
                (labelledValue) in
                return (labelledValue.value as? CNPhoneNumber)?.stringValue
            })

            options += contact.emailAddresses.map({
                (labelledValue) in
                return labelledValue.value as? String
            })

            return options.flatMap({ $0 })
        }
    }

}
