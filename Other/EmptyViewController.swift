import UIKit
import ContactsUI
import Sherpa

class EmptyViewController: UIViewController, CNContactPickerDelegate {

	//! The shared preferences manager.
	let preferences = PreferencesManager.sharedManager

	// MARK: View life cycle

	@IBOutlet weak var stackView: UIStackView!

	@IBOutlet weak var imageView: UIImageView!

	@IBOutlet weak var button: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        
        self.imageView.tintColor = PreferencesManager.tintColor
        self.button.tintColor = PreferencesManager.tintColor

		self.preferences?.addObserver(self, forKeyPath: "contact", options: [], context: nil)

		if self.preferences?.contact != nil {
			self.navigationController?.popToRootViewController(animated: false)
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		self.preferences?.removeObserver(self, forKeyPath: "contact")
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		let imageViewHeight = self.imageView.isHidden ? self.imageView.image!.size.height : 0
		self.imageView.isHidden = self.stackView.frame.size.height + imageViewHeight >= self.stackView.superview!.frame.size.height
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

	@IBAction func showUserGuide()  {
		if let url = Bundle.main.url(forResource: "userguide", withExtension: "json") {
			let viewController = SherpaViewController(fileAtURL: url)
			viewController.tintColor = PreferencesManager.tintColor
			viewController.articleTextColor = PreferencesManager.textColor
			viewController.articleBackgroundColor = PreferencesManager.backgroundColor
			viewController.articleKey = "setting-up"
			self.present(viewController, animated: true, completion: nil)
		}
	}

	// MARK: Contact picker delegate

	func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
		if let preferences = self.preferences {
			preferences.contact = contact
			preferences.updateShortcutItems( UIApplication.shared )

			self.navigationController?.popToRootViewController(animated: false)
		}

		else {
			let message = "An error occurred while updating your selected contact. Can you give it another try in a moment?"
			let alert = UIAlertController.alert(message)
			self.present(alert, animated: true, completion: nil)
		}
	}

	// MARK: Key-value observing

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if self.preferences?.contact != nil {
			self.navigationController?.popToRootViewController(animated: false)
		}
	}

}
