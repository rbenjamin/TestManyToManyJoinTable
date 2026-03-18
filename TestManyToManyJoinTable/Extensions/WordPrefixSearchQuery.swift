//
//  WordPrefixSearchQuery.swift
//  TestManyToManyJoinTable
//
//  Created by Ben Davis on 3/17/26.
//



import Foundation
import RegexBuilder

public struct WordPrefixSearchQuery: Sendable, Equatable {
    let lowercased: String
    let wordCount: Int
    let isEmpty: Bool
    let words: [String.SubSequence]
    
    public static func ==(lhs: WordPrefixSearchQuery, rhs: WordPrefixSearchQuery) -> Bool {
        return lhs.lowercased == rhs.lowercased
    }
    
    init(query: String) {
        isEmpty = query.isEmpty
        let lc = query.lowercased()
        self.lowercased = lc
        let split = lc.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        words = split
        self.wordCount = split.count
    }
    
    
    var isMultiWord: Bool {
        wordCount > 1
    }
}

extension String {
    func sentence(containing range: Range<String.Index>) -> Substring {
        // Ensure the range is within bounds
        precondition(range.lowerBound >= startIndex && range.upperBound <= endIndex)
        
        // Define sentence-ending characters
        let sentenceTerminators: Set<Character> = [".", "!", "?"]

        // --- Search backward for the start of the sentence ---
        var sentenceStart = startIndex
        var idx = range.lowerBound
        while idx > startIndex {
            let prev = self.index(before: idx)
            if sentenceTerminators.contains(self[prev]) {
                // Skip whitespace after punctuation
                sentenceStart = self.index(after: prev)
                while sentenceStart < endIndex, self[sentenceStart].isWhitespace {
                    sentenceStart = self.index(after: sentenceStart)
                }
                break
            }
            idx = prev
        }

        // --- Search forward for the end of the sentence ---
        var sentenceEnd = endIndex
        idx = range.upperBound
        while idx < endIndex {
            if sentenceTerminators.contains(self[idx]) {
                sentenceEnd = self.index(after: idx)
                break
            }
            idx = self.index(after: idx)
        }

        return self[sentenceStart..<sentenceEnd]
    }
    
    /// Removes the first word, including attached punctuation and the trailing space.
    /// Optimized for performance by using String.Index and returning a Substring.
    func dropFirstWord() -> Substring {
        // 1. Find the first space. Everything before this is our "prefix word + punctuation"
        guard let spaceIndex = self.firstIndex(of: " ") else {
            // If there's no space, it's a single word; return empty
            return ""
        }
        
        // 2. The 'drop' point is the character immediately after the first space
        let nextIndex = self.index(after: spaceIndex)
        
        // 3. Return a substring starting from that index
        // Note: This does not copy the string memory; it's O(1) space.
        return self[nextIndex...]
    }
    
    
    /// Toggles between plural and non-plural of string. Only looks at whether the string ends in 's'.
    /// - Returns: Toggled string (either plural or the non-plural version of the string)
    func pluralInverse() -> String {
        return last == "s" ? String(self[..<index(before: endIndex)]) : self.appending("s")
    }
    
    var isPlural: Bool {
        return last == "s"
    }
    
    func rangeOfWholeWord(_ word: String) -> Range<String.Index>? {
        
        let regexExpr = Regex {
            Anchor.wordBoundary
            word
            Anchor.wordBoundary
        }
        return self.firstRange(of: regexExpr)
    }
   

}


extension StringProtocol {
    
    
    func caseInsensitivePrefixSearch(query: WordPrefixSearchQuery) -> Bool {
        guard !query.isEmpty else { return false }
//        if query.isMultiWord {
//            return self.localizedCaseInsensitiveContains(query.lowercased)
//        }
        let query = query.words
        let words = self.lowercased().split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        
        if words.contains(query) {
            return true
        }
        return false
//        return words.contains(where: { $0.hasPrefix(query.lowercased) })
    }
    
    func wordPrefixSearch(query: String) -> Bool {
        guard !query.isEmpty else { return false }

        let lowercasedQuery = query.lowercased()
        let queryWords = lowercasedQuery
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))

        if queryWords.count > 1 {
            return self.localizedCaseInsensitiveContains(lowercasedQuery)
        }

        let words = self.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        
        return words.contains { $0.lowercased().hasPrefix(lowercasedQuery) }
    }

//    private func hasPrefixIgnoringCase(prefix: String) -> Bool {
//        guard let slice = self.prefix(prefix.count).lowercased() else { return false }
//        return slice == prefix
//    }
}

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")
    
    func sanitizedFilename(replacement: String = "-") -> String {
        // Characters that are not allowed in filenames on most file systems
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*:|\"<>.")
        
        // Replace invalid characters with the replacement string
        let sanitized = self.components(separatedBy: invalidCharacters).joined(separator: replacement)
        
        // Trim spaces and ensure it’s not an empty filename
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        } else {
            return "Untitled Recipe_\(Date().ISO8601Format())"
        }
    }
    
    public func convertedToSlug() -> String? {
        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
            let result = urlComponents.filter { $0 != "" }.joined(separator: "-")

            if result.count > 0 {
                return result
            }
        }

        return nil
    }
}
