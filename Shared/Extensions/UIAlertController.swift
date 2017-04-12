import UIKit

extension UIAlertController {

	/// Create a `UIAlertController` with the given `message`.
	/// @param message The text to be displayed to the user.
	/// @param handler The function to be run when the user taps the "OK" button (defaults to `nil`).
	/// @return The generated alert.
	class func alert(_ message: String, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
		let title = Bundle.main.displayName ?? "Other"
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
		return alertController
	}

}
