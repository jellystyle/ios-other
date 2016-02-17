import UIKit

extension UINavigationController {

	public override func viewDidLoad() {
		super.viewDidLoad()

        if let gradient = UIImage(named: "gradient") {
            let stretchableGradient = gradient.stretchableImageWithLeftCapWidth(0, topCapHeight: 0)
            self.navigationBar.setBackgroundImage(stretchableGradient, forBarMetrics: .Default)
            self.navigationBar.setBackgroundImage(stretchableGradient, forBarMetrics: .Compact)
            self.navigationBar.setBackgroundImage(stretchableGradient, forBarMetrics: .DefaultPrompt)
            self.navigationBar.setBackgroundImage(stretchableGradient, forBarMetrics: .CompactPrompt)
        }
	}

	public override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

}
