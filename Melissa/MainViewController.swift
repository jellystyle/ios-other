import UIKit
import StaticTables
import ContactsUI
import MessageUI

class MainViewController: JSMStaticTableViewController, MFMessageComposeViewControllerDelegate {

	let preferences = PreferencesManager(suiteName: "group.com.jellystyle.Melissa")

	let section = JSMStaticSection()

	var callRecipient: String?

	var messageRecipient: String?

	var messages: [String]?

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.dataSource.addSection(self.section);
	}

	override func viewWillAppear(animated: Bool) {
		self.section.removeAllRows()

		guard let preferences = self.preferences else {
			return
		}

		if let icon = preferences.contactThumbnail(25, stroke: 1) {
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .Plain, target: self, action: "displayContact:")
			self.navigationItem.rightBarButtonItem?.enabled = true
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

		self.tableView.reloadData()
	}

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        coordinator.animateAlongsideTransition({
            (context) in
            // Reload the data here so the cells update their height correctly, otherwise the
            // contentInsets we use (in `tableView:heightForRowAtIndexPath:`) are incorrect.
            self.tableView.reloadData()
        }, completion: nil)
    }

	// MARK: IBActions

	@IBAction func displayContact(sender: AnyObject) {
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
		let numberOfRows: CGFloat = CGFloat(self.section.numberOfRows)
		return ((tableView.frame.size.height - tableView.contentInset.top - tableView.contentInset.bottom) / numberOfRows)
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let row = self.dataSource.rowAtIndexPath(indexPath)
		let preferences = PreferencesManager(suiteName: "group.com.jellystyle.Melissa")

		if let callRecipient = preferences!.callRecipient where row.key as? String == "__call" {
			let telURL = NSURL(string: "tel:" + callRecipient)
			UIApplication.sharedApplication().openURL(telURL!)
		}

		else if let messageRecipient = preferences!.messageRecipient {
			let messageController = MFMessageComposeViewController()
			messageController.messageComposeDelegate = self
			messageController.recipients = [messageRecipient]

			if row.key as? String != "__message" {
				messageController.body = row.text
			}

			self.navigationController?.presentViewController(messageController, animated: true, completion: nil)
		}

		// Clear the selection
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	// MARK: Message compose view delegate

	func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}

    // MARK: Utilities

    private func _row(text: String, key: String, fontSize: CGFloat = 30) -> JSMStaticRow {
        let row = JSMStaticRow(key: key)
        row.style = .Default
        row.text = text
        row.configurationForCell {
            row, cell in
            cell.textLabel?.font = UIFont.systemFontOfSize(fontSize);
            cell.textLabel?.textAlignment = .Center
        }
        return row
    }

}
