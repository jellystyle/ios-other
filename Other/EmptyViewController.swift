import UIKit
import ContactsUI

class EmptyViewController: UIViewController, CNContactPickerDelegate {

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	// MARK: View life cycle

	@IBOutlet weak var stackView: UIStackView!

	@IBOutlet weak var imageView: UIImageView!

	@IBOutlet weak var button: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.imageView.tintColor = PreferencesManager.tintColor
		self.button.tintColor = PreferencesManager.tintColor
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if self.preferences?.contact != nil {
			self.navigationController?.popToRootViewControllerAnimated(false)
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		let imageViewHeight = self.imageView.hidden ? self.imageView.image!.size.height : 0
		self.imageView.hidden = self.stackView.frame.size.height + imageViewHeight >= self.stackView.superview!.frame.size.height
	}

	// MARK: IBActions

	@IBAction func selectContact()  {
		let viewController = CNContactPickerViewController()
		viewController.delegate = self
		viewController.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0 || phoneNumbers.@count > 0")
		viewController.modalPresentationStyle = .FormSheet
		self.presentViewController(viewController, animated: true, completion: nil)
	}

	// MARK: Contact picker delegate

	func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
		if let preferences = self.preferences {
			preferences.contact = contact
			preferences.updateShortcutItems( UIApplication.sharedApplication() )

			self.navigationController?.popToRootViewControllerAnimated(false)
		}

		else {
			let message = "An error occurred while updating your selected contact. Can you give it another try in a moment?"
			let alert = UIAlertController.alert(message)
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

}
