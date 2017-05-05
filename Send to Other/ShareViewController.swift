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

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.initialize()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}

	fileprivate func initialize() {
		self.modalPresentationStyle = .overFullScreen
	}

	// MARK: View life cycle

	var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = UIColor.clear
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.handleExtensionRequest()
	}

	fileprivate var handling = false
	
	fileprivate func handleExtensionRequest() {
		guard let context = self.extensionContext else {
			return
		}

		DispatchQueue.main.async {
			guard self.handling == false else {
				return
			}

			self.handling = true

			guard let preferences = PreferencesManager.sharedManager else {
				let message = "Something went wrong while loading your preferences. Have another go in a minute or two."
				let alert = UIAlertController.alert(message, handler: { action in
					context.completeRequest(returningItems: [], completionHandler: nil)
				})
				self.present(alert, animated: true, completion: nil)
				return
			}

			guard let messageRecipient = preferences.messageRecipient, messageRecipient.characters.count > 0 else {
				let message = "There's no recipient for messages selected in your preferences. You need to set it up in the app before using this extension."
				let alert = UIAlertController.alert(message, handler: { action in
					context.completeRequest(returningItems: [], completionHandler: nil)
				})
				self.present(alert, animated: true, completion: nil)
				return
			}

			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]

			DispatchQueue.global(qos: .userInitiated).async {
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

							itemProvider.loadItem(forTypeIdentifier: typeIdentifier as String, options: nil, completionHandler: { item, error in
								print("[ShareViewController] Load complete.")

								if item == nil {
									print("[ShareViewController] Nothing to attach?")
								}
								else if let url = item as? URL, url.isFileURL {
									let filename = url.lastPathComponent

									// To bypass an issue with MFMessageComposeViewController, photos and videos attached using file URLs
									// are displayed as a black preview (even though they send fine), we load and attach the data instead. This
									// works fine unless the data causes the memory constraints for the extension (causing it to crash), so we
									// only do so for photos, and just accept the downside for videos for now.

									if UTTypeConformsTo(typeIdentifier, kUTTypeImage), let data = try? Data(contentsOf: url) {
										print("[ShareViewController] Attaching as file data…")
										messageController.addAttachmentData(data, typeIdentifier: typeIdentifier as String, filename: filename)
									}
									else {
										print("[ShareViewController] Attaching as url…")
										messageController.addAttachmentURL(url, withAlternateFilename: filename)
									}
								}
								else if let url = item as? URL {
									let text = url.absoluteString
									print("[ShareViewController] Attaching as text…")
                                    let body = [messageController.body, text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)].flatMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
									messageController.body = body
								}
								else if let text = item as? String {
									print("[ShareViewController] Attaching as text…")
                                    let body = [messageController.body, text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)].flatMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                                    messageController.body = body
								}
								else if let data = item as? Data, let ext = UTTypeCopyPreferredTagWithClass(typeIdentifier, kUTTagClassFilenameExtension)?.takeRetainedValue() {
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

				DispatchQueue.main.async {
					guard numberOfAttachments > 0 else {
						let message = "Either no items were available to share, or they're not supported. Sorry!"
						let alert = UIAlertController.alert(message, handler: { action in
							context.completeRequest(returningItems: [], completionHandler: nil)
						})

						self.present(alert, animated: true, completion: nil)

						return
					}

					self.present(messageController, animated: true, completion: nil)
				}
			}
		}
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
		print("[ShareViewController] Did finish messaging…")

		PreferencesManager.sharedManager?.didFinishMessaging(result)

		controller.dismiss(animated: true) {
			if let extensionContext = self.extensionContext {
				extensionContext.completeRequest(returningItems: [], completionHandler: nil)
			}
		}
	}

}
