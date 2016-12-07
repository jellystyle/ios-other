import UIKit
import MessageUI
import ContactsUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	//! The main window.
	var window: UIWindow?

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		AppStoreManager.sharedManager?.fetchNumberOfUserRatings()
		return true
	}
    
    /// Present a view controller to display contact details
    private func _displayContact() {
        guard let contact = self.preferences?.contact else {
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
        
        self._present(viewController)
    }
    
    /// Present a view controller to edit and send a message
    private func _composeMessage(with body: String?) {
        guard let messageRecipient = self.preferences?.messageRecipient else {
            return
        }
        
        let messageController = MFMessageComposeViewController()
        messageController.messageComposeDelegate = self
        messageController.recipients = [messageRecipient]
        messageController.body = body
        
        self._present(messageController)
    }
    
    /// Animation of view controller presentations should be determine by the application's state.
    private var _animateTransitions: Bool {
        return UIApplication.sharedApplication().applicationState == .Active
    }
    
    // Present a given view controller
    private func _present(viewController: UIViewController) {
        guard let rootViewController = self.window?.rootViewController else {
            return
        }
        
        self._dismissPresented { [unowned self] in
            if viewController is UINavigationController {
                rootViewController.presentViewController(viewController, animated: self._animateTransitions, completion: nil)
            }
            
            else {
                viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self._dismiss))
                
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .FormSheet
                navigationController.navigationBar.tintColor = PreferencesManager.tintColor
                rootViewController.presentViewController(navigationController, animated: self._animateTransitions, completion: nil)
            }
        }
    }

    // Dismiss any presented view controllers
    private func _dismissPresented(completion: (() -> Void)?) {
        guard let rootViewController = self.window?.rootViewController where rootViewController.presentedViewController != nil else {
            completion?()
            
            return
        }

        rootViewController.dismissViewControllerAnimated(self._animateTransitions, completion: completion)
    }

    @objc private func _dismiss() {
        self._dismissPresented(nil)
    }

}

// MARK: URL Schemes

extension AppDelegate {

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        guard url.scheme == "my-other" else {
            return false
        }
        
        if url.path == "/contact" {
            self._displayContact()
            
            return true
        }
        
        else if url.path == "/message" {
            let body = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)?.queryItems?.filter { $0.name == "body" }.flatMap { $0.value }.first

            self._composeMessage(with: body)
            
            return true
        }
        
        return false
    }

}

// MARK: Shortcut Items

extension AppDelegate {
    
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        if shortcutItem.type == "message-shortcut" {
            self._composeMessage(with: shortcutItem.localizedTitle)
        }
    }
    
}

// MARK: Message compose view controller delegate

extension AppDelegate: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        self.preferences?.didFinishMessaging(result)
        controller.dismissViewControllerAnimated(self._animateTransitions, completion: nil)
	}

}

