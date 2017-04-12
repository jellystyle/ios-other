import UIKit

class CollectionViewLayout: UICollectionViewFlowLayout {

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint?

    override func prepare() {
        self.prepareLayoutDimensions()
        super.prepare()
    }

	var isPad: Bool {
		guard let collectionView = self.collectionView else {
			return false
		}

		return collectionView.traitCollection.horizontalSizeClass == .regular && collectionView.traitCollection.verticalSizeClass == .regular
	}

	var collectionViewSize: CGSize {
		guard let collectionView = self.collectionView else {
			return .zero
		}

		let width = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right
		let height = collectionView.frame.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom

		return CGSize(width: width, height: height)
	}

	var isLandscape: Bool {
		return self.collectionViewSize.width > self.collectionViewSize.height
	}

	var minimumCellHeight: CGFloat {
		return self.isPad ? 140 : 80
	}
    
    fileprivate func prepareLayoutDimensions() {
        guard let collectionView = self.collectionView else {
            return
        }

        let spacing: CGFloat = 15

        let cellsPerRow: CGFloat = self.isLandscape ? 2 : 1
		let cellsPerColumn = ceil(CGFloat(collectionView.numberOfItems(inSection: 0)) / cellsPerRow)

        if let headerHeightConstraint = self.headerHeightConstraint, self.isPad {
            let evenHeight = min(200, max(self.minimumCellHeight, ((self.collectionViewSize.height - spacing) / (cellsPerColumn + 1)) - (spacing * 2)))
			self.sectionInset = UIEdgeInsets(top: evenHeight - spacing, left: spacing, bottom: spacing, right: spacing)
            headerHeightConstraint.constant = self.sectionInset.top
		}
		else if let headerHeightConstraint = self.headerHeightConstraint, !self.isPad {
			let defaultHeaderHeight: CGFloat = self.isLandscape ? 80 : 100.0
			let defaultCellHeight = max(self.minimumCellHeight, ((self.collectionViewSize.height - spacing - defaultHeaderHeight - spacing) / cellsPerColumn) - spacing)
			let evenHeight = max(self.minimumCellHeight, ((self.collectionViewSize.height - spacing) / (cellsPerColumn + 1)) - spacing)

			if evenHeight >= defaultCellHeight {
				self.sectionInset = UIEdgeInsets(top: spacing + evenHeight + spacing, left: spacing, bottom: spacing, right: spacing)
			}
			else {
				self.sectionInset = UIEdgeInsets(top: spacing + defaultHeaderHeight + spacing, left: spacing, bottom: spacing, right: spacing)
			}

			headerHeightConstraint.constant = self.sectionInset.top
		}
		else {
            self.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        }

        let cellHeight = max(self.minimumCellHeight, ((self.collectionViewSize.height - self.sectionInset.top) / cellsPerColumn) - spacing)
        let cellWidth = ((self.collectionViewSize.width - spacing) / cellsPerRow) - spacing
        
        self.itemSize = CGSize(width: cellWidth, height: cellHeight)
        self.minimumLineSpacing = spacing
    }

}
