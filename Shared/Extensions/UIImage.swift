import UIKit

extension UIImage {

    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(color: UIColor) -> UIImage {
        let size = CGSize(width: 20, height: 100)
        return self.imageWithGradient(color, size: size)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(color: UIColor, height: CGFloat) -> UIImage {
        let size = CGSize(width: 20, height: height)
        return self.imageWithGradient(color, size: size)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(color: UIColor, size: CGSize) -> UIImage {
        return self.imageWithGradient(color, size: size, top: 0, bottom: 1)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(color: UIColor, size: CGSize, top: CGFloat, bottom: CGFloat) -> UIImage {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 1

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let topHue = hue + 0.01 + ( -0.01 * top )
        let topSaturation = saturation + 0.04 + ( -0.09 * top )
        let topBrightness = brightness - 0.095 + ( 0.145 * top )
        let topColor = UIColor(hue: topHue, saturation: topSaturation, brightness: topBrightness, alpha: alpha)
        
        let bottomHue = hue + 0.01 + ( -0.01 * bottom )
        let bottomSaturation = saturation + 0.04 + ( -0.09 * bottom )
        let bottomBrightness = brightness - 0.095 + ( 0.145 * bottom )
        let bottomColor = UIColor(hue: bottomHue, saturation: bottomSaturation, brightness: bottomBrightness, alpha: alpha)

        let scale = UIScreen.mainScreen().scale
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContext(pixelSize)
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        let gradient = CGGradientCreateWithColors(colorSpace, [topColor.CGColor, bottomColor.CGColor], locations)
        
        let startPoint = CGPointMake(pixelSize.width / 2, 0)
        let endPoint = CGPointMake(pixelSize.width / 2, pixelSize.height)
        CGContextDrawLinearGradient(context!, gradient!, startPoint, endPoint, [.DrawsBeforeStartLocation, .DrawsAfterEndLocation])
        
        let image = CGBitmapContextCreateImage(context!)
        UIGraphicsEndImageContext()
        
        return UIImage(CGImage: image!, scale: scale, orientation: .Up).stretchableImageWithLeftCapWidth(0, topCapHeight: 0)
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
		let context = CGBitmapContextCreate(nil, Int(scaledSize), Int(scaledSize), CGImageGetBitsPerComponent(source!), 0, CGImageGetColorSpace(source!)!, bitmapInfo.rawValue)

		let percent = scaledSize / min(self.size.width * self.scale, self.size.height * self.scale)
		let rectSize = CGSize(width: self.size.width * self.scale * percent, height: self.size.height * self.scale * percent)
		let rectOrigin = CGPoint(x: ((rectSize.width - scaledSize) / 2), y: ((rectSize.height - scaledSize) / 2) )
		var rect = CGRect(origin: rectOrigin, size: rectSize)

		if( stroke >= 1 ) {
			CGContextAddEllipseInRect(context!, rect)
			CGContextSetFillColorWithColor(context!, UIColor.whiteColor().CGColor)
			CGContextDrawPath(context!, .Fill)

			rect = rect.insetBy(dx: stroke * scale, dy: stroke * scale)
		}

		CGContextAddEllipseInRect(context!, rect)
		CGContextClip(context!)

		CGContextDrawImage(context!, rect, source!)

		guard let imageRef = CGBitmapContextCreateImage(context!) else {
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
        let context = CGBitmapContextCreate(nil, Int(contextSize.width), Int(contextSize.height), CGImageGetBitsPerComponent(source!), 0, CGImageGetColorSpace(source!)!, bitmapInfo.rawValue)
        
        let rect = CGRect(x: edgeInsets.left * scale, y: edgeInsets.bottom * scale, width: self.size.width * scale, height: self.size.height * scale)
        CGContextDrawImage(context!, rect, source!)
        
        guard let imageRef = CGBitmapContextCreateImage(context!) else {
            return nil
        }
        
        return UIImage(CGImage: imageRef, scale: scale, orientation: self.imageOrientation)
    }

    public func overlay(icon: UIImage?, color: UIColor) -> UIImage? {
        guard let icon = icon else { return self }
        
        let size = CGSize(width: self.size.width * self.scale, height: self.size.height * self.scale)
        let rect = CGRect(origin: CGPointZero, size: size)
        
        let source = self.CGImage
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(source!), 0, CGImageGetColorSpace(source!)!, bitmapInfo.rawValue)

        CGContextDrawImage(context!, rect, source!)
        
        let iconSize = CGSize(width: icon.size.width * icon.scale, height: icon.size.height * icon.scale)
        let iconOrigin = CGPoint(x: (size.width - iconSize.width) / 2, y: (size.height - iconSize.height) / 2)
        let iconRect = CGRect(origin: iconOrigin, size: iconSize)
        
        CGContextClipToMask(context!, iconRect, icon.CGImage!)
        CGContextSetFillColorWithColor(context!, color.CGColor)
        CGContextFillRect(context!, iconRect)

        guard let imageRef = CGBitmapContextCreateImage(context!) else {
            return nil
        }
        
        return UIImage(CGImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
    }

}
