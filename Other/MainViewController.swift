import UIKit
import StaticTables
import ContactsUI
import MessageUI

class MainViewController: UIViewController, MFMessageComposeViewControllerDelegate, IconViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    //! The collection view
    @IBOutlet weak var collectionView: UICollectionView?

    //! The position of the icon view
    @IBOutlet weak var iconViewTopConstraint: NSLayoutConstraint!

    //! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.collectionView!.dataSource = self
        self.collectionView!.delegate = self
        
		if self.preferences?.contact == nil {
			self.performSegueWithIdentifier("onboarding", sender: nil)
		}
	}

    override func viewWillAppear(animated: Bool) {
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

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

        guard let preferences = self.preferences else {
            return
        }
        
		preferences.removeObserver(self, forKeyPath: "contact")
		preferences.removeObserver(self, forKeyPath: "messages")
		preferences.removeObserver(self, forKeyPath: "callRecipient")
		preferences.removeObserver(self, forKeyPath: "messageRecipient")
	}

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ context in
            // Reload the data here so the cells update their height correctly, otherwise the
            // contentInsets we use (in `tableView:heightForRowAtIndexPath:`) are incorrect.
            self.collectionView?.reloadData()
        }, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let iconViewController = segue.destinationViewController as? IconViewController {
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
			fullContact = try store.unifiedContactWithIdentifier(contact.identifier, keysToFetch: [CNContactViewController.descriptorForRequiredKeys()])
		} catch {
			return
		}

		let viewController = ContactViewController(forContact: fullContact)
		viewController.allowsEditing = false
        viewController.view.tintColor = PreferencesManager.tintColor
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(dismissPresented))
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .FormSheet
        navigationController.navigationBar.tintColor = PreferencesManager.tintColor
        self.presentViewController(navigationController, animated: true, completion: nil)
	}
    
    @IBAction func dismissPresented() {
        self.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

	// MARK: Collection view

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.preferences?.messages.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MessageCell", forIndexPath: indexPath) as! CollectionViewCell
        
        cell.text = self.preferences?.messages[indexPath.row]

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let message = self.preferences?.messages[indexPath.row] else {
            return
        }

        if let messageRecipient = self.preferences?.messageRecipient {
			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]
			messageController.body = message
			self.navigationController?.presentViewController(messageController, animated: true, completion: nil)
		}

        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
	}
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let scrollViewOffset = 0 - scrollView.contentOffset.y - scrollView.contentInset.top

        self.iconViewTopConstraint.constant = scrollViewOffset > 0 ? scrollViewOffset * (1/2) : scrollViewOffset

        self.updateGradientForVisibleCells()
    }
    
    private func updateGradientForVisibleCells() {
        for cell in self.collectionView?.visibleCells().flatMap({ $0 as? CollectionViewCell }) ?? [] {
            cell.updateGradient()
        }
    }
    
    // MARK: Message compose view delegate
    
	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		PreferencesManager.sharedManager?.didFinishMessaging(result)
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
    
    // MARK: Message compose view delegate
    
    func iconViewController(iconViewController: UIViewController, didRequestOpenURL url: NSURL) {
        if url.scheme == "my-other" && url.path?.hasPrefix("/contact") ?? false {
            self.displayContact()
            return
        }

        UIApplication.sharedApplication().openURL(url)
    }

    // MARK: Key-value observing

	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		guard let keyPath = keyPath else {
			return
		}

		if keyPath == "contact" && self.preferences?.contact == nil {
			self.performSegueWithIdentifier("onboarding", sender: nil)
		}

		else if keyPath == "callRecipient" || keyPath == "messageRecipient" || keyPath == "messages" {
			self.collectionView?.reloadData()
		}
	}

    class ContactViewController: CNContactViewController {
        
        override func preferredStatusBarStyle() -> UIStatusBarStyle {
            return .Default
        }
        
    }

}
