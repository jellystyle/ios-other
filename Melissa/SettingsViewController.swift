import UIKit
import StaticTables
import AddressBookUI

class SettingsViewController: JSMStaticTableViewController, JSMStaticPreferenceObserver {

    let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa")

    // MARK: View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.editing = true
        self.tableView.allowsSelectionDuringEditing = true

        // Call Recipient

        let callSection = JSMStaticSection(key: "call-recipient")
        callSection.headerText = "Call Recipient"
        self.dataSource.addSection(callSection)

        let callRow = JSMStaticTextPreference.transientPreferenceWithKey("call")
        callRow.value = self.sharedDefaults!.stringForKey("call")
        callRow.textField?.keyboardType = UIKeyboardType.PhonePad
        callRow.textField?.placeholder = "+61000000000"
        callRow.fitControlToCell = true
        callRow.addObserver(self)
        callSection.addRow(callRow)

        // Message Recipient
        
        let messageSection = JSMStaticSection(key: "message-recipient")
        messageSection.headerText = "Message Recipient"
        self.dataSource.addSection( messageSection )

        let messageRow = JSMStaticTextPreference.transientPreferenceWithKey("message")
        messageRow.value = self.sharedDefaults!.stringForKey("message")
        messageRow.textField?.keyboardType = UIKeyboardType.EmailAddress
        messageRow.textField?.placeholder = "example@example.com"
        messageRow.fitControlToCell = true
        messageRow.addObserver(self)
        messageSection.addRow(messageRow)

        // Messages

        let messagesSection = JSMStaticSection(key: "messages")
        messagesSection.headerText = "Messages"
        self.dataSource.addSection(messagesSection)

        if let messages = self.sharedDefaults!.arrayForKey("messages") {
            for message in messages {
                if let message = message as? String {

                    let row = JSMStaticTextPreference.transientPreferenceWithKey(message)
                    row.value = message
                    row.textField?.placeholder = "Message Text"
                    row.canBeMoved = true
                    row.canBeDeleted = true
                    row.fitControlToCell = true
                    row.addObserver(self)
                    messagesSection.addRow(row)

                }
            }
        }
        
        let row = JSMStaticRow(key: "add-message")
        row.text = "Add Message"
        row.canBeDeleted = true
        row.configurationForCell { (row, cell) in
            cell.textLabel?.textColor = UIColor(red: 0, green: 0.506, blue: 0.83, alpha: 1)
        }
        messagesSection.addRow(row)

    }

    func updateMessagesInUserDefaults() {
        if let sharedDefaults = self.sharedDefaults, let rows = self.dataSource?.sectionWithKey("messages")?.rows {
            let filteredRows = rows.filter() { ($0 as? JSMStaticTextPreference)?.value != nil } as! [JSMStaticTextPreference]
            let messages = filteredRows.map() { $0.value }
            sharedDefaults.setObject(messages, forKey: "messages" )
            sharedDefaults.synchronize()
        }
    }

    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let dataSource = tableView.dataSource as? JSMStaticDataSource {
            let row = dataSource.rowAtIndexPath(indexPath)
            if( row.key as? String == "add-message" ) {

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

    // MARK: Static data source delegate

    override func dataSource(dataSource: JSMStaticDataSource!, didMoveRow row: JSMStaticRow!, fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {
        self.updateMessagesInUserDefaults()
    }

    override func dataSource(dataSource: JSMStaticDataSource!, didDeleteRow row: JSMStaticRow!, fromIndexPath indexPath: NSIndexPath!) {
        self.updateMessagesInUserDefaults()
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
    }

    // MARK: Static preference observer
    
    func preference(preference: JSMStaticPreference!, didChangeValue value: AnyObject!) {
        if let sharedDefaults = self.sharedDefaults {

            if preference.section?.key as? String != "messages" {
                if let preferenceKey = preference.key as? String {
                    sharedDefaults.setObject(value, forKey: preferenceKey )
                    sharedDefaults.synchronize()
                }
            }
            else {
                self.updateMessagesInUserDefaults()
            }

        }
    }

}
