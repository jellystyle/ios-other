import UIKit
import StaticTables
import ContactsUI
import MessageUI

class MainViewController: UIViewController, MFMessageComposeViewControllerDelegate, IconViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    //! The collection view
    @IBOutlet weak var collectionView: UICollectionView?

	//! The position of the icon view
	@IBOutlet weak var iconViewTopConstraint: NSLayoutConstraint!

	//! The container view for inline messages
	@IBOutlet weak var messageContainer: UIView?

	//! The container view for inline messages
	@IBOutlet weak var messageLabel: UILabel?

    //! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.collectionView!.dataSource = self
        self.collectionView!.delegate = self
        self.view.addGestureRecognizer(self.collectionView!.panGestureRecognizer)
        
		if self.preferences?.contact == nil {
			self.performSegue(withIdentifier: "onboarding", sender: nil)
		}
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let preferences = self.preferences else {
            return
        }
        
        self.collectionView!.reloadData()
        
        preferences.addObserver(self, forKeyPath: "contact", options: [], context: nil)
        preferences.addObserver(self, forKeyPath: "messages", options: [], context: nil)
        preferences.addObserver(self, forKeyPath: "callRecipient", options: [], context: nil)
        preferences.addObserver(self, forKeyPath: "messageRecipient", options: [], context: nil)
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

        guard let preferences = self.preferences else {
            return
        }
        
		preferences.removeObserver(self, forKeyPath: "contact")
		preferences.removeObserver(self, forKeyPath: "messages")
		preferences.removeObserver(self, forKeyPath: "callRecipient")
		preferences.removeObserver(self, forKeyPath: "messageRecipient")
	}

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            // Reload the data here so the cells update their height correctly, otherwise the
            // contentInsets we use (in `tableView:heightForRowAtIndexPath:`) are incorrect.
            self.collectionView?.reloadData()
        }, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let iconViewController = segue.destination as? IconViewController {
            iconViewController.delegate = self
        }
    }

	// MARK: IBActions

	/// Displays a `UIContactViewController` for the current contact.
	@IBAction func displayContact() {
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

		let viewController = ContactViewController(for: fullContact)
		viewController.allowsEditing = false
        viewController.view.tintColor = PreferencesManager.tintColor
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPresented))
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        navigationController.navigationBar.tintColor = PreferencesManager.tintColor
        self.present(navigationController, animated: true, completion: nil)
	}
    
    @IBAction func dismissPresented() {
        self.presentedViewController?.dismiss(animated: true, completion: nil)
    }

	// MARK: Collection view

    func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let preferences = self.preferences, preferences.messageRecipient != nil else {
			self.messageLabel?.text = "You don't have a phone number or email selected for sending messages."
			self.messageContainer?.isHidden = false

			return 0
		}

		guard preferences.messages.count > 0 else {
			self.messageLabel?.text = "You don't have any message shortcuts specified."
			self.messageContainer?.isHidden = false

			return 0
		}

		self.messageLabel?.text = nil
		self.messageContainer?.isHidden = true

		return preferences.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! CollectionViewCell
        
        cell.text = self.preferences?.messages[indexPath.row]

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let message = self.preferences?.messages[indexPath.row] else {
            return
        }

        UIApplication.shared.openURL(URL.messageOther(with: message))

        collectionView.deselectItem(at: indexPath, animated: true)
	}
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewOffset = 0 - scrollView.contentOffset.y - scrollView.contentInset.top

        self.iconViewTopConstraint.constant = scrollViewOffset > 0 ? scrollViewOffset * (1/2) : scrollViewOffset

        self.updateGradientForVisibleCells()
    }
    
    fileprivate func updateGradientForVisibleCells() {
        for cell in self.collectionView?.visibleCells.flatMap({ $0 as? CollectionViewCell }) ?? [] {
            cell.updateGradient()
        }
    }
    
    // MARK: Message compose view delegate
    
	func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
		PreferencesManager.sharedManager?.didFinishMessaging(result)
		controller.dismiss(animated: true, completion: nil)
	}
    
    // MARK: Message compose view delegate
    
    func iconViewController(_ iconViewController: UIViewController, didRequestOpenURL url: URL) {
        UIApplication.shared.openURL(url)
    }

    // MARK: Key-value observing

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let keyPath = keyPath else {
			return
		}

		if keyPath == "contact" && self.preferences?.contact == nil {
			self.performSegue(withIdentifier: "onboarding", sender: nil)
		}

		else if keyPath == "callRecipient" || keyPath == "messageRecipient" || keyPath == "messages" {
			self.collectionView?.reloadData()
		}
	}

    class ContactViewController: CNContactViewController {
        
        override var preferredStatusBarStyle : UIStatusBarStyle {
            return .default
        }
        
    }

}
