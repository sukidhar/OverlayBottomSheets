//
//  OverlayTranslationState.swift
//  OverlayBottomSheet
//
//  Created by Sukidhar Darisi on 22/07/21.
//

#if !os(macOS)
import UIKit

public enum OverlayTranslationState {
    case animating(_ minYPosition: CGFloat, _ percent: CGFloat)
    case start(_ minYPosition: CGFloat, _ percent: CGFloat)
    case finish(_ minYPosition: CGFloat, _ percent: CGFloat)
}
#endif
