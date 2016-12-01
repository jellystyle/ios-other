import UIKit

protocol IconViewControllerDelegate {
    
    func iconViewController(iconViewController: UIViewController, didRequestOpenURL url: NSURL)
    
}

class IconViewController: UIViewController {
    
    //! The shared preferences manager.
    let preferences = PreferencesManager.sharedManager
    
    var delegate: IconViewControllerDelegate? = nil
    
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.preservesSuperviewLayoutMargins = true

        stackView = UIStackView()
        stackView.alignment = .Center
        stackView.axis = .Horizontal
        stackView.distribution = .EqualCentering

        self.view.addSubview(stackView)
        stackView.anchor(toLayoutGuide: self.view.layoutMarginsGuide, maximumWidth: 500)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadIcons()
    }
    
    @objc private func loadIcons() {
        guard let preferences = self.preferences else {
            return
        }
        
        if self.stackView.arrangedSubviews.count > 0 {
            for subview in self.stackView.arrangedSubviews {
                self.stackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }
        }

        let contactIcon = preferences.contactThumbnail(56, stroke: 0)
        let contactLabel = preferences.contact?.givenName
        self.add(contactIcon, label: contactLabel) {
            let contactURL = NSURL(string: "my-other:/contact")!
            
            self.delegate?.iconViewController(self, didRequestOpenURL: contactURL)
        }
        
        let color = PreferencesManager.tintColor
        let gradient = UIImage.imageWithGradient(color, size: CGSize(width: 56, height: 56)).circularImage(56)
        
        if let url = preferences.messageURL {
            let icon = gradient?.overlay(UIImage(named: "message")!, color: UIColor.whiteColor())
            let text = "Message"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didOpenMessages()
            }
        }
        
        if let url = preferences.callURL {
            let icon = gradient?.overlay(UIImage(named: "call")!, color: UIColor.whiteColor())
            let text = "Call"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didStartCall()
            }
        }
        
        if let url = preferences.facetimeURL {
            let icon = gradient?.overlay(UIImage(named: "facetime")!, color: UIColor.whiteColor())
            let text = "FaceTime"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didStartFaceTime()
            }
        }
    }

    private func add(icon: UIImage?, label: String?, handler: () -> Void) {
        let stackView = UIStackView()
        stackView.alignment = .Center
        stackView.axis = .Vertical
        stackView.distribution = .EqualSpacing
        stackView.spacing = 5
        
        let iconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        iconView.image = icon
        stackView.addArrangedSubview(iconView)
        
        let textView = UILabel()
        textView.text = label
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        stackView.addArrangedSubview(textView)
        
        let gesture = TapGestureRecognizer(handler: handler)
        stackView.addGestureRecognizer(gesture)

        self.stackView.addArrangedSubview(stackView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    class TapGestureRecognizer: UITapGestureRecognizer {

        let handler: () -> Void
        
        init(handler: () -> Void) {
            self.handler = handler

            super.init(target: nil, action: nil)

            self.numberOfTapsRequired = 1
            self.numberOfTouchesRequired = 1
            self.addTarget(self, action: #selector(tapped))
        }

        @objc private func tapped() {
            self.handler()
        }
        
    }

}
