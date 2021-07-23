//
//  Protocols.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//

import UIKit

///Confirming to this protocol ensures ability to animate with custom animations
public protocol Animatable{
    /// animates the protocol instance with given animations and provides a completion handler
    /// - Parameters:
    ///   - animations: any escaping closure
    ///   - completion: any  closure which takes in boolean
    ///   - animationOptions: list of options to supported for UIView animation
    func animate(animations: @escaping () -> Void, animationOptions : UIView.AnimationOptions , completion: ((Bool) -> Void)?)
}

public typealias DraggableItem = Draggable & UIViewController

public protocol Draggable{
    var overlayCoordinator : OverlayCoordinator? { get set }
    func draggableView() -> UIScrollView?
}

public protocol OverlayCoordinatorDelegate : AnyObject{
    func overlaySheet(_ container : UIView?, completeTranslationWith animations: @escaping ((_ percent: CGFloat) -> Void) -> Void)
    func overlaySheet(_ container: UIView?, didChange state: OverlayTranslationState)
    func overlaySheet(_ container: UIView?, didPresent state: OverlayTranslationState)
}

public protocol OverlayCoordinatorDataSource : AnyObject{
    var animator : Animator? { get }
    func overlaySheetPositions(_ height : CGFloat) -> [CGFloat]
    func initialPosition(_ height : CGFloat) -> CGFloat
    func elasticTop(_ total : CGFloat, _ limit : CGFloat) -> CGFloat
    func elasticBottom(_ total : CGFloat, _ limit : CGFloat) -> CGFloat
}

