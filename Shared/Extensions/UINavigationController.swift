import UIKit

extension UINavigationController {

	public override func viewDidLoad() {
		super.viewDidLoad()

		let color = PreferencesManager.tintColor
		let gradient = UIImage.imageWithGradient(color)

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
		return UIStatusBarStyle.LightContent
	}
	
}
