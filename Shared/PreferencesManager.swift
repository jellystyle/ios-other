import Foundation
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

	//! Instance of `NSUserDefaults` used for persistance of preferences.
	var userDefaults: NSUserDefaults

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
		}
	}

	/// The number used to make phone calls.
	/// This will default to the first value in the `callOptions` array when a value has not been set.
	var callRecipient: String? {
		get {
			if let call = self.userDefaults.stringForKey("call-recipient") {
				return call
			}

			if let recipient = self.callOptions.first {
				if let phoneNumber = recipient.value as? CNPhoneNumber {
					return phoneNumber.stringValue
				}
				return (recipient.value as? String)
			}

			return nil
		}
		set(call) {
			if call == nil {
				self.userDefaults.removeObjectForKey("call-recipient")
			}

			else {
				self.userDefaults.setObject(call, forKey: "call-recipient")
			}
		}
	}

	/// The number or email address used to send messages.
	/// This will default to the first value in the `messageOptions` array when a value has not been set.
	var messageRecipient: String? {
		get {
			if let message = self.userDefaults.stringForKey("message-recipient") {
				return message
			}

			if let recipient = self.callOptions.first {
				if let phoneNumber = recipient.value as? CNPhoneNumber {
					return phoneNumber.stringValue
				}
				return (recipient.value as? String)
			}

			return nil
		}
		set(message) {
			if message == nil {
				self.userDefaults.removeObjectForKey("message-recipient")
			}

			else {
				self.userDefaults.setObject(message, forKey: "message-recipient")
			}
		}
	}

	// MARK: - Contact options

	/// Potential values from the linked contact for the `callRecipient` property.
	/// If no contact is linked, returns an empty array.
	var callOptions: [CNLabeledValue] {
		get {
			guard let contact = self.contact else {
				return []
			}

			return contact.phoneNumbers
		}
	}

	/// Potential values from the linked contact for the `messageRecipient` property.
	/// If no contact is linked, returns an empty array.
	var messageOptions: [CNLabeledValue] {
		guard let contact = self.contact else {
			return []
		}

		let phoneNumbers = contact.phoneNumbers.filter({
			(labelledValue) in
			return labelledValue.label == CNLabelPhoneNumberiPhone || labelledValue.label == CNLabelPhoneNumberMobile
		})

		return phoneNumbers + contact.emailAddresses
	}

}
