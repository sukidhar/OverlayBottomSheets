//
//  Animator.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//
#if !os(macOS)
import UIKit

public class Animator : Animatable{
    public func animate(animations: @escaping () -> Void, animationOptions: UIView.AnimationOptions = [.allowUserInteraction, .curveEaseInOut], completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: animationOptions, animations: animations, completion: completion)
    }
}
#endif
