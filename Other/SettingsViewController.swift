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

		self.tableView.isEditing = true
		self.tableView.allowsSelectionDuringEditing = true

		self._updateView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self._updateView()
		self.tableView.reloadData()
	}

	// MARK: IBActions

	@IBAction func selectContact() {
		let contactStore = CNContactStore()

		switch CNContactStore.authorizationStatus(for: .contacts) {
		case .restricted:
			let message = "Unable to access contacts, as this functionality has been restricted."
			let alertController = UIAlertController.alert(message)
			self.present(alertController, animated: true, completion: nil)

			break
		case .denied:
			let message = "To select a contact as your other, you will need to turn on access in Settings."
			let alertController = UIAlertController.alert(message, action: "Open Settings", handler: { _ in
				guard let url = URL(string: UIApplicationOpenSettingsURLString) else {
					return
				}

				UIApplication.shared.openURL(url)
			})
			self.present(alertController, animated: true, completion: nil)

			break
		case .notDetermined:
			contactStore.requestAccess(for: .contacts, completionHandler: { granted, error in
				DispatchQueue.main.async {
					self.selectContact()
				}
			})

			break
		case .authorized:
			let viewController = CNContactPickerViewController()
			viewController.delegate = self
			viewController.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 || phoneNumbers.@count > 0")
			viewController.modalPresentationStyle = .formSheet
			self.present(viewController, animated: true, completion: nil)

			break
		}
	}

	@IBAction func unwindToMain(_ segue: UIStoryboardSegue) {
		self.view.endEditing(true)
		self.navigationController?.dismiss(animated: true, completion: nil)
	}

	// MARK: Table view delegate

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		if let dataSource = tableView.dataSource as? JSMStaticDataSource, let row = dataSource.row(at: indexPath) {
			if let row = row as? JSMStaticSelectPreference {

				self.navigationController?.pushViewController(row.viewController, animated: true)

			}
			else if row.key as? String == "contact" || row.key as? String == "select-contact" {

				self.selectContact()

			}
			else if row.key as? String == "add-message", let section = row.section {

				let empty = self._rowForMessage(nil, key: String(indexPath.row))
                dataSource.insert(empty, into: section, at: UInt(indexPath.row), with: UITableViewRowAnimation.bottom)
				empty.textField?.becomeFirstResponder()

			}
			else if row.key as? String == "support.guide", let url = Bundle.main.url(forResource: "userguide", withExtension: "json") {

				let viewController = SherpaViewController(fileAtURL: url)
				viewController.tintColor = PreferencesManager.tintColor
				viewController.articleTextColor = PreferencesManager.textColor
				viewController.articleBackgroundColor = PreferencesManager.backgroundColor
				self.navigationController?.pushViewController(viewController, animated: true)

			}
			else if row.key as? String == "support.review", let appStoreManager = AppStoreManager.sharedManager {

				UIApplication.shared.openURL(appStoreManager.storeURL)

			}
			else if row.key as? String == "support.about" {

				let viewController = AboutViewController(style: .grouped)
				self.navigationController?.pushViewController(viewController, animated: true)

			}
		}
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if let dataSource = tableView.dataSource as? JSMStaticDataSource, let row = dataSource.row(at: indexPath), row.key as? String == "contact" {
			return 60
		}
		return 44
	}

	// MARK: Contact picker delegate

	func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
		if let preferences = self.preferences {
			preferences.contact = contact
			preferences.updateShortcutItems( UIApplication.shared )
			self._updateView()
			self.tableView.reloadData()
		}

		else {
			let message = "An error occurred while updating your selected contact. Can you give it another try in a moment?"
			let alert = UIAlertController.alert(message)
			self.present(alert, animated: true, completion: nil)
		}
	}

	// MARK: Static data source delegate

	override func dataSource(_ dataSource: JSMStaticDataSource, rowNeedsReload row: JSMStaticRow, at indexPath: IndexPath) {
		// We don't need to reload the row, it gets reloaded when the view appears
	}

	override func dataSource(_ dataSource: JSMStaticDataSource, sectionNeedsReload section: JSMStaticSection, at index: UInt) {
		// We don't need to reload the section, it gets reloaded when the view appears
	}

	override func dataSource(_ dataSource: JSMStaticDataSource, didMove row: JSMStaticRow, from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
		self._saveMessages()
	}

	override func dataSource(_ dataSource: JSMStaticDataSource, commit editingStyle: UITableViewCellEditingStyle, for row: JSMStaticRow, at indexPath: IndexPath) {
		if let tableView = dataSource.tableView, editingStyle == .insert {
			self.tableView(tableView, didSelectRowAt: indexPath)
		}

		else if editingStyle == .delete {
			dataSource.remove(row, with: .fade)
			self._saveMessages()
		}
	}

	// MARK: Static preference observer

	func preference(_ preference: JSMStaticPreference, didChangeValue value: Any) {
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
			self.present(alert, animated: true, completion: nil)
		}
	}

	// MARK: Text field delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

	// MARK: Mail compose controller delegate

	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
	
    // MARK: Utilities

	/// Refresh the various sections in the data source.
	fileprivate func _updateView() {
		var sections: [JSMStaticSection] = []

		let contact = self._contactSection()
		sections.append(contact)

		if let recipients = self._recipientSection() {
			sections.append(contentsOf: recipients)
		}

		if let messages = self._messagesSection() {
			sections.append(messages)
		}

		var support = JSMStaticSection(key: "support-1")
		support.headerText = Bundle.main.displayName ?? "Other"
		sections.append(support)

		if let appStoreManager = AppStoreManager.sharedManager {
			let review = JSMStaticRow(key: "support.review")
			review.text = NSLocalizedString("Review on the App Store", comment: "Label for button to open the App Store to post a review")
			review.accessoryType = .none
			review.selectionStyle = .default
			review.configuration { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			support.addRow(review)

			if let count = appStoreManager.numberOfUserRatings {
				if( count == 0 ) {
					support.footerText = "Be the first to rate this version!"
				}
				else {
					let formattedCount = NumberFormatter.localizedString(from: NSNumber(value: count), number: .decimal)
					if count <= 50 {
						support.footerText = "Only \(formattedCount) people have rated this version."
					}
					else {
						support.footerText = "\(formattedCount) people have rated this version."
					}
				}
			}
			else {
				support.footerText = "\(support.headerText ?? "Other") will never interrupt you for ratings."
			}

			support = JSMStaticSection(key: "support-2")
			sections.append(support)
		}

		if Bundle.main.url(forResource: "userguide", withExtension: "json") != nil {
			let guide = JSMStaticRow(key: "support.guide")
			guide.text = "User Guide"
			guide.accessoryType = .disclosureIndicator
			guide.selectionStyle = .default
			guide.configuration { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			support.addRow(guide)
		}

		let about = JSMStaticRow(key: "support.about")
		about.text = "About"
		about.accessoryType = .disclosureIndicator
		about.selectionStyle = .default
		about.configuration(forCell: { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		})
		support.addRow(about)

		self.dataSource.sections = sections
	}

	/// Refresh the contact section.
	fileprivate func _contactSection() -> JSMStaticSection {
		let section = JSMStaticSection(key: "contact")
		section.headerText = "Contact"

		if let preferences = self.preferences, let contact = preferences.contact {
			section.footerText = "This is your selected contact. You can tap at any time to select a different person from your address book."

			let contactRow = JSMStaticRow(key: "contact")
			contactRow.text = CNContactFormatter().string(from: contact)
			contactRow.image = preferences.contactThumbnail(46, stroke: 1, edgeInsets: UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0))
			contactRow.configuration { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			section.addRow(contactRow)
		}

		else {
			section.footerText = "You'll need to choose a contact to use Other for: someone you often send things to via Messages."

			let row = JSMStaticRow(key: "select-contact")
			row.text = "Select contact…"
			row.configuration { row, cell in
				cell.textLabel?.textColor = PreferencesManager.tintColor
			}
			section.addRow(row)
		}

		return section
	}

	/// Refresh the recipient section, removing if no contact is selected.
	fileprivate func _recipientSection() -> [JSMStaticSection]? {
		guard let preferences = self.preferences, preferences.contact != nil else {
			return nil
		}

        let sectionOne = JSMStaticSection(key: "recipients-one")
        sectionOne.footerText = "The phone number (or email address) used for composing texts, or for linking to the Messages app."

        let sectionTwo = JSMStaticSection(key: "recipients-two")
        sectionTwo.footerText = "Additional buttons can be enabled by selecting the number used for phone or FaceTime calls."

        // Message Recipient
        
        let messagePreference = JSMStaticSelectPreference.transientPreference(withKey: "message-recipient")
        messagePreference.add(self)
        sectionOne.addRow(messagePreference)
        
        var messageOptions: [[String: Any]] = preferences.messageOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option] as [String: Any]
        })
        messageOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""] as [String: Any])
        
        messagePreference.text = "Messages"
        messagePreference.value = preferences.messageRecipient ?? ""
        messagePreference.options = messageOptions
        messagePreference.configuration { row, cell in
            cell.textLabel?.textColor = PreferencesManager.tintColor
        }

		// Call Recipient

		let callPreference = JSMStaticSelectPreference.transientPreference(withKey: "call-recipient")
		callPreference.add(self)
		sectionTwo.addRow(callPreference)

        var callOptions: [[String: Any]] = preferences.callOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option] as [String: Any]
        })
        callOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""] as [String: Any])

        callPreference.text = "Calls"
		callPreference.value = preferences.callRecipient ?? ""
		callPreference.options = callOptions
		callPreference.configuration { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}

        // FaceTime Recipient
        
        let facetimePreference = JSMStaticSelectPreference.transientPreference(withKey: "facetime-recipient")
        facetimePreference.add(self)
        sectionTwo.addRow(facetimePreference)
        
        var facetimeOptions: [[String: Any]] = preferences.facetimeOptions.map({ (option) in
            return [JSMStaticSelectOptionLabel: option, JSMStaticSelectOptionValue: option] as [String: Any]
        })
        facetimeOptions.append([JSMStaticSelectOptionLabel: "None", JSMStaticSelectOptionValue: ""] as [String: Any])
        
        facetimePreference.text = "FaceTime"
        facetimePreference.value = preferences.facetimeRecipient ?? ""
        facetimePreference.options = facetimeOptions
        facetimePreference.configuration { row, cell in
            cell.textLabel?.textColor = PreferencesManager.tintColor
        }

		return [sectionOne, sectionTwo]
	}

	/// Refresh the messages section, removing if no message recipient is selected.
	fileprivate func _messagesSection() -> JSMStaticSection? {
		guard let preferences = self.preferences, let recipient = preferences.messageRecipient, recipient.characters.count > 0 else {
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
		row.editingStyle = .insert
		row.configuration { row, cell in
			cell.textLabel?.textColor = PreferencesManager.tintColor
		}
		section.addRow(row)

		return section
	}

	/// Generate a row for editing the content of a message.
	fileprivate func _rowForMessage(_ message: String?, key: String) -> JSMStaticTextPreference {
		let row = JSMStaticTextPreference.transientPreference(withKey: key)
		row.value = message
		row.textField?.placeholder = "Message Text"
		row.textField?.returnKeyType = .done
		row.textField?.delegate = self
		row.canBeMoved = true
		row.editingStyle = .delete
		row.fitControlToCell = true
		row.configuration { row, cell in
			if let preference = row as? JSMStaticTextPreference, let font = cell.textLabel?.font {
				preference.textField?.font = font
				preference.textField?.textColor = PreferencesManager.tintColor
			}
		}
		row.add(self)
		return row
	}

	/// Generates a list of messages in the messages section, and saves them, using the PreferencesManager.
	fileprivate func _saveMessages() {
		if let preferences = self.preferences, let rows = self.dataSource.section(withKey: "messages")?.rows {
			print("Saving messages...")

			let values: [String?] = rows.map({
				(row) in
				guard let preference = row as? JSMStaticTextPreference else {
					return nil
				}

				guard let value = preference.value, value.characters.count > 0 else {
					return nil
				}

				return preference.value
			})

			preferences.messages = values.flatMap({ $0 })

			preferences.updateShortcutItems( UIApplication.shared )
		}
		else {
			let message = "There was a problem with saving your messages. Maybe you can give it another shot?"
			let alert = UIAlertController.alert(message)
			self.present(alert, animated: true, completion: nil)
		}
	}

}
