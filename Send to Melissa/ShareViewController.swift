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

		var items = 0
		for item in context.inputItems as! [NSExtensionItem] {
			for itemProvider in item.attachments as! [NSItemProvider] {

				if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeFileURL) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeURL) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeImage) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeAudiovisualContent) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeText) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypePDF) {
					items += 1
				}
				else if self.attemptToHandle(itemProvider, typeIdentifier: kUTTypeVCard) {
					items += 1
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

		itemProvider.loadItemForTypeIdentifier(typeIdentifier as String, options: nil, completionHandler: {
			(item, error) -> Void in
			guard let messageController = self.messageController, url = item as? NSURL else {
				return
			}

			if url.fileURL {
				messageController.addAttachmentURL(url, withAlternateFilename: nil)
			}
			else {
				var body: String = messageController.body != nil ? messageController.body! : ""
				body = body + " " + url.absoluteString
				body = body.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
				messageController.body = body
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
			self._showMessage("Something went wrong while loading your preferences. Have another go in a minute or two.", handler: {
				(action) in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			return
		}

		guard let messageRecipient = preferences.messageRecipient where messageRecipient.characters.count > 0 else {
			self._showMessage("There's no recipient for messages selected in your preferences. You need to set it up in the app before using this extension.", handler: {
				(action) in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			return
		}

		guard let messageController = self.messageController else {
			self._showMessage("Either no items were available to share, or they're not supported. Sorry!", handler: {
				(action) in
				context.completeRequestReturningItems([], completionHandler: nil)
			})
			return
		}

		// If we got to here, we can go ahead and present the message controller

		self.presentViewController(messageController, animated: true, completion: nil)
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		controller.dismissViewControllerAnimated(true) {
			if let extensionContext = self.extensionContext {
				extensionContext.completeRequestReturningItems([], completionHandler: nil)
			}
		}
	}

	// MARK: Utilities

	/// Displays a `UIAlertController` with the given `message`.
	/// @param message The text to be displayed to the user.
	/// @param handler The function to be run when the user taps the "OK" button (defaults to `nil`).
	private func _showMessage(message: String, handler: ((UIAlertAction) -> Void)? = nil) {
		let title = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as! String
		let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: handler))
		self.presentViewController(alert, animated: true, completion: nil)
	}

}
