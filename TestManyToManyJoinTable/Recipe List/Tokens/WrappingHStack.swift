//
//  WrappingHStack.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//


//
//  RecipeKeywordSection.swift
//  Cookery
//
//  Created by Ben Davis on 3/11/25.
//

import SwiftUI
import UserInterfaceExtensions

private extension UnitPoint {
    init(_ alignment: Alignment) {
        switch alignment {
        case .top: self = .top
        case .topLeading: self = .topLeading
        case .topTrailing: self = .topTrailing
        case .bottom: self = .bottom
        case .bottomLeading: self = .bottomLeading
        case .bottomTrailing: self = .bottomTrailing
        case .leading: self = .leading
        case .trailing: self = .trailing
        default: self = .center
        }
    }
}

@frozen
public struct WrappingHStack: Layout {
    
    public struct Element {
        let index: Int
        let size: CGSize
        let xOffset: CGFloat
    }
    
    public struct Row {
        var elements: [Element] = []
        var height: CGFloat = 0
        var width: CGFloat = 0
        var yOffset: CGFloat = 0
    }
    
    public struct Cache {
        // We track the proposal that generated the current cache
        var lastProposal: ProposedViewSize?
        
        var rows: [Row] = []
        var totalSize: CGSize = .zero
    }
    
    let horizontalSpacing: CGFloat?
    let verticalSpacing: CGFloat?
    let alignment: Alignment
    let fitContentSize: Bool
    
    public init(horizontalSpacing: CGFloat? = nil,
                verticalSpacing: CGFloat? = nil,
                alignment: Alignment = .center,
                fitContentSize: Bool = false) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
        self.fitContentSize = fitContentSize
    }
    
    public func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    public func updateCache(_ cache: inout Cache, subviews: Subviews) {
        // Crucial: If subviews change (data updates), we must invalidate the cache
        // so the layout recalculates with the new views.
        cache.lastProposal = nil
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        // OPTIMIZATION 1: Check if we have a valid cache for this proposal
        if let lastProposal = cache.lastProposal, lastProposal == proposal {
            return cache.totalSize
        }
        
        // If not, compute layout and update cache
        calculateLayout(proposal: proposal, subviews: subviews, cache: &cache)
        
        return cache.totalSize
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        // Ensure layout is calculated (in case placeSubviews is called without sizeThatFits, though rare)
        if cache.lastProposal != proposal {
            calculateLayout(proposal: proposal, subviews: subviews, cache: &cache)
        }
        
        let anchor = UnitPoint(alignment)
        let width = bounds.width
        
        for row in cache.rows {
            for element in row.elements {
                // Align the row horizontally within the container
                let elementAnchorX = anchor.x * (width - row.width)
                // Align the element vertically within the row
                let elementAnchorY = anchor.y * (row.height - element.size.height)
                
                let origin = CGPoint(
                    x: bounds.minX + element.xOffset + elementAnchorX,
                    y: bounds.minY + row.yOffset + elementAnchorY
                )
                
                subviews[element.index].place(at: origin, proposal: ProposedViewSize(element.size))
            }
        }
    }
    
    // MARK: - Layout Calculation
    
    private func calculateLayout(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let resolvedProposal = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 10_000, height: 10_000))
        let childProposal = ProposedViewSize(resolvedProposal)
        
        var rows: [Row] = []
        var currentRow = Row()
        var currentX: CGFloat = 0
        var minWidth: CGFloat = 0
        var minHeight: CGFloat = 0

        // OPTIMIZATION 2: Loop Fusion
        // We iterate once. We calculate size and place it immediately.
        // This avoids allocating the large `sizes` array.
        
        for (index, subview) in subviews.enumerated() {
            // Expensive call happens here, but strictly once per layout invalidation
            let size = subview.sizeThatFits(childProposal)
            
            let spacing: CGFloat
            if currentRow.elements.isEmpty {
                spacing = 0
            } else {
                // We can still access the previous subview safely via index - 1
                spacing = horizontalSpacingValue(subviews[index - 1], subview)
            }
            
            let fitsInRow = currentX + size.width + spacing <= resolvedProposal.width
            
            if !fitsInRow && !currentRow.elements.isEmpty {
                // Finalize current row
                currentRow.width = currentX
                rows.append(currentRow)
                
                // Track max width for the container size
                minWidth = max(minWidth, currentX)
                
                // Reset for new row
                currentRow = Row()
                currentX = 0
                // Reset spacing for new row (first item has 0 spacing)
            }
            
            let actualSpacing = currentRow.elements.isEmpty ? 0 : spacing
            let xOffset = currentX + actualSpacing
            
            currentRow.elements.append(Element(index: index, size: size, xOffset: xOffset))
            currentX = xOffset + size.width
        }
        
        // Append the final row
        if !currentRow.elements.isEmpty {
            currentRow.width = currentX
            rows.append(currentRow)
            minWidth = max(minWidth, currentX)
        }
        
        // Calculate Vertical Offsets (Second pass is unavoidable for vertical stacking logic, but fast)
        var currentY: CGFloat = 0
        var previousMaxHeightIndex: Int?
        
        for i in rows.indices {
            // Optimization: We can find max height while building the row above if we wanted,
            // but doing it here keeps the logic cleaner for vertical spacing.
            let maxHeightElement = rows[i].elements.max(by: { $0.size.height < $1.size.height })
            guard let element = maxHeightElement else { continue }
            
            let spacing = previousMaxHeightIndex.map {
                verticalSpacingValue(subviews[$0], subviews[element.index])
            } ?? 0
            
            rows[i].yOffset = currentY + spacing
            rows[i].height = element.size.height
            currentY += rows[i].height + spacing
            previousMaxHeightIndex = element.index
        }
        
        minHeight = currentY
        
        // Final Layout Sizing
        let totalWidth = fitContentSize ? minWidth : max(proposal.width ?? minWidth, minWidth)
        
        // Update Cache
        cache.rows = rows
        cache.totalSize = CGSize(width: totalWidth, height: minHeight)
        cache.lastProposal = proposal
    }
    
    // MARK: - Spacing helpers remain the same
    @inline(__always)
    private func horizontalSpacingValue(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        horizontalSpacing ?? lhs.spacing.distance(to: rhs.spacing, along: .horizontal)
    }

    @inline(__always)
    private func verticalSpacingValue(_ lhs: LayoutSubview, _ rhs: LayoutSubview) -> CGFloat {
        verticalSpacing ?? lhs.spacing.distance(to: rhs.spacing, along: .vertical)
    }
}


#Preview {
    WrappingHStack {
        Text("Veggies")
        Text("Peas")
        Text("Pork")
        Text("Chicken")
    }
}
