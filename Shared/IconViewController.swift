import UIKit

protocol IconViewControllerDelegate {
    
    func iconViewController(_ iconViewController: UIViewController, didRequestOpenURL url: URL)
    
}

class IconViewController: UIViewController {
    
    //! The shared preferences manager.
    let preferences = PreferencesManager.sharedManager
    
    var delegate: IconViewControllerDelegate? = nil
    
    fileprivate var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.preservesSuperviewLayoutMargins = true

        stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering

        self.view.addSubview(stackView)
        stackView.anchorHeight(to: self.view.layoutMarginsGuide)
        stackView.anchorWidth(to: self.view.layoutMarginsGuide, withMaximum: 500, alignedTo: .center)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadIcons()
    }
    
    @objc fileprivate func loadIcons() {
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
            let contactURL = URL.contactOther
            
            self.delegate?.iconViewController(self, didRequestOpenURL: contactURL)
        }
        
        let color = PreferencesManager.tintColor
        let gradient = UIImage.imageWithGradient(color, size: CGSize(width: 56, height: 56)).circularImage(56)
        
        if let url = preferences.messageURL {
            let icon = gradient?.overlay(UIImage(named: "message")!, color: UIColor.white)
            let text = "Message"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didOpenMessages()
            }
        }
        
        if let url = preferences.callURL {
            let icon = gradient?.overlay(UIImage(named: "call")!, color: UIColor.white)
            let text = "Call"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didStartCall()
            }
        }
        
        if let url = preferences.facetimeURL {
            let icon = gradient?.overlay(UIImage(named: "facetime")!, color: UIColor.white)
            let text = "FaceTime"
            self.add(icon, label: text) {
                self.delegate?.iconViewController(self, didRequestOpenURL: url)
                
                PreferencesManager.sharedManager?.didStartFaceTime()
            }
        }
    }

    fileprivate func add(_ icon: UIImage?, label: String?, handler: @escaping () -> Void) {
		let container = UIView()
		container.translatesAutoresizingMaskIntoConstraints = false
		container.widthAnchor.constraint(equalToConstant: 56).isActive = true

		let iconView = UIImageView(image: icon)
		iconView.translatesAutoresizingMaskIntoConstraints = false
		iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor).isActive = true
		container.addSubview(iconView)

        let textView = UILabel()
		textView.allowsDefaultTighteningForTruncation = true
		textView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
        textView.text = label
		textView.textAlignment = .center
		textView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(textView)

		iconView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
		textView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 5).isActive = true
		textView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
		iconView.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
		iconView.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
		textView.leftAnchor.constraint(equalTo: container.leftAnchor, constant: -5).isActive = true
		textView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: 5).isActive = true

		let gesture = TapGestureRecognizer(handler: handler)
		container.addGestureRecognizer(gesture)

		self.stackView.addArrangedSubview(container)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    class TapGestureRecognizer: UITapGestureRecognizer {

        let handler: () -> Void
        
        init(handler: @escaping () -> Void) {
            self.handler = handler

            super.init(target: nil, action: nil)

            self.numberOfTapsRequired = 1
            self.numberOfTouchesRequired = 1
            self.addTarget(self, action: #selector(tapped))
        }

        @objc fileprivate func tapped() {
            self.handler()
        }
        
    }

}
