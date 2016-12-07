import UIKit

class CollectionViewLayout: UICollectionViewFlowLayout {

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint?

    override func prepareLayout() {
        self.prepareLayoutDimensions()
        super.prepareLayout()
    }
    
    private func prepareLayoutDimensions() {
        guard let collectionView = self.collectionView else {
            return
        }

        let spacing: CGFloat = 15

        let collectionViewHeight = collectionView.frame.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom
        let collectionViewWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right

        let cellsPerRow: CGFloat = collectionViewWidth > collectionViewHeight ? 2 : 1
        let cellsPerColumn = ceil(CGFloat(collectionView.numberOfItemsInSection(0)) / max(1, cellsPerRow))

        if let headerHeightConstraint = self.headerHeightConstraint {
            let defaultHeaderHeight: CGFloat = collectionViewWidth > collectionViewHeight ? 80 : 100.0
            let defaultCellHeight = max(80, ((collectionViewHeight - spacing - defaultHeaderHeight - spacing) / cellsPerColumn) - spacing)
            let evenHeight = max(80, ((collectionViewHeight - spacing) / (cellsPerColumn + 1)) - spacing)

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

        let cellHeight = max(80, ((collectionViewHeight - self.sectionInset.top) / cellsPerColumn) - spacing)
        let cellWidth = ((collectionViewWidth - spacing) / max(1, cellsPerRow)) - spacing
        
        self.itemSize = CGSize(width: cellWidth, height: cellHeight)
        self.minimumLineSpacing = spacing
    }

}
