import UIKit
import MessageUI
import MobileCoreServices

class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa")

    // MARK: Handling extension requests

    var messageController: MFMessageComposeViewController?

    override func beginRequestWithExtensionContext(context: NSExtensionContext) {
        super.beginRequestWithExtensionContext(context)

        // Create our message controller
        self.messageController = MFMessageComposeViewController()
        self.messageController!.messageComposeDelegate = self

        // Add our recipient
        if let sharedDefaults = NSUserDefaults(suiteName: "group.com.jellystyle.Melissa"), let messageRecipient = sharedDefaults.stringForKey("message") {
            self.messageController!.recipients = [ messageRecipient ];
        }

        // We'll handle as many items as we can
        var items = 0
        for item in context.inputItems as! [NSExtensionItem] {
            for itemProvider in item.attachments as! [NSItemProvider] {

                if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeFileURL ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeURL ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeImage ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeAudiovisualContent ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeText ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypePDF ) {
                    items++;
                }

                else if self.attemptToHandle( itemProvider, typeIdentifier: kUTTypeVCard ) {
                    items++;
                }
                
            }
        }

        // If we don't have any items, we can just complete
        if items == 0 {
            context.completeRequestReturningItems( [], completionHandler:nil )
        }
    }

    func attemptToHandle( itemProvider: NSItemProvider!, typeIdentifier: CFString! ) -> Bool {
        if !itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier as! String) {
            return false
        }

        itemProvider.loadItemForTypeIdentifier(typeIdentifier as! String, options: nil, completionHandler: { (item, error) -> Void in

            if let messageController = self.messageController, url = item as? NSURL {

                if url.fileURL {
                    messageController.addAttachmentURL( url, withAlternateFilename: nil )
                }

                else if let urlString = url.absoluteString {
                    var body = messageController.body != nil ? messageController.body : ""
                    body = body + " " + urlString
                    body = body.stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
                    messageController.body = body
                }

            }

        })
        
        return true
    }

    // MARK: View life cycle

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let messageController = self.messageController {
            self.presentViewController( messageController, animated: true, completion: nil)
        }
    }

    // MARK: Message compose view delegate

    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated( true ) {
            if let extensionContext = self.extensionContext {
                extensionContext.completeRequestReturningItems( [], completionHandler:nil )
            }
        }
    }

}
