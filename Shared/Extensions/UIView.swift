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
        
        let leading = self.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leading.constant = constant
        leading.isActive = true
        
        let trailing = self.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        trailing.constant = -constant
        trailing.isActive = true
    }
    
    @objc(anchorHeightToView:)
    func anchorHeight(to view: UIView) {
        self.anchorHeight(to: view, constant: 0)
    }
    
    @objc(anchorHeightToView:constant:)
    func anchorHeight(to view: UIView, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let top = self.topAnchor.constraint(equalTo: view.topAnchor)
        top.constant = constant
        top.isActive = true
        
        let bottom = self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottom.constant = -constant
        bottom.isActive = true
    }
    
    func anchorWidth(to view: UIView, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraint(equalToConstant: maximum)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.isActive = true
        
        switch alignment {
        case .leading:
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        case .center:
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        case .trailing:
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
        
        self.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor).isActive = true
    }
    
    func anchorHeight(to view: UIView, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = self.heightAnchor.constraint(equalToConstant: maximum)
        heightConstraint.priority = UILayoutPriorityDefaultHigh
        heightConstraint.isActive = true
        
        switch alignment {
        case .leading:
            self.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        case .center:
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        case .trailing:
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        
        self.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor).isActive = true
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
        
        let leading = self.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor)
        leading.constant = constant
        leading.isActive = true
        
        let trailing = self.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor)
        trailing.constant = -constant
        trailing.isActive = true
    }
    
    @objc(anchorHeightToLayoutGuide:)
    func anchorHeight(to layoutGuide: UILayoutGuide) {
        self.anchorHeight(to: layoutGuide, constant: 0)
    }
    
    @objc(anchorHeightToLayoutGuide:constant:)
    func anchorHeight(to layoutGuide: UILayoutGuide, constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let top = self.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
        top.constant = constant
        top.isActive = true
        
        let bottom = self.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        bottom.constant = -constant
        bottom.isActive = true
    }
    
    func anchorWidth(to layoutGuide: UILayoutGuide, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = self.widthAnchor.constraint(equalToConstant: maximum)
        widthConstraint.priority = UILayoutPriorityDefaultHigh
        widthConstraint.isActive = true
        
        switch alignment {
        case .leading:
            self.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        case .center:
            self.centerXAnchor.constraint(equalTo: layoutGuide.centerXAnchor).isActive = true
        case .trailing:
            self.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        }
        
        self.widthAnchor.constraint(lessThanOrEqualTo: layoutGuide.widthAnchor).isActive = true
    }
    
    func anchorHeight(to layoutGuide: UILayoutGuide, withMaximum maximum: CGFloat, alignedTo alignment: AnchorAlignment) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = self.heightAnchor.constraint(equalToConstant: maximum)
        heightConstraint.priority = UILayoutPriorityDefaultHigh
        heightConstraint.isActive = true
        
        switch alignment {
        case .leading:
            self.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        case .center:
            self.centerYAnchor.constraint(equalTo: layoutGuide.centerYAnchor).isActive = true
        case .trailing:
            self.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true
        }
        
        self.heightAnchor.constraint(lessThanOrEqualTo: layoutGuide.heightAnchor).isActive = true
    }
    
}
