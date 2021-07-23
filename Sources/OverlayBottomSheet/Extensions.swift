//
//  Extensions.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//

import UIKit

// MARK:  Draggable
public extension Draggable{
    /// Default implementation of draggable
    /// - Returns: nil by default
    func draggableView()->UIScrollView?{
        return nil
    }
}

// MARK:  UIViewController
extension UIViewController : OverlayCoordinatorDataSource{
    /// Adds a child controller in the given container
    /// - Parameters:
    ///   - child: child viewController
    ///   - container: view container
    ///   - animated: default is true, determines whether to animate the subject or not
    ///   - topInset: inset from top of the frame
    ///   - completion: any completion called before return
    func add(controller child: UIViewController, in container : UIView, animated : Bool = true, topInset : CGFloat , completion : (()->Void)? = nil){
        addChild(child)
        container.addSubview(child.view)
        child.didMove(toParent: self)
        let frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.height - topInset)
        if animated{
            container.frame = frame.offsetBy(dx: 0, dy: frame.height)
            child.view.frame = container.bounds
            UIView.animate(withDuration: 0.3) {
                container.frame = frame
            } completion: { _ in
                completion?()
            }
        }else{
            container.frame = frame
            child.view.frame = container.bounds
            completion?()
        }
    }
    
    /// removes the current controller from parent
    func removeFromParentController(){
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

// MARK:  UIView
extension UIView {
    /// Sets constraints to the anchors
    /// - Parameters:
    ///   - view: view that should relatively be  constrained to
    ///   - insets: insets from the reference view
    func pinToEdges(to view: UIView, insets: UIEdgeInsets = .zero) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
    }
    
    /// Gets a constraint with the given constraint attribute
    /// - Parameters:
    ///   - parent: parent view controller
    ///   - attribute: layout attribute
    /// - Returns: layout constraint 
    func constraint(_ parent: UIViewController, for attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        return parent.view.constraints.first(where: { (constraint) -> Bool in
            constraint.firstItem as? UIView == self && constraint.firstAttribute == attribute
         })
    }
}

// MARK:  Array
extension Array where Element == CGFloat {
    func nearest(to x: CGFloat) -> CGFloat {
        return self.reduce(self.first!) { abs($1 - x) < abs($0 - x) ? $1 : $0 }
    }
}

// MARK:  OverlayCoordinatorDelegate
extension OverlayCoordinatorDelegate{
    public func overlaySheet(_ container : UIView?, completeTranslationWith animations: @escaping ((_ percent: CGFloat) -> Void) -> Void){ }
    public func overlaySheet(_ container: UIView?, didChange state: OverlayTranslationState){ }
    public func overlaySheet(_ container: UIView?, didPresent state: OverlayTranslationState){ }
}

// MARK:  OverlayCoordinatorDataSource
extension OverlayCoordinatorDataSource{
    public var animator : Animator? {
        return Animator()
    }
    
    /// Defailt implementation of sheetPositions
    /// - Parameter height: screen height
    /// - Returns: an array of 2 positions, min and max positions
    public func overlaySheetPositions(_ height : CGFloat) -> [CGFloat]{
        return [0.2,0.7].map { $0 * height }
    }
    
    /// Default implementation for initial position
    /// - Parameter height: screen height
    /// - Returns: minimum position
    public func initialPosition(_ height : CGFloat) -> CGFloat
    {
        return 0.2 * height
    }
    
    public func elasticTop(_ total : CGFloat, _ limit : CGFloat) -> CGFloat
    {
        let value = limit * (1 - log10(total / limit))
        guard !value.isNaN, value.isFinite else {
            return total
        }
        return value
    }
    
    public func elasticBottom(_ total : CGFloat, _ limit : CGFloat) -> CGFloat
    {
        let value = limit * (1 + log10(total / limit))
        guard !value.isNaN, value.isFinite else {
            return total
        }
        return value
    }
}
