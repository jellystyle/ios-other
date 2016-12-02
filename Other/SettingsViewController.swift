import UIKit
import StaticTables
import Sherpa
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

		self._updateView()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self._updateView()
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
				viewController.modalPresentationStyle = .FormSheet
				self.presentViewController(viewController, animated: true, completion: nil)

			}
			else if row.key as? String == "add-message", let section = row.section {

				let empty = self._rowForMessage(nil, key: String(indexPath.row))
                dataSource.insertRow(empty, intoSection: section, atIndex: UInt(indexPath.row), withRowAnimation: UITableViewRowAnimation.Bottom)
				empty.textField?.becomeFirstResponder()

			}
			else if row.key as? String == "support.guide", let url = NSBundle.mainBundle().URLForResource("userguide", withExtension: "json") {

				let viewController = SherpaViewController(fileAtURL: url)
				viewController.tintColor = PreferencesManager.tintColor
				viewController.articleTextColor = PreferencesManager.textColor
				viewController.articleBackgroundColor = PreferencesManager.backgroundColor
				self.navigationController?.pushViewController(viewController, animated: true)

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
			preferences.updateShortcutItems( UIApplication.sharedApplication() )
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

	override func dataSource(dataSource: JSMStaticDataSource, rowNeedsReload row: JSMStaticRow, atIndexPath indexPath: NSIndexPath) {
		// We don't need to reload the row, it gets reloaded when the view appears
	}

	override func dataSource(dataSource: JSMStaticDataSource, sectionNeedsReload section: JSMStaticSection, atIndex index: UInt) {
		// We don't need to reload the section, it gets reloaded when the view appears
	}

	override func dataSource(dataSource: JSMStaticDataSource, didMoveRow row: JSMStaticRow, fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
		self._saveMessages()
	}

	override func dataSource(dataSource: JSMStaticDataSource, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRow row: JSMStaticRow, atIndexPath indexPath: NSIndexPath) {
		if let tableView = dataSource.tableView where editingStyle == .Insert {
			self.tableView(tableView, didSelectRowAtIndexPath: indexPath)
		}

		else if editingStyle == .Delete {
			dataSource.removeRow(row, withRowAnimation: .Fade)
			self._saveMessages()
		}
	}

	// MARK: Static preference observer

	func preference(preference: JSMStaticPreference, didChangeValue value: AnyObject) {
		if let preferences = self.preferences {
            if let select = preference as? JSMStaticSelectPreference, let value = value as? String {
                
                if select.key as? String == "call-recipient" {
                    preferences.callRecipient = value
                }
                    
                else if select.key as? String == "message-recipient" {
                    preferences.messageRecipient = value
                }
                    
                else if select.key as? String == "facetime-recipient" {
                    preferences.facetimeRecipient = value
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
		var sections: [JSMStaticSection] = []

		let contact = self._contactSection()
		sections.append(contact)

		if let recipients = self._recipientSection() {
			sections.appendContentsOf(recipients)
		}

		if let messages = self._messagesSection() {
			sections.append(messages)
		}

		var support = JSMStaticSection(key: "support-1")
		support.headerText = NSBundle.mainBundle().displayName ?? "Other"
		sections.append(support)

		if let appStoreManager = AppStoreManager.sharedManager {
			let review = JSMStaticRow(key: "support.review")
			review.text = NSLocalizedString("Review on the App Store", comment: "Label for button to open the App Store to post a review")
			review.accessoryType = .None
			review.selectionStyle = .Default
			review.configurationForCell { row, cell in
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
			sections.append(support)
		}

		if NSBundle.mainBundle().URLForResource("userguide", withExtension: "json") != nil {
			let guide = JSMStaticRow(key: "support.guide")
			guide.text = "User Guide"
			guide.accessoryType = .DisclosureIndicator
			guide.selectionStyle = .Default
			guide.configurationForCell { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			support.addRow(guide)
		}

		let about = JSMStaticRow(key: "support.about")
		about.text = "About"
		about.accessoryType = .DisclosureIndicator
		about.selectionStyle = .Default
		about.configurationForCell({ row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		})
		support.addRow(about)

		self.dataSource.sections = sections
	}

	/// Refresh the contact section.
	private func _contactSection() -> JSMStaticSection {
		let section = JSMStaticSection(key: "contact")
		section.headerText = "Contact"

		if let preferences = self.preferences, let contact = preferences.contact {
			section.footerText = "This is your selected contact. You can tap at any time to select a different person from your address book."

			let contactRow = JSMStaticRow(key: "contact")
			contactRow.text = CNContactFormatter().stringFromContact(contact)
			contactRow.image = preferences.contactThumbnail(46, stroke: 1, edgeInsets: UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0))
			contactRow.configurationForCell { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			section.addRow(contactRow)
		}

		else {
			section.footerText = "You'll need to choose a contact to use Other for: someone you often send things to via Messages."

			let row = JSMStaticRow(key: "select-contact")
			row.text = "Select contact…"
			row.configurationForCell { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			section.addRow(row)
		}

		return section
	}

	/// Refresh the recipient section, removing if no contact is selected.
	private func _recipientSection() -> [JSMStaticSection]? {
		guard let preferences = self.preferences where preferences.contact != nil else {
			return nil
		}

        let sectionOne = JSMStaticSection(key: "recipients-one")
        sectionOne.footerText = "The phone number (or email address) used for composing texts, or for linking to the Messages app."

        let sectionTwo = JSMStaticSection(key: "recipients-two")
        sectionTwo.footerText = "Additional buttons can be enabled by selecting the number used for phone or FaceTime calls."

        // Message Recipient
        
        let messagePreference = JSMStaticSelectPreference.transientPreferenceWithKey("message-recipient")
        messagePreference.addObserver(self)
        sectionOne.addRow(messagePreference)
        
        var messageOptions: [[String: AnyObject]] = preferences.messageOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option]
        })
        messageOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""])
        
        messagePreference.text = "Messages"
        messagePreference.value = preferences.messageRecipient ?? ""
        messagePreference.options = messageOptions
        messagePreference.configurationForCell { row, cell in
            cell.textLabel?.textColor = PreferencesManager.tintColor
        }

		// Call Recipient

		let callPreference = JSMStaticSelectPreference.transientPreferenceWithKey("call-recipient")
		callPreference.addObserver(self)
		sectionTwo.addRow(callPreference)

        var callOptions: [[String: AnyObject]] = preferences.callOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option]
        })
        callOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""])

        callPreference.text = "Calls"
		callPreference.value = preferences.callRecipient ?? ""
		callPreference.options = callOptions
		callPreference.configurationForCell { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}

        // FaceTime Recipient
        
        let facetimePreference = JSMStaticSelectPreference.transientPreferenceWithKey("facetime-recipient")
        facetimePreference.addObserver(self)
        sectionTwo.addRow(facetimePreference)
        
        var facetimeOptions: [[String: AnyObject]] = preferences.facetimeOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option]
        })
        facetimeOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""])
        
        facetimePreference.text = "FaceTime"
        facetimePreference.value = preferences.facetimeRecipient ?? ""
        facetimePreference.options = facetimeOptions
        facetimePreference.configurationForCell { row, cell in
            cell.textLabel?.textColor = PreferencesManager.tintColor
        }

		return [sectionOne, sectionTwo]
	}

	/// Refresh the messages section, removing if no message recipient is selected.
	private func _messagesSection() -> JSMStaticSection? {
		guard let preferences = self.preferences, let recipient = preferences.messageRecipient where recipient.characters.count > 0 else {
			return nil
		}

		let section = JSMStaticSection(key: "messages")
		section.headerText = "Messages"
		if #available(iOS 9.1, *) {
			section.footerText = "Messages are shown as shortcut buttons within the app, and as 3D touch shortcuts on the home screen, providing a quick way to send messages you use regularly."
		}
		else {
			section.footerText = "Messages are shown as shortcut buttons within the app, providing a quick way to send messages you use regularly."
		}

		for message in preferences.messages {
			let row = self._rowForMessage(message, key: message)
			section.addRow(row)
		}

		let row = JSMStaticRow(key: "add-message")
		row.text = "Add Message"
		row.editingStyle = .Insert
		row.configurationForCell { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		section.addRow(row)

		return section
	}

	/// Generate a row for editing the content of a message.
	private func _rowForMessage(message: String?, key: String) -> JSMStaticTextPreference {
		let row = JSMStaticTextPreference.transientPreferenceWithKey(key)
		row.value = message
		row.textField?.placeholder = "Message Text"
		row.textField?.returnKeyType = .Done
		row.textField?.delegate = self
		row.canBeMoved = true
		row.editingStyle = .Delete
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
		if let preferences = self.preferences, let rows = self.dataSource.sectionWithKey("messages")?.rows {
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

			preferences.updateShortcutItems( UIApplication.sharedApplication() )
		}
		else {
			let message = "There was a problem with saving your messages. Maybe you can give it another shot?"
			let alert = UIAlertController.alert(message)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

}
