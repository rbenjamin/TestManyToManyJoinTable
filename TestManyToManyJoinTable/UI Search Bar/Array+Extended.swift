//
//  File.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/19/26.
//

import Foundation

extension Array {
    
    
    /// Returns the maximum valid index, up to `offset` from ``Array.endIndex``.  Always progresses toward array `startEndex`, regardless of +/- state of `offset`.
    /// - Parameter offset: The maximum distance from endIndex.
    /// - Returns: The maximum valid index from `offset`.
    func maxOffsetUpTo(offset: Int) -> Array.Index {
        var endIndex: Array.Index = endIndex
        let absOffset = abs(offset)
        var tryOffset = 0
        while tryOffset < absOffset {
            defer {
                tryOffset += 1
            }
            let previousIndex = self.index(before: endIndex)
            
            if previousIndex >= startIndex {
                endIndex = self.index(before: endIndex)
            } else {
                return endIndex
            }
        }
        return endIndex
    }
}
