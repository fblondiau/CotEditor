//
//  NSTextView+LineNumber.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa

extension NSTextView {
    
    enum Line {
        
        case new(_ lineNumber: Int, _ isSelected: Bool)
        case wrapped
    }
    
    
    /// enumerate line fragments in area with line numbers
    ///
    /// - Parameters:
    ///   - rect: The bounding rectangle for which to process lines.
    ///   - includingExtraLine: If `true` `body` also enumerate extra line fragment if any.
    ///   - body: The closure executed for each line in the enumeration.
    ///   - line: The information of the line.
    ///   - lineRect: The line fragment rect.
    func enumerateLineFragments(in rect: NSRect, includingExtraLine: Bool = true, body: (_ line: Line, _ lineRect: NSRect) -> Void) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return }
        
        let selectedLineRanges = self.selectedRanges.map { (self.string as NSString).lineRange(for: $0.rangeValue) }
        
        // get glyph range of which line number should be drawn
        let layoutRect = rect.offset(by: -self.textContainerOrigin)
        let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRectWithoutAdditionalLayout: layoutRect, in: textContainer)
        
        // count up lines until the interested area
        let firstIndex = layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.location)
        var lineNumber = self.string.lineNumber(at: firstIndex)
        
        // enumerate visible line numbers
        var glyphIndex = glyphRangeToDraw.location
        while glyphIndex < glyphRangeToDraw.upperBound {  // process "real" lines
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = self.string.lineRange(at: characterIndex)
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let isSelected = selectedLineRanges.contains { lineRange.intersection($0) != nil }
            glyphIndex = lineGlyphRange.upperBound
            
            var wrappedLineGlyphIndex = lineGlyphRange.location
            while wrappedLineGlyphIndex < glyphIndex {  // process wrapped lines
                var range = NSRange.notFound
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: wrappedLineGlyphIndex, effectiveRange: &range, withoutAdditionalLayout: true)
                let line: Line = (range.location == lineGlyphRange.location) ? .new(lineNumber, isSelected) : .wrapped
                
                body(line, lineRect)
                
                wrappedLineGlyphIndex = range.upperBound
            }
            lineNumber += 1
        }
        
        guard includingExtraLine else { return }
        
        let extraLineRect = layoutManager.extraLineFragmentUsedRect
        if !extraLineRect.isEmpty, extraLineRect.intersects(layoutRect) {
            let lineNumber = max(self.string.numberOfLines(includingLastLineEnding: true), 1)
            let isSelected = (selectedLineRanges.last?.location == (self.string as NSString).length)
            
            body(.new(lineNumber, isSelected), extraLineRect)
        }
    }
    
}
