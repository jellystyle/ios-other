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
    
    fileprivate func initialize() {
        self.applyCustomisations()
    }
    
    @objc fileprivate func applyCustomisations() {
        self.isTranslucent = true
        self.barTintColor = PreferencesManager.tintColor
    }
    
    override var barTintColor: UIColor? {
        didSet {
            var gradient: UIImage? = nil
            var tintColor: UIColor = PreferencesManager.tintColor
            var titleColor: UIColor = UIColor.darkText
            
            if let barTintColor = self.barTintColor {
                gradient = UIImage.imageWithGradient(barTintColor)
                tintColor = UIColor.white
                titleColor = UIColor.white
            }

            self.setBackgroundImage(gradient, for: .default)
            self.setBackgroundImage(gradient, for: .compact)
            self.setBackgroundImage(gradient, for: .defaultPrompt)
            self.setBackgroundImage(gradient, for: .compactPrompt)
            
            self.tintColor = tintColor
            self.titleTextAttributes = [ NSForegroundColorAttributeName: titleColor ]
        }
    }
    
}
