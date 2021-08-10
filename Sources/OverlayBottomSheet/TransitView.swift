//
//  TransitView.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//
#if !os(macOS)

import UIKit

public class TransitView : UIView{
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

#endif
