import UIKit

class NavigationBar: UINavigationBar {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    private func initialize() {
        self.translucent = true
        self.barTintColor = PreferencesManager.tintColor
    }
    
    override var barTintColor: UIColor? {
        didSet {
            var gradient: UIImage? = nil
            var tintColor: UIColor = PreferencesManager.tintColor
            var titleColor: UIColor = UIColor.darkTextColor()
            
            if let barTintColor = self.barTintColor {
                gradient = UIImage.imageWithGradient(barTintColor)
                tintColor = UIColor.whiteColor()
                titleColor = UIColor.whiteColor()
            }

            self.setBackgroundImage(gradient, forBarMetrics: .Default)
            self.setBackgroundImage(gradient, forBarMetrics: .Compact)
            self.setBackgroundImage(gradient, forBarMetrics: .DefaultPrompt)
            self.setBackgroundImage(gradient, forBarMetrics: .CompactPrompt)
            
            self.tintColor = tintColor
            self.titleTextAttributes = [ NSForegroundColorAttributeName: titleColor ]
        }
    }

}
