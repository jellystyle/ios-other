import UIKit

extension UIAlertController {

	/// Create a `UIAlertController` with the given `message`.
	/// @param message The text to be displayed to the user.
	/// @param handler The function to be run when the user taps the "OK" button (defaults to `nil`).
	/// @return The generated alert.
	class func alert(message: String, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
		let title = NSBundle.mainBundle().displayName ?? "Melissa"
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
		alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: handler))
		return alertController
	}

}