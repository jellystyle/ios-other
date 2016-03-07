import UIKit
import MessageUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MFMessageComposeViewControllerDelegate {

	//! The main window.
	var window: UIWindow?

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		AppStoreManager.sharedManager?.fetchNumberOfUserRatings()
		return true
	}

	// MARK: - Shortcut Items

	func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
		guard let rootViewController = self.window?.rootViewController else {
			return
		}

		if rootViewController.presentedViewController != nil {

			rootViewController.dismissViewControllerAnimated(false, completion: {
				self._handleShortcutItem(shortcutItem)
			})

		}

		else {
			self._handleShortcutItem(shortcutItem)
		}
	}

	/// Perform the appropriate action for the given shortcut item
	private func _handleShortcutItem(shortcutItem: UIApplicationShortcutItem) {
		if shortcutItem.type == "message-shortcut" {
			guard let messageRecipient = self.preferences?.messageRecipient else {
				return
			}

			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]
			messageController.body = shortcutItem.localizedTitle
			self.window?.rootViewController?.presentViewController(messageController, animated: false, completion: nil)
		}
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

}

