import UIKit

extension UIAlertController {

	/// Create a `UIAlertController` with the given `message`.
	/// @param message The text to be displayed to the user.
	/// @param handler The function to be run when the user taps the "OK" button (defaults to `nil`).
	/// @return The generated alert.
	class func alert(_ message: String, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
		let title = Bundle.main.displayName ?? "Other"
		let alertController = UIAlertController(title: title, message: message.trimmingCharacters(in: .whitespacesAndNewlines), preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
		return alertController
	}

	/// Create a `UIAlertController` with the given `message`, an action button and a cancel button.
	/// @param message The text to be displayed to the user.
	/// @param action The label to be displayed on the alert's action button.
	/// @param handler The function to be run when the user taps the action button.
	/// @return The generated alert.
	class func alert(_ message: String, action: String, handler: @escaping (UIAlertAction) -> Void) -> UIAlertController {
		let title = Bundle.main.displayName ?? "Other"
		let alertController = UIAlertController(title: title, message: message.trimmingCharacters(in: .whitespacesAndNewlines), preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: action, style: .default, handler: handler))
		return alertController
	}

}
