//
//  EqualWidthVStack.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import Foundation
import SwiftUI

/// A horizontal stack layout that proposes a size to each subview equal to
/// that of the largest subview
struct EqualWidthVStackLayout: Layout {
    
    /// The spacing between views
    var spacing: Double = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        return subviews.reduce(CGSize(width: 0, height: 0)) { partialResult, subview in
            return CGSize(width: max(partialResult.width, subview.sizeThatFits(.unspecified).width), height: subview.sizeThatFits(.unspecified).height)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let elementSize = elementSize(proposal: .unspecified, subviews: subviews)
        var point = bounds.origin
        point.x += elementSize.width / 2
        point.y += elementSize.height / 2 - spacing / 2
        let placementProposal = ProposedViewSize(width: elementSize.width, height: elementSize.height)
        for view in subviews {
            view.place(at: point, anchor: .center, proposal: placementProposal)
            point.y += (elementSize.height + spacing)
        }
    }
    
    func elementSize(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
        var maxSize = CGSize.zero
        for view in subviews {
            let size = view.sizeThatFits(proposal)
            maxSize.width = max(maxSize.width, size.width)
            maxSize.height = max(maxSize.height, size.height)
        }
        return maxSize
    }
}
