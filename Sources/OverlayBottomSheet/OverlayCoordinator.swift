//
//  OverlayCoordinator.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//

import UIKit

public class OverlayCoordinator : NSObject{
    public weak var parent : UIViewController!
    private var container : UIView?
    public weak var dataSource :  OverlayCoordinatorDataSource! {
        didSet{
            let positions = dataSource.overlaySheetPositions(availableHeight)
            minimumOveralyPosition = positions.min()
            maximumOverlayPosition = positions.max()
        }
    }
    public weak var delegate : OverlayCoordinatorDelegate?
    private var minimumOveralyPosition : CGFloat?
    private var maximumOverlayPosition : CGFloat?
    public var availableHeight: CGFloat {
        return parent.view.frame.height
    }
    public var draggables = [DraggableItem]()
    private var dropShadowView : TransitView?
    private var tolerance : CGFloat = 0.0000001
    public var isUsingNavigationController = false
    
    private var lastAnimatedValue: CGFloat = 0.0
    private var cornerRadius : CGFloat = 0{
        didSet{
            applyDefaultShadoowConfiguration()
            clearShadowBackground()
        }
    }

    public init(parent: UIViewController, delegate: OverlayCoordinatorDelegate? = nil) {
        super.init()
        self.parent = parent
        self.dataSource = parent
        self.delegate = delegate
        let positions = dataSource.overlaySheetPositions(availableHeight)
        minimumOveralyPosition = positions.min()
        maximumOverlayPosition = positions.max()
    }
    
    public func createContainer(with config : @escaping (UIView)->Void){
        let view = TransitView()
        self.container = view
        config(view)
        container?.pinToEdges(to: parent.view)
        container?.constraint(parent, for: .top)?.constant = dataSource.overlaySheetPositions(availableHeight)[0]
        setPosition(dataSource.initialPosition(availableHeight), animated: false)
    }
    
    public func addOverlaySheet(_ item : UIViewController, to parent : UIViewController, didContainerCreate : ((UIView)->Void)? = nil){
        self.isUsingNavigationController = item is UINavigationController
        let container = TransitView()
        self.container = container
        parent.view.addSubview(container)
        let position = dataSource.initialPosition(availableHeight)
        parent.add(controller: item, in: container, animated: true, topInset: position) { [weak self] in
            guard let _self = self else{
                return
            }
            _self.delegate?.overlaySheet(container, didPresent: .finish(position, _self.calculatePercent(at: position)))
        }
        didContainerCreate?(container)
        setPosition(dataSource.initialPosition(availableHeight), animated: false)
    }
    
    public func addOverlayChild(_ item : DraggableItem){
        parent.addChild(item)
        container!.addSubview(item.view)
        item.didMove(toParent: parent)
        item.view.frame = container!.frame.offsetBy(dx: 0, dy: availableHeight)
        UIView.animate(withDuration: 0.3) {
                   item.view.frame = self.container!.bounds
        }
    }
    
    private func getInitialFrame() -> CGRect {
        let minY = parent.view.bounds.minY + dataSource.initialPosition(availableHeight)
        return CGRect(x: parent.view.bounds.minX,
                      y: minY,
                      width: parent.view.bounds.width,
                      height: parent.view.bounds.maxY - minY)
    }
    
    public func addDropShadowIfNotExists(_ config : ((UIView?)->Void)? = nil){
        guard dropShadowView == nil else {
            return
        }
        dropShadowView = TransitView()
        parent.view.insertSubview(dropShadowView!, belowSubview: container!)
        dropShadowView?.pinToEdges(to: container!, insets: UIEdgeInsets(top: -getInitialFrame().minY, left: 0, bottom: 0, right: 0))
        self.dropShadowView?.layer.masksToBounds = false
        if config == nil {
            applyDefaultShadoowConfiguration()
            clearShadowBackground()
        }else{
            config?(dropShadowView!)
        }
    }
    
    private func applyDefaultShadoowConfiguration(){
        dropShadowView?.layer.shadowPath = UIBezierPath(roundedRect: getInitialFrame(),cornerRadius: cornerRadius).cgPath
        dropShadowView?.layer.shadowColor = UIColor.black.cgColor
        dropShadowView?.layer.shadowRadius = CGFloat.init(10)
        dropShadowView?.layer.shadowOpacity = Float.init(0.5)
        dropShadowView?.layer.shadowOffset = CGSize.init(width: 0.0, height: 4.0)
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.0
        animation.toValue = 0.5
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.duration = 0.3
        dropShadowView?.layer.add(animation, forKey: "fadeout")
    }
    
    private func clearShadowBackground() {
        let p = CGMutablePath()
        p.addRect(parent.view.bounds.insetBy(dx: 0, dy: -availableHeight))
        p.addPath(UIBezierPath(roundedRect: getInitialFrame(), cornerRadius: cornerRadius).cgPath)
        let mask = CAShapeLayer()
        mask.path = p
        mask.fillRule = .evenOdd
        dropShadowView?.layer.mask = mask
    }
    
    public func setPosition(_ position : CGFloat, animated : Bool){
        endTranslate(to: position,animated: animated)
    }
    
    public func setCornerRadius(_ radius: CGFloat) {
        self.cornerRadius = radius
    }
    
    public func setToNearest(_ position: CGFloat, animated: Bool) {
         let y = dataSource.overlaySheetPositions(availableHeight).nearest(to: position)
         setPosition(y, animated: animated)
    }
    
    public func endTranslate(to position : CGFloat, animated : Bool = false){
        guard position != 0 else {
            return
        }
        let oldFrame = container!.frame
        let height = max(availableHeight - minimumOveralyPosition!, availableHeight - position)
        let frame = CGRect(x: 0, y: position, width: oldFrame.width, height: height)
        
        self.delegate?.overlaySheet(self.container, didChange: .start(position, self.calculatePercent(at: position)))
        
        if animated{
            self.lastAnimatedValue = position
            dataSource.animator?.animate(animations: {
                self.delegate?.overlaySheet(self.container, completeTranslationWith: { (animation) in
                    animation(self.calculatePercent(at: position))
                })
                self.container!.frame = frame
                self.parent.view.layoutIfNeeded()
            }, completion: { completed in
                if self.lastAnimatedValue != position{
                    return
                }
                self.delegate?.overlaySheet(self.container, didChange: .finish(position, self.calculatePercent(at: position)))
                if position >= self.availableHeight{
                    self.removeSheet()
                }
            })
        }else{
            self.container!.frame = frame
            self.delegate?.overlaySheet(self.container, didChange: .finish(position, self.calculatePercent(at: position)))
        }
    }
    
    public func removeSheetChild<T:DraggableItem>(item : T){
        stopTracking(item: item)
        let _item = isUsingNavigationController ? item.navigationController! : item
        UIView.animate(withDuration: 0.3, animations: {
            _item.view.frame = _item.view.frame.offsetBy(dx: 0, dy: _item.view.frame.height)
        }) { (finished) in
            _item.removeFromParent()
        }
    }
    
    public func removeSheet(_ block : ((_ container : UIView?)->Void)? = nil){
        self.draggables.removeAll()
        guard block == nil else {
            block?(self.container)
            return
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let _self = self else {
                return
            }
            _self.container!.frame = _self.container!.frame.offsetBy(dx: 0, dy: _self.parent.view.frame.height)
        } completion: { [weak self] completed in
            self?.container?.removeFromSuperview()
            self?.removeDropShadow()
        }
    }
    
    public func removeDropShadow(){
        self.dropShadowView?.removeFromSuperview()
    }
    
    private func calculatePercent(at position: CGFloat) -> CGFloat {
        return (availableHeight - position) / (availableHeight - minimumOveralyPosition!) * 100
    }
    
    private func isTracking<T: DraggableItem>(item: T) -> Bool {
        return draggables.contains { (vc) -> Bool in
            vc == item
        }
    }
    
    public func startTracking<T:DraggableItem>(item : T){
        guard !isTracking(item: item) else {
            return
        }
        item.draggableView()?.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(handleViewPan(_:)))
        item.view.addGestureRecognizer(panGestureRecogniser)
        let navigationBarPanGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(handleViewPan(_:)))
        panGestureRecogniser.delegate = self
        navigationBarPanGestureRecogniser.delegate = self
        item.navigationController?.navigationBar.addGestureRecognizer(navigationBarPanGestureRecogniser)
        draggables.append(item)
    }
    
    public func stopTracking<T:DraggableItem>(item : T){
        draggables.removeAll { (vc) -> Bool in
            vc == item
        }
    }
    
    @objc private func handleViewPan(_ recognizer: UIPanGestureRecognizer) {
        handlePan(recognizer)
    }
    
    @objc private func handleScrollPan(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView else {
            return
        }
        handlePan(recognizer, scrollView: scrollView)
    }
    
    private var lastContentOffset : CGPoint = .zero
    private var lastY : CGFloat = 0
    private var totalTranslationMinY: CGFloat!
    private var totalTranslationMaxY: CGFloat!


    
    private func handlePan(_ recognizer: UIPanGestureRecognizer, scrollView: UIScrollView? = nil) {
        let dy = recognizer.translation(in: recognizer.view).y
        let vel = recognizer.velocity(in: recognizer.view)
        
        switch recognizer.state {
        case .began:
            lastY = 0
            if let scroll = scrollView{
                lastContentOffset.y = scroll.contentOffset.y + dy
            }
            totalTranslationMaxY = maximumOverlayPosition!
            totalTranslationMinY = minimumOveralyPosition!
            translate(with: vel, dy: dy, scrollView: scrollView)
        case .changed:
            translate(with: vel, dy: dy, scrollView: scrollView)
        case .ended,.cancelled,.failed:
            guard let scroll = scrollView else {
                self.finishDragging(with: vel, position: container!.frame.minY + dy - lastY)
                return
            }
            let minY = container!.frame.minY
            switch dragDirection(vel) {
            case .up where minY - minimumOveralyPosition! > tolerance:
                scroll.setContentOffset(lastContentOffset, animated: false)
                self.finishDragging(with: vel, position: minY)
            default:
                if !isSheetPosition(minY) {
                    self.finishDragging(with: vel, position: minY)
                }
            }
        default:
            break
        }
    }
    
    func translate(with velocity: CGPoint, dy: CGFloat, scrollView: UIScrollView? = nil) {
        if let scroll = scrollView {
            switch dragDirection(velocity) {
            case .up where (container!.frame.minY - minimumOveralyPosition! > tolerance):
                applyTranslation(dy: dy - lastY)
                scroll.contentOffset.y = lastContentOffset.y
            case .down where scroll.contentOffset.y <= 0 /*&& !scroll.isDecelerating*/:
                applyTranslation(dy: dy - lastY)
                scroll.contentOffset.y = 0
                lastContentOffset = .zero
            default:
                break
            }
        } else {
            applyTranslation(dy: dy - lastY)
        }
        lastY = dy
    }
    
    private func isSheetPosition(_ point: CGFloat) -> Bool {
        return dataSource.overlaySheetPositions(availableHeight).first(where: { (p) -> Bool in
            abs(p - point) < tolerance
        }) != nil
    }
    
    private enum DraggingState {
        case up, down, idle
    }
    
    private func dragDirection(_ velocity: CGPoint) -> DraggingState {
        if velocity.y < 0 {
            return .up
        } else if velocity.y > 0 {
            return .down
        } else {
            return .idle
        }
    }
    
    private func filteredPositions(_ velocity: CGPoint, currentPosition: CGFloat) -> [CGFloat] {
        //dragging up
        if velocity.y < -100 {
            let data = dataSource.overlaySheetPositions(availableHeight).filter { (p) -> Bool in
                p < currentPosition
            }
            if data.isEmpty {
                return dataSource.overlaySheetPositions(availableHeight)
            } else {
                return data
            }
        }
        // dragging down
        else if velocity.y > 100 {
            let data = dataSource.overlaySheetPositions(availableHeight).filter { (p) -> Bool in
                p > currentPosition
            }
            if data.isEmpty {
                return dataSource.overlaySheetPositions(availableHeight)
            } else {
                return data
            }
        } else {
            return dataSource.overlaySheetPositions(availableHeight)
        }
    }
    
    private func applyTranslation(dy: CGFloat) {
        guard dy != 0 else {
            return
        }
        
        let topLimit = minimumOveralyPosition!
        let bottomLimit = maximumOverlayPosition!
        let oldFrame = container!.frame
        
        var newY = oldFrame.minY
        
        if hasExceededTopLimit(oldFrame.minY + dy, topLimit){
            let y = min(0, topLimit - oldFrame.minY)
            totalTranslationMinY -= (dy - y)
            totalTranslationMaxY = maximumOverlayPosition!
            newY = dataSource.elasticTop(totalTranslationMinY, topLimit)
        }
        else if hasExceededBottomLimit(oldFrame.minY + dy, bottomLimit){
            let yy = max(0 , bottomLimit - oldFrame.minY)
            totalTranslationMinY = minimumOveralyPosition!
            totalTranslationMaxY += (dy - yy)
            newY = dataSource.elasticBottom(totalTranslationMaxY, bottomLimit)
        }
        else {
            totalTranslationMinY = minimumOveralyPosition!
            totalTranslationMaxY = maximumOverlayPosition!
            newY += dy
        }
        
        let height = max(availableHeight - minimumOveralyPosition!, availableHeight - newY)
        let frame = CGRect(x: 0, y: newY, width: oldFrame.width, height: height)
        container?.frame = frame
        self.delegate?.overlaySheet(self.container, didChange: .animating(frame.minY, self.calculatePercent(at: frame.minY)))
    }
    
    private func finishDragging(with velocity: CGPoint, position: CGFloat) {
        let y = filteredPositions(velocity, currentPosition: position).nearest(to: position)
        endTranslate(to: y, animated: true)
    }
    
    private func hasExceededTopLimit(_ constant: CGFloat, _ limit: CGFloat) -> Bool {
        return (constant - limit) < tolerance
    }
    
    private func hasExceededBottomLimit(_ constant: CGFloat, _ limit: CGFloat) -> Bool {
        return (constant - limit) > tolerance
    }
    
}

extension OverlayCoordinator : UIGestureRecognizerDelegate{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = otherGestureRecognizer.view as? UIScrollView{
            return scrollView.alwaysBounceVertical
        }else{
            return true
        }
    }
}
