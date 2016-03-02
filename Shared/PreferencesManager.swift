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

		guard let maskedImage = self._maskImage(image, size: size, stroke: stroke) else {
			return nil
		}

		guard let offsetImage = self._offsetImage(maskedImage, edgeInsets: edgeInsets) else {
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

	// MARK: - Utilities

	/// Create a new image which is resized and masked as a circle, with an optional white stroke.
	/// @param image The image to be masked.
	/// @param size The diameter to use for the circle. The given image will be resized to fill this space.
	/// @param stroke Line width to use for the stroke, defaults to 0 (which does not render a stroke).
	/// @return A circular image matching the given parameters.
	private func _maskImage(image: UIImage?, size: CGFloat, stroke: CGFloat = 0) -> UIImage? {
		guard let image = image else { return nil }
		if size == 0 { return nil }

		let scale = UIScreen.mainScreen().scale
		let scaledSize = size * scale

		let source = image.CGImage

		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let context = CGBitmapContextCreate(nil, Int(scaledSize), Int(scaledSize), CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), bitmapInfo.rawValue)

		let percent = scaledSize / min(image.size.width * image.scale, image.size.height * image.scale)
		let rectSize = CGSize(width: image.size.width * image.scale * percent, height: image.size.height * image.scale * percent)
		let rectOrigin = CGPoint(x: ((rectSize.width - scaledSize) / 2), y: ((rectSize.height - scaledSize) / 2) )
		var rect = CGRect(origin: rectOrigin, size: rectSize)

		if( stroke >= 1 ) {
			CGContextAddEllipseInRect(context, rect)
			CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
			CGContextDrawPath(context, .Fill)

			rect = rect.insetBy(dx: stroke * scale, dy: stroke * scale)
		}

		CGContextAddEllipseInRect(context, rect)
		CGContextClip(context)

		CGContextDrawImage(context, rect, source)

		guard let imageRef = CGBitmapContextCreateImage(context) else {
			return nil
		}

		return UIImage(CGImage: imageRef, scale: scale, orientation: image.imageOrientation)
	}

	/// Creates a new image in which the given image is "padded" based on the given `edgeInsets`.
	/// This allows manual adjustments to an image's apparent position without needing to adjust the image view.
	/// @param image The image to be offset.
	/// @param edgeInsets The padding to use for each of the four sides.
	/// @return A new image which has (transparent) padding added based on the given `edgeInsets`.
	private func _offsetImage(image: UIImage?, edgeInsets: UIEdgeInsets) -> UIImage? {
		guard let image = image else { return nil }
		if edgeInsets == UIEdgeInsetsZero { return image }

		let scale = UIScreen.mainScreen().scale

		let source = image.CGImage

		let contextSize = CGSize(width: (image.size.width + edgeInsets.left + edgeInsets.right) * scale, height: (image.size.height + edgeInsets.top + edgeInsets.bottom) * scale)
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let context = CGBitmapContextCreate(nil, Int(contextSize.width), Int(contextSize.height), CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), bitmapInfo.rawValue)

		let rect = CGRect(x: edgeInsets.left * scale, y: edgeInsets.bottom * scale, width: image.size.width * scale, height: image.size.height * scale)
		CGContextDrawImage(context, rect, source)

		guard let imageRef = CGBitmapContextCreateImage(context) else {
			return nil
		}

		return UIImage(CGImage: imageRef, scale: scale, orientation: image.imageOrientation)
	}

}
