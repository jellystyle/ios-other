import UIKit

extension UINavigationController {

	public override func viewDidLoad() {
		super.viewDidLoad()

		if self._isStandardNavigationController { return }

		let color = PreferencesManager.tintColor
		let gradient = UIImage.imageWithGradient(color)

		self.navigationBar.translucent = true
		self.navigationBar.barTintColor = color
		self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .Default)
		self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .Compact)
		self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .DefaultPrompt)
		self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .CompactPrompt)

		// TODO: Automatically determine best contrast for colour of title and buttons.
		self.navigationBar.tintColor = UIColor.whiteColor()
		self.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName: UIColor.whiteColor() ]
	}

	public override func preferredStatusBarStyle() -> UIStatusBarStyle {
		if self._isStandardNavigationController { return super.preferredStatusBarStyle() }

		return UIStatusBarStyle.LightContent
	}

	/// Flag to indicate if the receiver is a plain `UINavigationController`.
	/// This typically indicates if the controller is owned by an external library, like with a `MFMessageComposeViewController`
	private var _isStandardNavigationController: Bool {
		get {
			return object_getClass(self.navigationBar.delegate).self != UINavigationController.self
		}
	}
	
}
