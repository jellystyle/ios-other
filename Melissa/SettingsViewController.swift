import UIKit
import StaticTables
import ContactsUI
import ImageIO

class SettingsViewController: JSMStaticTableViewController, JSMStaticPreferenceObserver, CNContactPickerDelegate {

	//! Link to the shared `PreferencesManager` for storage
	let preferences = PreferencesManager(suiteName: "group.com.jellystyle.Melissa")

	// MARK: View life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.editing = true
		self.tableView.allowsSelectionDuringEditing = true

		let contactSection = JSMStaticSection(key: "contact")
		contactSection.headerText = "Contact"
		self.dataSource.addSection(contactSection)

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

				let empty = JSMStaticTextPreference(key: String(indexPath.row))
				empty.value = nil
				empty.textField?.placeholder = "Message Text"
				empty.textField?.returnKeyType = .Done
				empty.canBeMoved = true
				empty.canBeDeleted = true
				empty.fitControlToCell = true
                empty.configurationForCell {
                    row, cell in
                    if let preference = row as? JSMStaticTextPreference, let font = cell.textLabel?.font {
                        preference.textField?.font = font
                    }
                }
                empty.addObserver(self)

                dataSource.insertRow(empty, intoSection: row.section, atIndex: UInt(indexPath.row), withRowAnimation: UITableViewRowAnimation.Bottom)
				empty.textField?.becomeFirstResponder()

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
			self._showMessage("An error occurred while updating your selected contact. Can you give it another try in a moment?")
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
		self._updateMessagesInUserDefaults()
	}

	override func dataSource(dataSource: JSMStaticDataSource!, didDeleteRow row: JSMStaticRow!, fromIndexPath indexPath: NSIndexPath!) {
		self._updateMessagesInUserDefaults()
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
					self._updateMessagesInUserDefaults()
				}

			}
		}
		else {
			self._showMessage("Something went wrong while updating your preferences. Try again in a minute or three.")
		}

        self._updateView()
	}

	// MARK: Utilities

	private func _updateView() {
		self._updateContactSection()
		self._updateRecipientSection()
		self._updateMessagesSection()
	}

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
				row.configurationForCell {
					(row, cell) in
					cell.textLabel?.textColor = UIColor(red: 0, green: 0.506, blue: 0.83, alpha: 1)
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

		if let imageData = contact.thumbnailImageData, let image = UIImage(data: imageData) {
			let source = image.CGImage
			let scale = UIScreen.mainScreen().scale

			let size = 44 * scale

			let context = CGBitmapContextCreate(nil, Int(size), Int(size), CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), CGImageGetBitmapInfo(source).rawValue)

			let percent = size / min(image.size.width * image.scale, image.size.height * image.scale)
			let s = CGSize(width: image.size.width * image.scale * percent, height: image.size.height * image.scale * percent)
			let o = CGPoint(x: ((s.width - size) / 2), y: ((s.height - size) / 2))
			CGContextDrawImage(context, CGRect(origin: o, size: s), source)

			if let imageRef = CGBitmapContextCreateImage(context) {
				contactRow.image = UIImage(CGImage: imageRef, scale: scale, orientation: image.imageOrientation)
			}
		}

		let formatter = CNContactFormatter()
		contactRow.text = formatter.stringFromContact(contact)
		contactRow.configurationForCell {
			(row, cell) in
			if let imageView = cell.imageView, let image = row.image {
				imageView.layer.cornerRadius = image.size.width / 2
				imageView.layer.masksToBounds = true
			}
		}

		section.footerText = "This is your selected contact. You can tap at any time to select a different person from your address book."
	}

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
}

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
            section.footerText = "Messages are shown as shortcut buttons within the app, providing a quick way to send messages you use regularly."
            self.dataSource.insertSection(section, atIndex: 2)
        }

        if let messages = self.preferences?.messages {
			for message in messages {
				let row = JSMStaticTextPreference.transientPreferenceWithKey(message)
				row.value = message
				row.textField?.placeholder = "Message Text"
				row.textField?.returnKeyType = .Done
				row.canBeMoved = true
				row.canBeDeleted = true
				row.fitControlToCell = true
                row.configurationForCell {
                    row, cell in
                    if let preference = row as? JSMStaticTextPreference, let font = cell.textLabel?.font {
                        preference.textField?.font = font
                    }
                }
                row.addObserver(self)
				section.addRow(row)
			}
		}

		let row = JSMStaticRow(key: "add-message")
		row.text = "Add Message"
		row.canBeDeleted = true
		row.configurationForCell {
			(row, cell) in
			cell.textLabel?.textColor = UIColor(red: 0, green: 0.506, blue: 0.83, alpha: 1)
		}
		section.addRow(row)
	}

	private func _updateMessagesInUserDefaults() {
		if let preferences = self.preferences, let rows = self.dataSource?.sectionWithKey("messages")?.rows {

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

		}
		else {
			self._showMessage("There was a problem with saving your messages. Maybe you can give it another shot?")
		}
	}

	private func _showMessage(message: String, handler: ((UIAlertAction) -> Void)? = nil) {
		let title = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleDisplayName") as! String
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: handler))
		self.presentViewController(alertController, animated: true, completion: nil)
	}

}
