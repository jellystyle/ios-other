import UIKit
import StaticTables
import ContactsUI
import MessageUI

class MainViewController: JSMStaticTableViewController, MFMessageComposeViewControllerDelegate, IconViewControllerDelegate {

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	//! The section used by the data source.
	let section = JSMStaticSection()

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.dataSource.addSection(self.section);

		if self.preferences?.contact == nil {
			self.performSegueWithIdentifier("onboarding", sender: nil)
		}
	}

	override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
		guard let preferences = self.preferences else {
			return
		}

		self._updateShortcutsSection()

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

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		self._calculateRowHeight()
	}

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({ context in
            // Reload the data here so the cells update their height correctly, otherwise the
            // contentInsets we use (in `tableView:heightForRowAtIndexPath:`) are incorrect.
			self._calculateRowHeight()
            self.tableView.reloadData()
        }, completion: nil)
    }

	var rowHeight: CGFloat = 0

	private func _calculateRowHeight() {
		let numberOfRows: CGFloat = CGFloat(self.section.numberOfRows)
		let tableViewHeight = tableView.frame.size.height  - tableView.contentInset.top - tableView.contentInset.bottom

		self.rowHeight = max( 80, tableViewHeight / numberOfRows )

		let overflows = ( self.rowHeight * numberOfRows > tableViewHeight )

		self.tableView.scrollEnabled = overflows
		self.tableView.bounces = overflows
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

	// MARK: Table view delegate

    private lazy var iconViewController: IconViewController = {
        let iconViewController = IconViewController()
        iconViewController.delegate = self
        return iconViewController
    }()
    
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return self.rowHeight
	}

	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.preservesSuperviewLayoutMargins = false
		cell.layoutMargins = UIEdgeInsetsZero
		cell.separatorInset = UIEdgeInsetsZero
        
        if let row = (tableView.dataSource as? JSMStaticDataSource)?.rowAtIndexPath(indexPath) where (row.key as? String) == "__icons" {
            self.addChildViewController(self.iconViewController)
            cell.contentView.addSubview(self.iconViewController.view)
            
            self.iconViewController.view.anchor(toAllSidesOf: cell.contentView, maximumWidth: 400)
        }
	}
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let row = (tableView.dataSource as? JSMStaticDataSource)?.rowAtIndexPath(indexPath) where (row.key as? String) == "__icons" {
            self.iconViewController.view.removeFromSuperview()
            self.iconViewController.removeFromParentViewController()
        }
    }

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let row = self.dataSource.rowAtIndexPath(indexPath) else {
			return
		}

        if let messageRecipient = self.preferences?.messageRecipient {
			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]
			messageController.body = row.text
			self.navigationController?.presentViewController(messageController, animated: true, completion: nil)
		}

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
			self._updateShortcutsSection()
		}
	}

    // MARK: Utilities
    
    private func _updateShortcutsSection() {
		self.section.removeAllRows()

		guard let preferences = self.preferences else {
			return
		}
        
        if preferences.contact != nil {
            let row = JSMStaticRow(key: "__icons")
            row.selectionStyle = .None
            row.style = .Default
            row.configurationForCell { row, cell in
                cell.backgroundColor = self.tableView.backgroundColor
            }
            self.section.addRow(row)
        }

        if let recipient = preferences.messageRecipient where recipient.characters.count > 0 {
            for message in preferences.messages {
				let row = self._row(message, key: message)
				self.section.addRow(row)
			}
        }

		self._calculateRowHeight()
		self.tableView.reloadData()
	}

	/// Generate a `JSMStaticRow` instance for a message.
	/// @param text The text to be used for the cell's `textLabel`
	/// @param key Unique-ish identifier for the row.
	/// @return The generated row for addition to the data source.
    private func _row(text: String, key: String) -> JSMStaticRow {
        let row = JSMStaticRow(key: key)
        row.style = .Default
        row.text = text
        row.configurationForCell { row, cell in
			cell.backgroundColor = self.tableView.backgroundColor
			cell.textLabel?.font = UIFont.systemFontOfSize(30);
            cell.textLabel?.textAlignment = .Center
			cell.textLabel?.textColor = PreferencesManager.tintColor
        }
        return row
    }

    class ContactViewController: CNContactViewController {
        
        override func preferredStatusBarStyle() -> UIStatusBarStyle {
            return .Default
        }
        
    }

}
