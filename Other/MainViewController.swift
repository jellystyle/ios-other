import UIKit
import StaticTables
import ContactsUI
import MessageUI

class MainViewController: JSMStaticTableViewController, MFMessageComposeViewControllerDelegate {

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
		guard let preferences = self.preferences else {
			return
		}

		if preferences.contactHasThumbnail {
            let icon: UIImage
            if let thumbnail = preferences.contactThumbnail(25, stroke: 1) {
                icon = thumbnail
            }
            else {
                icon = UIImage(named: "contact")!
            }
			if let item = self.navigationItem.rightBarButtonItem, let target = item.target {
				self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .Plain, target: target, action: item.action)
			}
        }

		if preferences.contact != nil {
			self.navigationItem.rightBarButtonItem?.enabled = true
		}

		self._updateShortcutsSection()

		self.preferences?.addObserver(self, forKeyPath: "contact", options: [], context: nil)
		self.preferences?.addObserver(self, forKeyPath: "messages", options: [], context: nil)
		self.preferences?.addObserver(self, forKeyPath: "callRecipient", options: [], context: nil)
		self.preferences?.addObserver(self, forKeyPath: "messageRecipient", options: [], context: nil)
	}

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

		self.preferences?.removeObserver(self, forKeyPath: "contact")
		self.preferences?.removeObserver(self, forKeyPath: "messages")
		self.preferences?.removeObserver(self, forKeyPath: "callRecipient")
		self.preferences?.removeObserver(self, forKeyPath: "messageRecipient")
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

		let viewController = CNContactViewController(forContact: fullContact)
		viewController.allowsEditing = false
		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return self.rowHeight
	}

	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.preservesSuperviewLayoutMargins = false
		cell.layoutMargins = UIEdgeInsetsZero
		cell.separatorInset = UIEdgeInsetsZero
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let row = self.dataSource.rowAtIndexPath(indexPath) else {
			return
		}

		guard let preferences = self.preferences else {
			return
		}

		if let callURL = preferences.callURL where row.key as? String == "__call" {
			UIApplication.sharedApplication().openURL(callURL)
			PreferencesManager.sharedManager?.didStartCall()
		}

		else if let messageURL = preferences.messageURL where row.key as? String == "__message" {
			UIApplication.sharedApplication().openURL(messageURL)
			PreferencesManager.sharedManager?.didOpenMessages()
		}

		else if let messageRecipient = preferences.messageRecipient {
			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]
			messageController.body = row.text
			self.navigationController?.presentViewController(messageController, animated: true, completion: nil)
		}

		// Clear the selection
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		PreferencesManager.sharedManager?.didFinishMessaging(result)
		controller.dismissViewControllerAnimated(true, completion: nil)
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

		if let recipient = preferences.callRecipient where recipient.characters.count > 0 {
			let row = self._row("Call", key: "__call")
			self.section.addRow(row)
		}

		if let recipient = preferences.messageRecipient where recipient.characters.count > 0 {
			let row = self._row("Message", key: "__message")
			self.section.addRow(row)

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

}
