import UIKit

extension UIView {
    
    func anchor(toAllSidesOf view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let left = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 0)
        
        let right = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1, constant: 0)
        
        let top = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0)
        
        let bottom = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        
        view.addConstraints([left, right, top, bottom])
    }
    
    func anchor(toMarginsOnAllSidesOf view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let left = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .LeftMargin, multiplier: 1, constant: 0)
        
        let right = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .RightMargin, multiplier: 1, constant: 0)
        
        let top = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .TopMargin, multiplier: 1, constant: 0)
        
        let bottom = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1, constant: 0)
        
        view.addConstraints([left, right, top, bottom])
    }
    
    func anchor(toAllSidesOf view: UIView, maximumWidth width: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false

        let left = NSLayoutConstraint(item: self, attribute: .Left, relatedBy: .GreaterThanOrEqual, toItem: view, attribute: .Left, multiplier: 1, constant: 0)

        let right = NSLayoutConstraint(item: self, attribute: .Right, relatedBy: .GreaterThanOrEqual, toItem: view, attribute: .Right, multiplier: 1, constant: 0)
        
        let top = NSLayoutConstraint(item: self, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0)
        
        let bottom = NSLayoutConstraint(item: self, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        
        let centerX = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
        
        let width = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: width)
        
        view.addConstraints([left, right, top, bottom, centerX, width])
    }

    func anchor(toCenterOf view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false

        let centerX = NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
        
        let centerY = NSLayoutConstraint(item: self, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0)
        
        view.addConstraints([centerX, centerY])
    }

}
