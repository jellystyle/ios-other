import UIKit
import MessageUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MFMessageComposeViewControllerDelegate {

	var window: UIWindow?

	let preferences = PreferencesManager.sharedManager

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		return true
	}

	// MARK: Shortcut Items

	func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
		guard let messageRecipient = self.preferences?.messageRecipient else {
			return
		}

		if shortcutItem.type == "message-shortcut" {
			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]
			messageController.body = shortcutItem.localizedTitle
			self.window?.rootViewController?.presentViewController(messageController, animated: true, completion: nil)
		}
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

}

