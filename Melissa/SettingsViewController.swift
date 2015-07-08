import UIKit
import StaticTables
import AddressBookUI

class SettingsViewController: JSMStaticTableViewController, JSMStaticPreferenceObserver {

    let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa")

    // MARK: View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = self.navigationController {
            let gradient = UIImage(named: "gradient")!.stretchableImageWithLeftCapWidth(0, topCapHeight: 0)
            navigationController.navigationBar.setBackgroundImage( gradient, forBarMetrics: .Default )
            navigationController.navigationBar.setBackgroundImage( gradient, forBarMetrics: .Compact )
            navigationController.navigationBar.setBackgroundImage( gradient, forBarMetrics: .DefaultPrompt )
            navigationController.navigationBar.setBackgroundImage( gradient, forBarMetrics: .CompactPrompt )
        }

        // Call Recipient

        let callSection = JSMStaticSection()
        callSection.headerText = "Call Recipient"
        self.dataSource.addSection(callSection)

        let callRow = JSMStaticTextPreference.transientPreferenceWithKey("call")
        callRow.value = self.sharedDefaults!.stringForKey("call")
        callRow.textField.keyboardType = UIKeyboardType.PhonePad
        callRow.textField.placeholder = "+61000000000"
        callRow.fitControlToCell = true
        callRow.addObserver(self)
        callSection.addRow(callRow)

        // Message Recipient
        
        let messageSection = JSMStaticSection()
        messageSection.headerText = "Message Recipient"
        self.dataSource.addSection( messageSection )

        let messageRow = JSMStaticTextPreference.transientPreferenceWithKey("message")
        messageRow.value = self.sharedDefaults!.stringForKey("message")
        messageRow.textField.keyboardType = UIKeyboardType.EmailAddress
        messageRow.textField.placeholder = "example@example.com"
        messageRow.fitControlToCell = true
        messageRow.addObserver(self)
        messageSection.addRow(messageRow)

        // Messages

        //let messagesSection = JSMStaticSection()
        //messagesSection.headerText = "Quick Messages"
        //self.dataSource.addSection(messagesSection)

    }

    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Static preference observer

    func preference(preference: JSMStaticPreference!, didChangeValue value: AnyObject!) {
        if let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa") {
            sharedDefaults.setObject(value, forKey: preference.key as! String)
            sharedDefaults.synchronize()
        }
    }

}
