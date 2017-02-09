import Foundation
import UIKit
import MessageUI
import MobileCoreServices

class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {

	//! The messages view controller used to present the shared items.
	var messageController: MFMessageComposeViewController?

	//! Valid UTIs in the preferred order of support.
	let typeIdentifiers = [
		kUTTypeFileURL,
		kUTTypeURL,
		kUTTypeJPEG,
		kUTTypeJPEG2000,
		kUTTypeTIFF,
		kUTTypePICT,
		kUTTypeGIF,
		kUTTypePNG,
		kUTTypeQuickTimeImage,
		kUTTypeAppleICNS,
		kUTTypeBMP,
		kUTTypeICO,
		kUTTypeImage,
		kUTTypeQuickTimeMovie,
		kUTTypeMPEG,
		kUTTypeMPEG4,
		kUTTypeMP3,
		kUTTypeMPEG4Audio,
		kUTTypeAppleProtectedMPEG4Audio,
		kUTTypeAudiovisualContent,
		kUTTypeText,
		kUTTypePDF,
		kUTTypeRTFD,
		kUTTypeVCard
	]

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.initialize()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}

	private func initialize() {
		self.modalPresentationStyle = .OverFullScreen
	}

	// MARK: View life cycle

	var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = UIColor.clearColor()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		self.handleExtensionRequest()
	}

	private var handling = false
	
	private func handleExtensionRequest() {
		guard let context = self.extensionContext else {
			return
		}

		dispatch_async(dispatch_get_main_queue()) {
			guard self.handling == false else {
				return
			}

			self.handling = true

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

			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
				var numberOfAttachments = 0

				print("[ShareViewController] Number of input items: \(context.inputItems.count)")

				for item in context.inputItems as? [NSExtensionItem] ?? [] {
					guard let attachments = item.attachments as? [NSItemProvider] else {
						continue
					}

					for itemProvider in attachments {
						print("[ShareViewController] Attempting to attach \(itemProvider)…")

						let beforeAttachment = numberOfAttachments

						for typeIdentifier in self.typeIdentifiers {
							if !itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier as String) {
								continue
							}

							print("[ShareViewController] Loading item for `\(typeIdentifier)`…")

							var finished = false

							itemProvider.loadItemForTypeIdentifier(typeIdentifier as String, options: nil, completionHandler: { item, error in
								print("[ShareViewController] Load complete.")

								if item == nil {
									print("[ShareViewController] Nothing to attach?")
								}
								else if let url = item as? NSURL where url.fileURL, let filename = url.lastPathComponent {

									// To bypass an issue with MFMessageComposeViewController where photos and videos attached using file URLs
									// are displayed as a black preview (even though they send fine), we load and attach the data instead. This
									// works fine unless the data causes the memory constraints for the extension (causing it to crash), so we
									// only do so for photos, and just accept the downside for videos for now.

									if UTTypeConformsTo(typeIdentifier, kUTTypeImage), let data = NSData(contentsOfURL: url) {
										print("[ShareViewController] Attaching as file data…")
										messageController.addAttachmentData(data, typeIdentifier: typeIdentifier as String, filename: filename)
									}
									else {
										print("[ShareViewController] Attaching as url…")
										messageController.addAttachmentURL(url, withAlternateFilename: filename)
									}
								}
								else if let url = item as? NSURL, let text = url.absoluteString {
									print("[ShareViewController] Attaching as text…")
									messageController.body = "\(messageController.body ?? "") \(text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))"
								}
								else if let text = item as? String {
									print("[ShareViewController] Attaching as text…")
									messageController.body = "\(messageController.body ?? "") \(text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))"
								}
								else if let data = item as? NSData, let ext = UTTypeCopyPreferredTagWithClass(typeIdentifier, kUTTagClassFilenameExtension)?.takeRetainedValue() {
									print("[ShareViewController] Attaching as data…")
									messageController.addAttachmentData(data, typeIdentifier: typeIdentifier as String, filename: "attachment.\(ext)")
								}
								else if let item = item {
									print("[ShareViewController] Unknown item provided: \(item)")
								}

								finished = true
							})

							while !finished {
								usleep(5000)
							}

							numberOfAttachments += 1

							break
						}

						if beforeAttachment == numberOfAttachments {
							print("[ShareViewController] Couldn't attach.")
						}
						else {
							print("[ShareViewController] Success!")
						}
					}
				}

				dispatch_async(dispatch_get_main_queue()) {
					guard numberOfAttachments > 0 else {
						let message = "Either no items were available to share, or they're not supported. Sorry!"
						let alert = UIAlertController.alert(message, handler: { action in
							context.completeRequestReturningItems([], completionHandler: nil)
						})

						self.presentViewController(alert, animated: true, completion: nil)

						return
					}

					self.presentViewController(messageController, animated: true, completion: nil)
				}
			}
		}
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		print("[ShareViewController] Did finish messaging…")

		PreferencesManager.sharedManager?.didFinishMessaging(result)

		controller.dismissViewControllerAnimated(true) {
			if let extensionContext = self.extensionContext {
				extensionContext.completeRequestReturningItems([], completionHandler: nil)
			}
		}
	}

}
