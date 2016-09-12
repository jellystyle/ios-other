import UIKit
import MessageUI
import MobileCoreServices

class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {

	//! The messages view controller used to present the shared items.
	var messageController: MFMessageComposeViewController?

	// MARK: Handling extension requests

	override func beginRequestWithExtensionContext(context: NSExtensionContext) {
		super.beginRequestWithExtensionContext(context)

		guard let preferences = PreferencesManager.sharedManager else {
			return
		}

		guard let messageRecipient = preferences.messageRecipient where messageRecipient.characters.count > 0 else {
			return
		}

		let messageController = MFMessageComposeViewController()
		messageController.messageComposeDelegate = self
		messageController.recipients = [messageRecipient]

		let typeIdentifiers = [kUTTypeFileURL, kUTTypeURL, kUTTypeJPEG, kUTTypeJPEG2000, kUTTypeTIFF, kUTTypePICT, kUTTypeGIF, kUTTypePNG, kUTTypeQuickTimeImage, kUTTypeAppleICNS, kUTTypeBMP, kUTTypeICO, kUTTypeImage, kUTTypeQuickTimeMovie, kUTTypeMPEG, kUTTypeMPEG4, kUTTypeMP3, kUTTypeMPEG4Audio, kUTTypeAppleProtectedMPEG4Audio, kUTTypeAudiovisualContent, kUTTypeText, kUTTypePDF, kUTTypeRTFD, kUTTypeVCard]

        var items = 0
		for item in context.inputItems as? [NSExtensionItem] ?? [] {
			for itemProvider in item.attachments as? [NSItemProvider] ?? [] {
				for typeIdentifier in typeIdentifiers where self.attemptToHandle(itemProvider, typeIdentifier: typeIdentifier) {
                    items += 1

                    break
				}
			}
		}

		if items == 0 {
			return
		}

		self.messageController = messageController
	}

	func attemptToHandle(itemProvider: NSItemProvider!, typeIdentifier: CFString!) -> Bool {
		if !itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier as String) {
			return false
		}

		itemProvider.loadItemForTypeIdentifier(typeIdentifier as String, options: nil, completionHandler: { item, error in
			guard let messageController = self.messageController else {
				return
			}

			if let url = item as? NSURL {
				if url.fileURL {
					messageController.addAttachmentURL(url, withAlternateFilename: nil)
				}

				else {
					var body: String = messageController.body != nil ? messageController.body! : ""
					body = body + " " + url.absoluteString!
					body = body.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
					messageController.body = body
				}
			}

			else if let text = item as? String {
				if let body = messageController.body where body.characters.count > 0 {
					messageController.body = body + " " + text
				}
				else {
					messageController.body = text
				}
			}

			else if let data = item as? NSData, let ext = UTTypeCopyPreferredTagWithClass(typeIdentifier, kUTTagClassFilenameExtension)?.takeRetainedValue() {
				messageController.addAttachmentData(data, typeIdentifier: typeIdentifier as String, filename: "attachment.\(ext)")
			}
		})

		return true
	}

	// MARK: View life cycle

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		guard let context = self.extensionContext else {
			return
		}

		// We have to handle our "error" states here so we have a view to show our alerts on.

		guard let preferences = PreferencesManager.sharedManager else {
			let message = "Something went wrong while loading your preferences. Have another go in a minute or two."
			let alert = UIAlertController.alert(message, handler: { action in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}

		guard let messageRecipient = preferences.messageRecipient where messageRecipient.characters.count > 0 else {
			let message = "There's no recipient for messages selected in your preferences. You need to set it up in the app before using this extension."
			let alert = UIAlertController.alert(message, handler: { action in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}

		guard let messageController = self.messageController else {
			let message = "Either no items were available to share, or they're not supported. Sorry!"
			let alert = UIAlertController.alert(message, handler: { action in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			self.presentViewController(alert, animated: true, completion: nil)
			return
		}

		// If we got to here, we can go ahead and present the message controller

		self.presentViewController(messageController, animated: true, completion: nil)
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		PreferencesManager.sharedManager?.didFinishMessaging(result)
		controller.dismissViewControllerAnimated(true) {
			if let extensionContext = self.extensionContext {
				extensionContext.completeRequestReturningItems([], completionHandler: nil)
			}
		}
	}

}
