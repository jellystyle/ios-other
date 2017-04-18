import UIKit

extension UIImage {

    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 20, height: 100)
        return self.imageWithGradient(color, size: size)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(_ color: UIColor, height: CGFloat) -> UIImage {
        let size = CGSize(width: 20, height: height)
        return self.imageWithGradient(color, size: size)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(_ color: UIColor, size: CGSize) -> UIImage {
        return self.imageWithGradient(color, size: size, top: 0, bottom: 1)
    }
    
    /// Generate a vertical gradient based on a single colour.
    /// @param color The (roughly) mid-point to use for the gradient.
    /// @return A 900px square image with a vertical, linear gradient based on the given colour.
    class func imageWithGradient(_ color: UIColor, size: CGSize, top: CGFloat, bottom: CGFloat) -> UIImage {
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

        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContext(pixelSize)
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: [topColor.cgColor, bottomColor.cgColor] as CFArray, locations: locations)
        
        let startPoint = CGPoint(x: pixelSize.width / 2, y: 0)
        let endPoint = CGPoint(x: pixelSize.width / 2, y: pixelSize.height)
        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        
        let image = context!.makeImage()
        UIGraphicsEndImageContext()
        
        return UIImage(cgImage: image!, scale: scale, orientation: .up).stretchableImage(withLeftCapWidth: 0, topCapHeight: 0)
    }

	/// Create a new image which is resized and masked as a circle, with an optional white stroke.
	/// @param diameter The diameter to use for the circle. The given image will be resized to fill this space.
	/// @param stroke Line width to use for the stroke, defaults to 0 (which does not render a stroke).
	/// @return A circular image matching the given parameters.
	public func circularImage(_ diameter: CGFloat, stroke: CGFloat = 0) -> UIImage? {
		if diameter == 0 { return nil }

		let scale = UIScreen.main.scale
		let scaledSize = diameter * scale

		let source = self.cgImage

		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
		let context = CGContext(data: nil, width: Int(scaledSize), height: Int(scaledSize), bitsPerComponent: source!.bitsPerComponent, bytesPerRow: 0, space: source!.colorSpace!, bitmapInfo: bitmapInfo.rawValue)

		let percent = scaledSize / min(self.size.width * self.scale, self.size.height * self.scale)
		let rectSize = CGSize(width: self.size.width * self.scale * percent, height: self.size.height * self.scale * percent)
		let rectOrigin = CGPoint(x: ((rectSize.width - scaledSize) / 2), y: ((rectSize.height - scaledSize) / 2) )
		var rect = CGRect(origin: rectOrigin, size: rectSize)

		if( stroke >= 1 ) {
			context!.addEllipse(in: rect)
			context!.setFillColor(UIColor.white.cgColor)
			context!.drawPath(using: .fill)

			rect = rect.insetBy(dx: stroke * scale, dy: stroke * scale)
		}

		context!.addEllipse(in: rect)
		context!.clip()

		context!.draw(source!, in: rect)

		guard let imageRef = context!.makeImage() else {
			return nil
		}

		return UIImage(cgImage: imageRef, scale: scale, orientation: self.imageOrientation)
	}

	/// Creates a new image in which the given image is "padded" based on the given `edgeInsets`.
	/// This allows manual adjustments to an image's apparent position without needing to adjust the image view.
	/// @param edgeInsets The padding to use for each of the four sides.
	/// @return A new image which has (transparent) padding added based on the given `edgeInsets`.
    public func paddedImage(_ edgeInsets: UIEdgeInsets) -> UIImage? {
        if edgeInsets == UIEdgeInsets.zero { return self }
        
        let scale = UIScreen.main.scale
        
        let source = self.cgImage
        
        let contextSize = CGSize(width: (self.size.width + edgeInsets.left + edgeInsets.right) * scale, height: (self.size.height + edgeInsets.top + edgeInsets.bottom) * scale)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(contextSize.width), height: Int(contextSize.height), bitsPerComponent: source!.bitsPerComponent, bytesPerRow: 0, space: source!.colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        
        let rect = CGRect(x: edgeInsets.left * scale, y: edgeInsets.bottom * scale, width: self.size.width * scale, height: self.size.height * scale)
        context!.draw(source!, in: rect)
        
        guard let imageRef = context!.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: imageRef, scale: scale, orientation: self.imageOrientation)
    }

    public func overlay(_ icon: UIImage?, color: UIColor) -> UIImage? {
        guard let icon = icon else { return self }
        
        let size = CGSize(width: self.size.width * self.scale, height: self.size.height * self.scale)
        let rect = CGRect(origin: CGPoint.zero, size: size)
        
        let source = self.cgImage
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: source!.bitsPerComponent, bytesPerRow: 0, space: source!.colorSpace!, bitmapInfo: bitmapInfo.rawValue)

        context!.draw(source!, in: rect)
        
        let iconSize = CGSize(width: icon.size.width * icon.scale, height: icon.size.height * icon.scale)
        let iconOrigin = CGPoint(x: (size.width - iconSize.width) / 2, y: (size.height - iconSize.height) / 2)
        let iconRect = CGRect(origin: iconOrigin, size: iconSize)
        
        context!.clip(to: iconRect, mask: icon.cgImage!)
        context!.setFillColor(color.cgColor)
        context!.fill(iconRect)

        guard let imageRef = context!.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
    }

}
