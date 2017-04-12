import UIKit
import MessageUI
import ContactsUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	//! The main window.
	var window: UIWindow?

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		AppStoreManager.sharedManager?.fetchNumberOfUserRatings()
		return true
	}
    
    /// Present a view controller to display contact details
    fileprivate func _displayContact() {
        guard let contact = self.preferences?.contact else {
            return
        }
        
        let fullContact: CNContact
        do {
            let store = CNContactStore()
            fullContact = try store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
        } catch {
            return
        }
        
        let viewController = CNContactViewController(for: fullContact)
        viewController.allowsEditing = false
        viewController.view.tintColor = PreferencesManager.tintColor
        
        self._present(viewController)
    }
    
    /// Present a view controller to edit and send a message
    fileprivate func _composeMessage(with body: String?) {
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
    fileprivate var _animateTransitions: Bool {
        return UIApplication.shared.applicationState == .active
    }
    
    // Present a given view controller
    fileprivate func _present(_ viewController: UIViewController) {
        guard let rootViewController = self.window?.rootViewController else {
            return
        }
        
        self._dismissPresented { [unowned self] in
            if viewController is UINavigationController {
                rootViewController.present(viewController, animated: self._animateTransitions, completion: nil)
            }
            
            else {
                viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self._dismiss))
                
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.modalPresentationStyle = .formSheet
                navigationController.navigationBar.tintColor = PreferencesManager.tintColor
                rootViewController.present(navigationController, animated: self._animateTransitions, completion: nil)
            }
        }
    }

    // Dismiss any presented view controllers
    fileprivate func _dismissPresented(_ completion: (() -> Void)?) {
        guard let rootViewController = self.window?.rootViewController, rootViewController.presentedViewController != nil else {
            completion?()
            
            return
        }

        rootViewController.dismiss(animated: self._animateTransitions, completion: completion)
    }

    @objc fileprivate func _dismiss() {
        self._dismissPresented(nil)
    }

}

// MARK: URL Schemes

extension AppDelegate {

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        guard url.scheme == "my-other" else {
            return false
        }
        
        if url.path == "/contact" {
            self._displayContact()
            
            return true
        }
        
        else if url.path == "/message" {
            let body = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.filter { $0.name == "body" }.flatMap { $0.value }.first

            self._composeMessage(with: body)
            
            return true
        }
        
        return false
    }

}

// MARK: Shortcut Items

extension AppDelegate {
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "message-shortcut" {
            self._composeMessage(with: shortcutItem.localizedTitle)
        }
    }
    
}

// MARK: Message compose view controller delegate

extension AppDelegate: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.preferences?.didFinishMessaging(result)
        controller.dismiss(animated: self._animateTransitions, completion: nil)
	}

}

