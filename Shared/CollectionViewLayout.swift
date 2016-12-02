import UIKit

class CollectionViewLayout: UICollectionViewFlowLayout {

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint?

    private var dynamicAnimator: UIDynamicAnimator!
    
    private var visibleIndexPathsSet = Set<NSIndexPath>()
    
    private var latestDelta: CGFloat = 0

    override init() {
        super.init()
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    func initialize() {
        dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
    }

    override func prepareLayout() {
        self.prepareLayoutDimensions()
        super.prepareLayout()
        //self.prepareDynamicBehaviours()
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

    /*
    private func prepareDynamicBehaviours() {
        guard let collectionView = self.collectionView else {
            return
        }
        
        let visibleRect = CGRect(origin: collectionView.bounds.origin, size: collectionView.frame.size).insetBy(dx: -100, dy: -100)
        
        let itemsInVisibleRectArray = super.layoutAttributesForElementsInRect(visibleRect) ?? []
        
        let itemsIndexPathsInVisibleRectSet = Set(itemsInVisibleRectArray.map({$0.indexPath}))
        
        let noLongerVisibleBehaviours = (self.dynamicAnimator.behaviors as! [UIAttachmentBehavior]).filter({ behaviour in
            return !itemsIndexPathsInVisibleRectSet.contains((behaviour.items.first as! UICollectionViewLayoutAttributes).indexPath)
        })
        
        for behaviour in noLongerVisibleBehaviours {
            self.dynamicAnimator.removeBehavior(behaviour)
            self.visibleIndexPathsSet.remove((behaviour.items.first as! UICollectionViewLayoutAttributes).indexPath)
        }
        
        let newlyVisibleAttributes = itemsInVisibleRectArray.filter({ attributes in
            return !self.visibleIndexPathsSet.contains(attributes.indexPath)
        })
        
        let touchLocation = collectionView.panGestureRecognizer.locationInView(collectionView)
        
        for attributes in newlyVisibleAttributes {
            var center = attributes.center
            let springBehaviour = UIAttachmentBehavior(item: attributes, attachedToAnchor: center)
            
            springBehaviour.length = 0.0
            springBehaviour.damping = 0.8
            springBehaviour.frequency = 1.0
            
            if CGPoint.zero != touchLocation {
                let yDistanceFromTouch = fabs(touchLocation.y - springBehaviour.anchorPoint.y)
                let xDistanceFromTouch = fabs(touchLocation.x - springBehaviour.anchorPoint.x)
                let scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0
                
                if self.latestDelta < 0 {
                    center.y += max(self.latestDelta, self.latestDelta * scrollResistance)
                }
                else {
                    center.y += min(self.latestDelta, self.latestDelta * scrollResistance)
                }
                
                attributes.center = center
            }
            
            self.dynamicAnimator.addBehavior(springBehaviour)
            self.visibleIndexPathsSet.insert(attributes.indexPath)
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.dynamicAnimator.itemsInRect(rect) as? [UICollectionViewLayoutAttributes]
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return self.dynamicAnimator.layoutAttributesForCellAtIndexPath(indexPath)
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else {
            return false
        }
        
        let delta = newBounds.origin.y - collectionView.bounds.origin.y
        
        self.latestDelta = delta

        let touchLocation = collectionView.panGestureRecognizer.locationInView(collectionView)
        
        for springBehaviour in self.dynamicAnimator.behaviors as! [UIAttachmentBehavior] {
            let yDistanceFromTouch = fabs(touchLocation.y - springBehaviour.anchorPoint.y)
            let xDistanceFromTouch = fabs(touchLocation.x - springBehaviour.anchorPoint.x)
            let scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / 1500.0
            
            let attributes = springBehaviour.items.first as! UICollectionViewLayoutAttributes
            var center = attributes.center
            
            if self.latestDelta < 0 {
                center.y += max(self.latestDelta, self.latestDelta * scrollResistance)
            }
            else {
                center.y += min(self.latestDelta, self.latestDelta * scrollResistance)
            }
            
            attributes.center = center
            
            self.dynamicAnimator.updateItemUsingCurrentState(attributes)
        }
        
        return false
    }
    */

}
