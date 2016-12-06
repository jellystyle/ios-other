import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var text: String? {
        get {
            return self.textLabel.text
        }
        set(text) {
            self.textLabel.text = text
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateGradient()
    }
    
    func updateGradient() {
        guard let collectionView = self.superview as? UICollectionView else {
            return
        }

        let collectionViewOffset = collectionView.contentOffset.y - collectionView.contentInset.top
        let collectionViewHeight = collectionView.bounds.height
        
        let factor: CGFloat = 2 // Adjusts the "strength" of the generated gradient
        
        let cellFrame = self.convertRect(self.contentView.frame, toView: collectionView)
        let cellTop = factor - (factor * ((cellFrame.origin.y - collectionViewOffset) / collectionViewHeight))
        let cellBottom = cellTop - (factor * (cellFrame.size.height / collectionViewHeight))

        let gradientColor = PreferencesManager.tintColor.colorWithAlphaComponent(0.8)
        let gradientSize = CGSize(width: 20, height: cellFrame.size.height)
        let gradient = UIImage.imageWithGradient(gradientColor, size: gradientSize, top: cellTop, bottom: cellBottom)

        (self.backgroundView as? UIImageView)?.image = gradient
        (self.selectedBackgroundView as? UIImageView)?.image = gradient
    }
    
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    func initialize() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 10.0
        
        self.textLabel.font = UIFont.systemFontOfSize(30)
        self.textLabel.numberOfLines = 0
        self.textLabel.textAlignment = .Center
        self.textLabel.textColor = PreferencesManager.backgroundColor

        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.contentView.layoutMarginsDidChange()

        self.contentView.addSubview(self.textLabel)
        self.textLabel.anchor(to: self.contentView.layoutMarginsGuide)
        
        self.backgroundView = UIImageView()
        self.selectedBackgroundView = UIImageView()
    }
    
    override func prepareForReuse() {
        self.textLabel.text = nil
    }

}
