import UIKit

extension UINavigationController {

	public override func viewDidLoad() {
		super.viewDidLoad()

        let color = UIColor(red:0.122,  green:0.463,  blue:0.804, alpha:1)
        let gradient = self._gradient(color)

        self.navigationBar.barTintColor = color
        self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .Default)
        self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .Compact)
        self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .DefaultPrompt)
        self.navigationBar.setBackgroundImage(gradient, forBarMetrics: .CompactPrompt)
	}

	public override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

    // MARK: Utilities

    private func _gradient(color: UIColor) -> UIImage {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let topColor = UIColor(hue:hue, saturation:saturation, brightness:brightness+0.2, alpha:alpha)
        let bottomColor = UIColor(hue:hue, saturation:saturation, brightness:brightness-0.02, alpha:alpha)

        let size = CGSize(width: 900, height: 900)

        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]

        let gradient = CGGradientCreateWithColors(colorSpace, [topColor.CGColor, bottomColor.CGColor], locations)

        let startPoint = CGPointMake(size.width / 2, 0)
        let endPoint = CGPointMake(size.width / 2, size.height)
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, [.DrawsBeforeStartLocation,.DrawsAfterEndLocation])

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage.stretchableImageWithLeftCapWidth(0, topCapHeight: 0)
    }

}
