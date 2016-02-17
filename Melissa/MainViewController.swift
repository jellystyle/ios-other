import UIKit
import StaticTables
import MessageUI

class MainViewController: JSMStaticTableViewController, MFMessageComposeViewControllerDelegate {

    let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa")

    let section = JSMStaticSection()

    var callRecipient : String?

    var messageRecipient : String?

    var messages : [String]?

    // MARK: View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()


        self.dataSource.addSection( self.section );

    }

    override func viewWillAppear(animated: Bool) {

        if let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa") {
            self.callRecipient = sharedDefaults.stringForKey("call")
            self.messageRecipient = sharedDefaults.stringForKey("message")
            self.messages = sharedDefaults.arrayForKey("messages") as? [String]
        }

        self.section.removeAllRows()

        if self.callRecipient != nil && self.callRecipient!.characters.count > 0 {

            self.addRow( "Call", key: "__call" )

        }

        if self.messageRecipient != nil && self.messageRecipient!.characters.count > 0 {

            self.addRow( "Message", key: "__message" )

            if let messages = self.messages {

                for message in messages {

                    self.addRow( message, key: message )

                }

            }

        }

        self.tableView.reloadData()

    }

    func addRow( text: String, key: String, fontSize: CGFloat = 30 ) {
        let row = JSMStaticRow(key: key)
        row.style = .Default
        row.text = text
        row.configurationForCell { row, cell in
            cell.textLabel?.font = UIFont.systemFontOfSize( fontSize );
            cell.textLabel?.textAlignment = .Center
        }
        self.dataSource.sectionAtIndex(0).addRow( row )
    }

    // MARK: Table view delegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let numberOfRows : CGFloat = CGFloat( self.section.numberOfRows )
        return ( ( tableView.frame.size.height - tableView.contentInset.top - tableView.contentInset.bottom ) / numberOfRows )
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = self.dataSource.rowAtIndexPath( indexPath )

        if row.key as? String == "__call", let callRecipient = self.callRecipient {
            let telURL = NSURL(string: "tel:" + callRecipient )
            UIApplication.sharedApplication().openURL( telURL! )
        }

        else if let messageRecipient = self.messageRecipient {
            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self

            // Who does this go to?
            messageController.recipients = [ messageRecipient ]

            // Set the message's content
            if row.key as? String != "__message" {
                messageController.body = row.text
            }

            // Show message view
            self.navigationController?.presentViewController( messageController, animated: true, completion: nil)
        }

        // Clear the selection
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: Message compose view delegate

    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated( true, completion: nil )
    }

}
