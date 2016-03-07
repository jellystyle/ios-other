import UIKit
import StaticTables
import ContactsUI
import MessageUI
import ImageIO

class SettingsViewController: JSMStaticTableViewController, JSMStaticPreferenceObserver, CNContactPickerDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.editing = true
		self.tableView.allowsSelectionDuringEditing = true

		let contactSection = JSMStaticSection(key: "contact")
		contactSection.headerText = "Contact"
		self.dataSource.addSection(contactSection)

		var support = JSMStaticSection(key: "support-1")
		support.headerText = NSBundle.mainBundle().displayName ?? "Other"
		self.dataSource.addSection(support)

		if MFMailComposeViewController.canSendMail() {
			let feedback = JSMStaticRow(key: "support.feedback")
			feedback.text = NSLocalizedString("Send Feedback", comment: "Label for button to send feedback")
			feedback.configurationForCell { row, cell in
				cell.accessoryType = .None
				cell.selectionStyle = .Default
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			support.addRow(feedback)
		}

		if let appStoreManager = AppStoreManager.sharedManager {
			let review = JSMStaticRow(key: "support.review")
			review.text = NSLocalizedString("Review on the App Store", comment: "Label for button to open the App Store to post a review")
			review.configurationForCell { row, cell in
				cell.accessoryType = .None
				cell.selectionStyle = .Default
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			support.addRow(review)

			if let count = appStoreManager.numberOfUserRatings {
				if( count == 0 ) {
					support.footerText = "Be the first to rate this version!"
				}
				else {
					let formattedCount = NSNumberFormatter.localizedStringFromNumber(count, numberStyle: .DecimalStyle)
					if count <= 50 {
						support.footerText = "Only \(formattedCount) people have rated this version."
					}
					else {
						support.footerText = "\(formattedCount) people have rated this version."
					}
				}
			}
			else {
				support.footerText = "\(support.headerText) will never interrupt you for ratings."
			}

			support = JSMStaticSection(key: "support-2")
			self.dataSource.addSection(support)
		}

		let about = JSMStaticRow(key: "support.about")
		about.text = "About"
		about.configurationForCell({ row, cell in
			cell.accessoryType = .DisclosureIndicator
			cell.selectionStyle = .Default
			cell.textLabel?.textColor = PreferencesManager.tintColor
		})
		support.addRow(about)

		self._updateView()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}

	// MARK: IBActions

	@IBAction func unwindToMain(segue: UIStoryboardSegue) {
		self.view.endEditing(true)
		self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
	}

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		if let dataSource = tableView.dataSource as? JSMStaticDataSource, let row = dataSource.rowAtIndexPath(indexPath) {
			if let row = row as? JSMStaticSelectPreference {

				self.navigationController?.pushViewController(row.viewController, animated: true)

			}
			else if row.key as? String == "contact" || row.key as? String == "select-contact" {

				let viewController = CNContactPickerViewController()
				viewController.delegate = self
				viewController.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 || phoneNumbers.@count > 0")
				self.presentViewController(viewController, animated: true, completion: nil)

			}
			else if row.key as? String == "add-message" {

				let empty = self._rowForMessage(nil, key: String(indexPath.row))
                dataSource.insertRow(empty, intoSection: row.section, atIndex: UInt(indexPath.row), withRowAnimation: UITableViewRowAnimation.Bottom)
				empty.textField?.becomeFirstResponder()

			}
			else if row.key as? String == "support.feedback" {

				let appName = NSBundle.mainBundle().displayName ?? "Other"
				let appVersion = NSBundle.mainBundle().displayVersion ?? "(Unknown)"

				let viewController = MFMailComposeViewController()
				viewController.mailComposeDelegate = self
				viewController.setToRecipients(["JellyStyle Support <support@jellystyle.com>"])
				viewController.setSubject("\(appName) \(appVersion)")
				self.presentViewController(viewController, animated: true, completion: nil)

			}
			else if row.key as? String == "support.review", let appStoreManager = AppStoreManager.sharedManager {

				UIApplication.sharedApplication().openURL(appStoreManager.storeURL)

			}
			else if row.key as? String == "support.about" {

				let viewController = AboutViewController(style: .Grouped)
				self.navigationController?.pushViewController(viewController, animated: true)

			}
		}
	}

	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		if let dataSource = tableView.dataSource as? JSMStaticDataSource {
			let row = dataSource.rowAtIndexPath(indexPath)
			if row.key as? String == "add-message" {
				return UITableViewCellEditingStyle.Insert
			}
			else if row.canBeDeleted {
				return UITableViewCellEditingStyle.Delete
			}
		}

		return UITableViewCellEditingStyle.None
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if let dataSource = tableView.dataSource as? JSMStaticDataSource, let row = dataSource.rowAtIndexPath(indexPath) where row.key as? String == "contact" {
			return 60
		}
		return 44
	}

	// MARK: Contact picker delegate

	func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
		if let preferences = self.preferences {
			preferences.contact = contact
			self._updateView()
			self.tableView.reloadData()
		}

		else {
			let message = "An error occurred while updating your selected contact. Can you give it another try in a moment?"
			let alert = UIAlertController.alert(message)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

	// MARK: Static data source delegate

	override func dataSource(dataSource: JSMStaticDataSource!, rowNeedsReload row: JSMStaticRow!, atIndexPath indexPath: NSIndexPath!) {
		// We don't need to reload the row, it gets reloaded when the view appears
	}

	override func dataSource(dataSource: JSMStaticDataSource!, sectionNeedsReload section: JSMStaticSection!, atIndex index: UInt) {
		// We don't need to reload the section, it gets reloaded when the view appears
	}

	override func dataSource(dataSource: JSMStaticDataSource!, didMoveRow row: JSMStaticRow!, fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {
		self._saveMessages()
	}

	override func dataSource(dataSource: JSMStaticDataSource!, didDeleteRow row: JSMStaticRow!, fromIndexPath indexPath: NSIndexPath!) {
		self._saveMessages()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
	}

	// MARK: Static preference observer

	func preference(preference: JSMStaticPreference!, didChangeValue value: AnyObject!) {
		if let preferences = self.preferences {
			if let select = preference as? JSMStaticSelectPreference {

				if select.key as? String == "call-recipient" {
					preferences.callRecipient = select.value
				}

				else if select.key as? String == "message-recipient" {
					preferences.messageRecipient = select.value
				}

            }

			else if let text = preference as? JSMStaticTextPreference {

				if text.section?.key as? String == "messages" {
					self._saveMessages()
				}

			}
		}
		else {
			let message = "Something went wrong while updating your preferences. Try again in a minute or three."
			let alert = UIAlertController.alert(message)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

	// MARK: Text field delegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

	// MARK: Mail compose controller delegate

	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
    // MARK: Utilities

	/// Refresh the various sections in the data source.
	private func _updateView() {
		self._updateContactSection()
		self._updateRecipientSection()
		self._updateMessagesSection()
	}

	/// Refresh the contact section.
	private func _updateContactSection() {
		guard let section = self.dataSource.sectionWithKey("contact") else {
			return
		}

		// Remove sections

		guard let preferences = self.preferences, let contact = preferences.contact else {
			section.footerText = nil

			if section.rowWithKey("select-contact") == nil {
				let row = JSMStaticRow(key: "select-contact")
				row.text = "Select contact…"
				row.configurationForCell { row, cell in
					cell.textLabel?.textColor = PreferencesManager.tintColor
				}
				section.addRow(row)
			}

			if let recipients = self.dataSource.sectionWithKey("recipients") {
				self.dataSource.removeSection(recipients)
			}

			return
		}

		// Contact Row

		let contactRow: JSMStaticRow
		if section.rowWithKey("contact") != nil {
			contactRow = section.rowWithKey("contact")
		}
		else {
			contactRow = JSMStaticRow(key: "contact")
			section.addRow(contactRow)
		}

		let formatter = CNContactFormatter()
		contactRow.text = formatter.stringFromContact(contact)
		contactRow.image = preferences.contactThumbnail(46, stroke: 1, edgeInsets: UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0))
		contactRow.configurationForCell { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}

		section.footerText = "This is your selected contact. You can tap at any time to select a different person from your address book."
	}

	/// Refresh the recipient section, removing if no contact is selected.
	private func _updateRecipientSection() {
		guard let preferences = self.preferences, let _ = preferences.contact else {

			if let recipients = self.dataSource.sectionWithKey("recipients") {
				self.dataSource.removeSection(recipients)
			}

			return
		}

		let section: JSMStaticSection
		if self.dataSource.sectionWithKey("recipients") != nil {
			section = self.dataSource.sectionWithKey("recipients")
		}
		else {
			section = JSMStaticSection(key: "recipients")
			section.footerText = "Select the phone number (or email address) used for the call and message features. These are used when tapping a shortcut in the app, or when using the share extension to send images, links and other kinds of content."
			self.dataSource.insertSection(section, atIndex: 1)
		}

		// Call Recipient

		let callPreference: JSMStaticSelectPreference
		if section.rowWithKey("call-recipient") as? JSMStaticSelectPreference != nil {
			callPreference = section.rowWithKey("call-recipient") as! JSMStaticSelectPreference
		}
		else {
			callPreference = JSMStaticSelectPreference.transientPreferenceWithKey("call-recipient")
			callPreference.addObserver(self)
			section.addRow(callPreference)
		}

        var callOptions = preferences.callOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option]
        })
        callOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""])

        callPreference.text = "Calls"
		callPreference.value = preferences.callRecipient
        callPreference.options = callOptions
		callPreference.configurationForCell { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}

		// Message Recipient

		let messagePreference: JSMStaticSelectPreference
		if section.rowWithKey("message-recipient") as? JSMStaticSelectPreference != nil {
			messagePreference = section.rowWithKey("message-recipient") as! JSMStaticSelectPreference
		}
		else {
			messagePreference = JSMStaticSelectPreference.transientPreferenceWithKey("message-recipient")
			messagePreference.addObserver(self)
			section.addRow(messagePreference)
		}

        var messageOptions = preferences.messageOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option]
        })
        messageOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""])

		messagePreference.text = "Messages"
		messagePreference.value = preferences.messageRecipient
        messagePreference.options = messageOptions
		messagePreference.configurationForCell { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
	}

	/// Refresh the messages section, removing if no message recipient is selected.
	private func _updateMessagesSection() {
        guard let preferences = self.preferences, let recipient = preferences.messageRecipient where recipient.characters.count > 0 else {

            if let messages = self.dataSource.sectionWithKey("messages") {
                self.dataSource.removeSection(messages)
            }
            
            return
        }
        
        let section: JSMStaticSection
        if self.dataSource.sectionWithKey("messages") != nil {
            section = self.dataSource.sectionWithKey("messages")
            section.removeAllRows()
        }
        else {
            section = JSMStaticSection(key: "messages")
            section.headerText = "Messages"
			if #available(iOS 9.1, *) {
				section.footerText = "Messages are shown as shortcut buttons within the app, and as 3D touch shortcuts on the home screen, providing a quick way to send messages you use regularly."
			}
			else {
				section.footerText = "Messages are shown as shortcut buttons within the app, providing a quick way to send messages you use regularly."
			}
            self.dataSource.insertSection(section, atIndex: 2)
        }

		for message in preferences.messages {
			let row = self._rowForMessage(message, key: message)
			section.addRow(row)
		}

		let row = JSMStaticRow(key: "add-message")
		row.text = "Add Message"
		row.canBeDeleted = true
		row.configurationForCell {
			row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		section.addRow(row)
	}

	/// Generate a row for editing the content of a message.
	private func _rowForMessage(message: String?, key: String) -> JSMStaticTextPreference {
		let row = JSMStaticTextPreference.transientPreferenceWithKey(key)
		row.value = message
		row.textField?.placeholder = "Message Text"
		row.textField?.returnKeyType = .Done
		row.textField?.delegate = self
		row.canBeMoved = true
		row.canBeDeleted = true
		row.fitControlToCell = true
		row.configurationForCell { row, cell in
			if let preference = row as? JSMStaticTextPreference, let font = cell.textLabel?.font {
				preference.textField?.font = font
				preference.textField?.textColor = PreferencesManager.tintColor
			}
		}
		row.addObserver(self)
		return row
	}

	/// Generates a list of messages in the messages section, and saves them, using the PreferencesManager.
	private func _saveMessages() {
		if let preferences = self.preferences, let rows = self.dataSource?.sectionWithKey("messages")?.rows {

			print("Saving messages...")

			let values: [String?] = rows.map({
				(row) in
				guard let preference = row as? JSMStaticTextPreference else {
					return nil
				}

				guard let value = preference.value where value.characters.count > 0 else {
					return nil
				}

				return preference.value
			})

			preferences.messages = values.flatMap({ $0 })

			if #available(iOS 9.1, *) {
				var shortcutItems: [UIMutableApplicationShortcutItem] = []
				for message in preferences.messages {
					let item = UIMutableApplicationShortcutItem(type: "message-shortcut", localizedTitle: message)
					item.icon = UIApplicationShortcutIcon(type: .Compose)
					shortcutItems.append(item)
				}
				UIApplication.sharedApplication().shortcutItems = shortcutItems
			}
		}
		else {
			let message = "There was a problem with saving your messages. Maybe you can give it another shot?"
			let alert = UIAlertController.alert(message)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

}
