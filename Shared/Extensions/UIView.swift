import UIKit

extension UIView {
    
    func anchor(toAllSidesOf view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        self.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        self.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
    }
    
    func anchor(toAllSidesOf view: UIView, maximumWidth width: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraintEqualToConstant(width)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.active = true
        
        self.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        self.widthAnchor.constraintLessThanOrEqualToAnchor(view.widthAnchor).active = true
        self.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
    }
    
    func anchor(toLayoutGuide layoutGuide: UILayoutGuide) {
        self.translatesAutoresizingMaskIntoConstraints = false

        self.leadingAnchor.constraintEqualToAnchor(layoutGuide.leadingAnchor).active = true
        self.trailingAnchor.constraintEqualToAnchor(layoutGuide.trailingAnchor).active = true
        self.topAnchor.constraintEqualToAnchor(layoutGuide.topAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(layoutGuide.bottomAnchor).active = true
    }
    
    func anchor(toLayoutGuide layoutGuide: UILayoutGuide, maximumWidth width: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraintEqualToConstant(width)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.active = true

        self.centerXAnchor.constraintEqualToAnchor(layoutGuide.centerXAnchor).active = true
        self.widthAnchor.constraintLessThanOrEqualToAnchor(layoutGuide.widthAnchor).active = true
        self.topAnchor.constraintEqualToAnchor(layoutGuide.topAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(layoutGuide.bottomAnchor).active = true
    }

    func anchor(toCenterOf view: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        self.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
    }

}
