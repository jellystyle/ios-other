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

		let messagesSection = JSMStaticSection(key: "messages")
		messagesSection.headerText = "Messages"
		self.dataSource.addSection(messagesSection)

		self.updateView()

	}

	func updateView() {

		let preferences = PreferencesManager(suiteName: "group.com.jellystyle.Melissa")

		if let section = self.dataSource.sectionWithKey("contact") {
			section.removeAllRows();

			if let contact = preferences?.contact {

				let contactRow = JSMStaticRow(key: "contact")
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
				section.addRow(contactRow)

				let recipientSection = JSMStaticSection(key: "contact-2")
				self.dataSource.insertSection(recipientSection, atIndex: self.dataSource.indexForSection(section) + 1)

				let callRow = JSMStaticSelectPreference.transientPreferenceWithKey("call-recipient")
				callRow.text = "Calls"
				callRow.value = preferences!.callRecipient
				callRow.options = preferences!.callOptions.map({
					(labelledValue) in
					if let phoneNumber = labelledValue.value as? CNPhoneNumber {
						return [JSMStaticSelectOptionLabel: phoneNumber.stringValue, JSMStaticSelectOptionValue: phoneNumber.stringValue]
					}
					return [JSMStaticSelectOptionLabel: labelledValue.value, JSMStaticSelectOptionValue: labelledValue.value]
				})
				callRow.addObserver(self)
				recipientSection.addRow(callRow)

				let messageRow = JSMStaticSelectPreference.transientPreferenceWithKey("message-recipient")
				messageRow.text = "Messages"
				messageRow.value = preferences!.messageRecipient
				messageRow.options = preferences!.messageOptions.map({
					(labelledValue) in
					if let phoneNumber = labelledValue.value as? CNPhoneNumber {
						return [JSMStaticSelectOptionLabel: phoneNumber.stringValue, JSMStaticSelectOptionValue: phoneNumber.stringValue]
					}
					return [JSMStaticSelectOptionLabel: labelledValue.value, JSMStaticSelectOptionValue: labelledValue.value]
				})
				messageRow.addObserver(self)
				recipientSection.addRow(messageRow)
			}

			else {
				let row = JSMStaticRow(key: "select-contact")
				row.text = "Select contact…"
				row.configurationForCell {
					(row, cell) in
					cell.textLabel?.textColor = UIColor(red: 0, green: 0.506, blue: 0.83, alpha: 1)
				}
				section.addRow(row)

				self.dataSource.removeSection(self.dataSource.sectionWithKey("contact-2"))
			}

		}

		if let section = self.dataSource.sectionWithKey("messages") {
			section.removeAllRows();

			if let messages = preferences?.messages {
				for message in messages {

					let row = JSMStaticTextPreference.transientPreferenceWithKey(message)
					row.value = message
					row.textField?.placeholder = "Message Text"
					row.canBeMoved = true
					row.canBeDeleted = true
					row.fitControlToCell = true
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

	}

	// MARK: IBActions

	@IBAction func unwindToMain(segue: UIStoryboardSegue) {
		self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
	}

	// MARK: Table view delegate

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

		if let dataSource = tableView.dataSource as? JSMStaticDataSource {
			let row = dataSource.rowAtIndexPath(indexPath)
			if let row = row as? JSMStaticSelectPreference {
				self.navigationController?.pushViewController(row.viewController, animated: true)
			}
			else if (row.key as? String == "contact" || row.key as? String == "select-contact") {

				let viewController = CNContactPickerViewController()
				viewController.delegate = self
				viewController.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 || phoneNumbers.@count > 0")
				self.presentViewController(viewController, animated: true, completion: nil)

			}
			else if (row.key as? String == "add-message") {

				let empty = JSMStaticTextPreference(key: String(indexPath.row))
				empty.value = nil
				empty.textField?.placeholder = "Message Text"
				empty.canBeMoved = true
				empty.canBeDeleted = true
				empty.fitControlToCell = true
				empty.addObserver(self)

				dataSource.insertRow(empty, intoSection: row.section, atIndex: UInt(indexPath.row), withRowAnimation: UITableViewRowAnimation.Bottom)

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
		if let dataSource = tableView.dataSource as? JSMStaticDataSource {
			let row = dataSource.rowAtIndexPath(indexPath)
			if row.key as? String == "contact" {
				return 60
			}
		}
		return 44
	}

	// MARK: Contact picker delegate

	func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
		if let preferences = self.preferences {
			preferences.contact = contact
			self.updateView()
			self.tableView.reloadData()
		}

		else {
			self._showMessage("An error occurred while updating your selected contact. Can you give it another try in a moment?")
		}
	}

	// MARK: Static data source delegate

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
	}

	// MARK: Utilities

	private func _updateMessagesInUserDefaults() {
		if let preferences = self.preferences, let rows = self.dataSource?.sectionWithKey("messages")?.rows {
			let filteredRows = rows.filter() {
				($0 as? JSMStaticTextPreference)?.value != nil
			} as! [JSMStaticTextPreference]
			let messages = filteredRows.map() {
				$0.value
			} as! [String]
			preferences.messages = messages
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
