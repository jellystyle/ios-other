import UIKit

extension UIImage {

	/// Generate a vertical gradient based on a single colour.
	/// @param color The (roughly) mid-point to use for the gradient.
	/// @return A 900px square image with a vertical, linear gradient based on the given colour.
	class func imageWithGradient(color: UIColor) -> UIImage {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0

		color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
		let topColor = UIColor(hue: hue, saturation: saturation, brightness: brightness + 0.2, alpha: alpha)
		let bottomColor = UIColor(hue: hue, saturation: saturation, brightness: brightness - 0.02, alpha: alpha)

		let size = CGSize(width: 900, height: 900)

		UIGraphicsBeginImageContext(size)
		let context = UIGraphicsGetCurrentContext()

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let locations: [CGFloat] = [0.0, 1.0]

		let gradient = CGGradientCreateWithColors(colorSpace, [topColor.CGColor, bottomColor.CGColor], locations)

		let startPoint = CGPointMake(size.width / 2, 0)
		let endPoint = CGPointMake(size.width / 2, size.height)
		CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, [.DrawsBeforeStartLocation, .DrawsAfterEndLocation])

		let finalImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return finalImage.stretchableImageWithLeftCapWidth(0, topCapHeight: 0)
	}

	/// Create a new image which is resized and masked as a circle, with an optional white stroke.
	/// @param diameter The diameter to use for the circle. The given image will be resized to fill this space.
	/// @param stroke Line width to use for the stroke, defaults to 0 (which does not render a stroke).
	/// @return A circular image matching the given parameters.
	public func circularImage(diameter: CGFloat, stroke: CGFloat = 0) -> UIImage? {
		if diameter == 0 { return nil }

		let scale = UIScreen.mainScreen().scale
		let scaledSize = diameter * scale

		let source = self.CGImage

		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let context = CGBitmapContextCreate(nil, Int(scaledSize), Int(scaledSize), CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), bitmapInfo.rawValue)

		let percent = scaledSize / min(self.size.width * self.scale, self.size.height * self.scale)
		let rectSize = CGSize(width: self.size.width * self.scale * percent, height: self.size.height * self.scale * percent)
		let rectOrigin = CGPoint(x: ((rectSize.width - scaledSize) / 2), y: ((rectSize.height - scaledSize) / 2) )
		var rect = CGRect(origin: rectOrigin, size: rectSize)

		if( stroke >= 1 ) {
			CGContextAddEllipseInRect(context, rect)
			CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
			CGContextDrawPath(context, .Fill)

			rect = rect.insetBy(dx: stroke * scale, dy: stroke * scale)
		}

		CGContextAddEllipseInRect(context, rect)
		CGContextClip(context)

		CGContextDrawImage(context, rect, source)

		guard let imageRef = CGBitmapContextCreateImage(context) else {
			return nil
		}

		return UIImage(CGImage: imageRef, scale: scale, orientation: self.imageOrientation)
	}

	/// Creates a new image in which the given image is "padded" based on the given `edgeInsets`.
	/// This allows manual adjustments to an image's apparent position without needing to adjust the image view.
	/// @param edgeInsets The padding to use for each of the four sides.
	/// @return A new image which has (transparent) padding added based on the given `edgeInsets`.
	public func paddedImage(edgeInsets: UIEdgeInsets) -> UIImage? {
		if edgeInsets == UIEdgeInsetsZero { return self }

		let scale = UIScreen.mainScreen().scale

		let source = self.CGImage

		let contextSize = CGSize(width: (self.size.width + edgeInsets.left + edgeInsets.right) * scale, height: (self.size.height + edgeInsets.top + edgeInsets.bottom) * scale)
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
		let context = CGBitmapContextCreate(nil, Int(contextSize.width), Int(contextSize.height), CGImageGetBitsPerComponent(source), 0, CGImageGetColorSpace(source), bitmapInfo.rawValue)

		let rect = CGRect(x: edgeInsets.left * scale, y: edgeInsets.bottom * scale, width: self.size.width * scale, height: self.size.height * scale)
		CGContextDrawImage(context, rect, source)

		guard let imageRef = CGBitmapContextCreateImage(context) else {
			return nil
		}

		return UIImage(CGImage: imageRef, scale: scale, orientation: self.imageOrientation)
	}
	
}
