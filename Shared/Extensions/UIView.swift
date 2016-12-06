import UIKit

public extension UIView {
    
    /// Alignment of items on a given axis
    public enum AnchorAlignment {
        case leading
        case center
        case trailing
        
        static let top = AnchorAlignment.leading
        static let bottom = AnchorAlignment.trailing
        static let left = AnchorAlignment.leading
        static let right = AnchorAlignment.trailing
    }
    
    // MARK: View constraints
    
    @objc(anchorToView:)
    func anchor(to view: UIView) {
        self.anchorWidth(to: view)
        self.anchorHeight(to: view)
    }
    
    @objc(anchorToView:constant:)
    func anchor(to view: UIView, constant: CGFloat) {
        self.anchorWidth(to: view, constant: constant)
        self.anchorHeight(to: view, constant: constant)
    }
    
    @objc(anchorWidthToView:)
    func anchorWidth(to view: UIView) {
        self.anchorWidth(to: view, constant: 0)
    }
    
    @objc(anchorWidthToView:constant:)
    func anchorWidth(to view: UIView, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = self.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
        leading.constant = constant
        leading.active = true
        
        let trailing = self.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
        trailing.constant = -constant
        trailing.active = true
    }
    
    @objc(anchorHeightToView:)
    func anchorHeight(to view: UIView) {
        self.anchorHeight(to: view, constant: 0)
    }
    
    @objc(anchorHeightToView:constant:)
    func anchorHeight(to view: UIView, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let top = self.topAnchor.constraintEqualToAnchor(view.topAnchor)
        top.constant = constant
        top.active = true
        
        let bottom = self.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        bottom.constant = -constant
        bottom.active = true
    }
    
    func anchorWidth(to view: UIView, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraintEqualToConstant(maximum)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.active = true
        
        switch alignment {
        case .leading:
            self.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        case .center:
            self.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        case .trailing:
            self.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        }
        
        self.widthAnchor.constraintLessThanOrEqualToAnchor(view.widthAnchor).active = true
    }
    
    func anchorHeight(to view: UIView, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = self.heightAnchor.constraintEqualToConstant(maximum)
        heightConstraint.priority = UILayoutPriorityDefaultHigh
        heightConstraint.active = true
        
        switch alignment {
        case .leading:
            self.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        case .center:
            self.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor).active = true
        case .trailing:
            self.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        }
        
        self.heightAnchor.constraintLessThanOrEqualToAnchor(view.heightAnchor).active = true
    }
    
    // MARK: Layout guide constraints
    
    @objc(anchorToLayoutGuide:)
    func anchor(to layoutGuide: UILayoutGuide) {
        self.anchorWidth(to: layoutGuide)
        self.anchorHeight(to: layoutGuide)
    }
    
    @objc(anchorToLayoutGuide:constant:)
    func anchor(to layoutGuide: UILayoutGuide, constant: CGFloat) {
        self.anchorWidth(to: layoutGuide, constant: constant)
        self.anchorHeight(to: layoutGuide, constant: constant)
    }
    
    @objc(anchorWidthToLayoutGuide:)
    func anchorWidth(to layoutGuide: UILayoutGuide) {
        self.anchorWidth(to: layoutGuide, constant: 0)
    }
    
    @objc(anchorWidthToLayoutGuide:constant:)
    func anchorWidth(to layoutGuide: UILayoutGuide, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = self.leadingAnchor.constraintEqualToAnchor(layoutGuide.leadingAnchor)
        leading.constant = constant
        leading.active = true
        
        let trailing = self.trailingAnchor.constraintEqualToAnchor(layoutGuide.trailingAnchor)
        trailing.constant = -constant
        trailing.active = true
    }
    
    @objc(anchorHeightToLayoutGuide:)
    func anchorHeight(to layoutGuide: UILayoutGuide) {
        self.anchorHeight(to: layoutGuide, constant: 0)
    }
    
    @objc(anchorHeightToLayoutGuide:constant:)
    func anchorHeight(to layoutGuide: UILayoutGuide, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let top = self.topAnchor.constraintEqualToAnchor(layoutGuide.topAnchor)
        top.constant = constant
        top.active = true
        
        let bottom = self.bottomAnchor.constraintEqualToAnchor(layoutGuide.bottomAnchor)
        bottom.constant = -constant
        bottom.active = true
    }
    
    func anchorWidth(to layoutGuide: UILayoutGuide, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraintEqualToConstant(maximum)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.active = true
        
        switch alignment {
        case .leading:
            self.leadingAnchor.constraintEqualToAnchor(layoutGuide.leadingAnchor).active = true
        case .center:
            self.centerXAnchor.constraintEqualToAnchor(layoutGuide.centerXAnchor).active = true
        case .trailing:
            self.trailingAnchor.constraintEqualToAnchor(layoutGuide.trailingAnchor).active = true
        }
        
        self.widthAnchor.constraintLessThanOrEqualToAnchor(layoutGuide.widthAnchor).active = true
    }
    
    func anchorHeight(to layoutGuide: UILayoutGuide, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = self.heightAnchor.constraintEqualToConstant(maximum)
        heightConstraint.priority = UILayoutPriorityDefaultHigh
        heightConstraint.active = true
        
        switch alignment {
        case .leading:
            self.topAnchor.constraintEqualToAnchor(layoutGuide.topAnchor).active = true
        case .center:
            self.centerYAnchor.constraintEqualToAnchor(layoutGuide.centerYAnchor).active = true
        case .trailing:
            self.bottomAnchor.constraintEqualToAnchor(layoutGuide.bottomAnchor).active = true
        }
        
        self.heightAnchor.constraintLessThanOrEqualToAnchor(layoutGuide.heightAnchor).active = true
    }
    
}
