import UIKit
import MessageUI
import ContactsUI

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

        guard rootViewController.presentedViewController != nil else {
            self._handleShortcutItem(shortcutItem)
            
            return
        }
        
        rootViewController.dismissViewControllerAnimated(false, completion: {
            self._handleShortcutItem(shortcutItem)
        })
	}
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        guard url.scheme == "my-other" else {
            return false
        }
        
        if url.path == "/contact" {
            guard let rootViewController = self.window?.rootViewController else {
                return false
            }
            
            guard rootViewController.presentedViewController != nil else {
                self._displayContact()
                
                return true
            }
            
            rootViewController.dismissViewControllerAnimated(false, completion: {
                self._displayContact()
            })
            
            return true
        }

        return false
    }

    /// Present the contact view controller
    private func _displayContact() {
        guard let rootViewController = self.window?.rootViewController, let contact = self.preferences?.contact else {
            return
        }
        
        let fullContact: CNContact
        do {
            let store = CNContactStore()
            fullContact = try store.unifiedContactWithIdentifier(contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        } catch {
            return
        }
        
        let viewController = CNContactViewController(forContact: fullContact)
        viewController.allowsEditing = false
        viewController.view.tintColor = PreferencesManager.tintColor
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(_dismissPresented))
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .FormSheet
        navigationController.navigationBar.tintColor = PreferencesManager.tintColor
        rootViewController.presentViewController(navigationController, animated: false, completion: nil)
    }
    
    /// Perform the appropriate action for the given shortcut item
    private func _handleShortcutItem(shortcutItem: UIApplicationShortcutItem) {
        guard let rootViewController = self.window?.rootViewController else {
            return
        }
        
        if shortcutItem.type == "message-shortcut" {
            guard let messageRecipient = self.preferences?.messageRecipient else {
                return
            }
            
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self
            messageController.recipients = [messageRecipient]
            messageController.body = shortcutItem.localizedTitle
            rootViewController.presentViewController(messageController, animated: false, completion: nil)
        }
    }
    
    @objc private func _dismissPresented() {
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

}

