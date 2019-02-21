//
//  TextStorage.m
//  TextStorage
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextStorage.h"
#import <UIKit/UIKit.h>

@interface TextStorage()

@property (strong) NSTextStorage *backingStore;

@end

@implementation TextStorage

- (instancetype)init {
    if ([super init]) {
        self.backingStore = [[NSTextStorage alloc]init];
    }
    
    return self;
}

- (NSString *)string {
    return [self.backingStore mutableString];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    [self.backingStore replaceCharactersInRange:range withString:str];
    [self edited: NSTextStorageEditedCharacters range:range changeInLength: str.length - range.length];
    [self endEditing];
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self beginEditing];
    [self.backingStore setAttributes:attrs range:range];
    [super edited: NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)processEditing {
    if ([self.attributeChangeDelegate respondsToSelector: @selector(performContentUpdate:range:delta:action:)]) {
        [self.attributeChangeDelegate performContentUpdate:self.string range: [super editedRange] delta: [super changeInLength] action: [super editedMask]];
    }
    
    [super processEditing];
}

- (NSUInteger)layoutManager:(NSLayoutManager *)layoutManager shouldGenerateGlyphs:(const CGGlyph *)glyphs properties:(const NSGlyphProperty *)props characterIndexes:(const NSUInteger *)charIndexes font:(UIFont *)aFont forGlyphRange:(NSRange)glyphRange {
    
    NSGlyphProperty *controlCharProps = malloc(sizeof(NSGlyphProperty) * glyphRange.length);
    BOOL shouldGenerate = NO; // 如果标记为 YES，则表示有 glyph 需要修改，否则使用默认行为
    
    for (int i = 0; i < glyphRange.length; i++) {
        NSDictionary * attributes = [self attributesAtIndex: glyphRange.location + i effectiveRange: nil];
        
        if (attributes[OUTLINE_ATTRIBUTE_HIDDEN] != nil) {
            controlCharProps[i] = NSGlyphPropertyNull;
            shouldGenerate = YES;
        } else if (attributes[OUTLINE_ATTRIBUTE_HEADING_FOLDED] != nil) {
            controlCharProps[i] = NSGlyphPropertyNull;
            shouldGenerate = YES;
        }
    }
    
    if (shouldGenerate) {
        [layoutManager setGlyphs:glyphs properties:controlCharProps characterIndexes:charIndexes font:aFont forGlyphRange:glyphRange];
        return glyphRange.length;
    } else {
        return 0;
    }
}

@end
