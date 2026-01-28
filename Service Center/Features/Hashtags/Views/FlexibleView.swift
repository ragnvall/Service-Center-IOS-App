//
//  FlexibleView.swift
//  Service Center
//
//  Created by Kevin on 2/12/25.
//
import SwiftUI
//FlexibleStack comes from https://github.com/minacod/SwiftUILayoutTutorial/blob/main/SwiftUILayout/FlexibleStack.swift
struct FlexibleStack : Layout {
    
    var spacing: CGFloat = 10
    var alignment: HorizontalAlignment = .center
    //Initializes a cache.Cache used so that view doesn't need to do size calculations(for determining how to place each subview) every time the view is reloaded
    func makeCache(subviews: Subviews) -> Cache {
        return .init(rows: [], height: 0)
    }
    //Determines layout size given the subviews(each tag), and parent size in proposal(ie, view size of CreatePostVIew)
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        //maxWidth: cannot exceed the size of the parent view
        let maxWidth = proposal.width ?? 0
        //
        cache = caculateRows(maxWidth, proposal: proposal, subviews: subviews)
        return .init(width: maxWidth, height: cache.height)
    }
    //determines subview(row) placement, based on size of ProposedViewSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        var origin = bounds.origin
        var subviews = subviews
        for row in cache.rows {
            //reset to the row beginning
            origin.x = getRowXOrigin(bounds: bounds, rowWidth: row.size.width)
            for size in row.viewsSizes {
                guard let view = subviews.popFirst() else { return }
                let width = size.width
                view.place(at: origin, proposal: .init(size))
                origin.x += width + spacing
            }
            //move to the next row
            origin.y += row.size.height + spacing
        }
    }
    
    private func getRowXOrigin(bounds: CGRect, rowWidth: CGFloat) -> CGFloat {
        switch alignment {
        case .center: return (bounds.minX + bounds.maxX - rowWidth)/2
        case .trailing: return bounds.maxX - rowWidth
        default: return bounds.minX
        }
    }
    //Function determines the number of rows needed given the width,
    private func caculateRows(_ maxWidth: CGFloat, proposal: ProposedViewSize, subviews: Subviews) -> Cache {
        var rows : [Cache.Row] = []
        var height: CGFloat = 0
        var subviews = subviews
        while !subviews.isEmpty {
            guard let row = calculateRow(maxWidth, proposal: proposal, subviews: &subviews) else { break }
            rows.append(row)
            height += row.size.height + spacing
        }
        height -= spacing
        return .init(rows: rows, height: height)
    }
    
    
    private func calculateRow(_ maxWidth: CGFloat, proposal: ProposedViewSize, subviews: inout Subviews) -> Cache.Row? {
        var viewSizes : [CGSize] = []
        var rowHeight : CGFloat = 0
        var origin = CGRect.zero.origin
        var hasSpace : (CGSize) -> Bool = {(origin.x + $0.width + spacing) <= maxWidth}
        //keep iterating untill row is filled
        while true {
            // if no views left
            //if view size bigger than available space
            guard
                let size = subviews.first?.sizeThatFits(proposal),
                hasSpace(size)
            else {
                let rowSize = CGSize(width: origin.x - spacing , height: rowHeight)
                return viewSizes.isEmpty ? nil : .init(viewsSizes: viewSizes, size: rowSize)
            }
            
            _ = subviews.popFirst()
            viewSizes.append(size)
            rowHeight = rowHeight > size.height ? rowHeight : size.height
            origin.x += (size.width + spacing)
            
        }
        
        let rowSize = CGSize(width: origin.x - spacing , height: rowHeight)
        return viewSizes.isEmpty ? nil : .init(viewsSizes: viewSizes, size: rowSize)
    }
    
    
}


extension FlexibleStack {
    
    struct Cache {
        let rows: [Row]
        let height: CGFloat
        
        struct Row {
            let viewsSizes: [CGSize]
            let size : CGSize
        }
    }
    
}
