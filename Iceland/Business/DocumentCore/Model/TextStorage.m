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

+ (NSTextAttachment *)foldingAttachment {
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed: @"left"];
    attachment.bounds = CGRectMake(0, 0, 20, 20);
    return attachment;
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    [self.backingStore replaceCharactersInRange:range withString:str];
    [self edited: NSTextStorageEditedCharacters range:range changeInLength: str.length - range.length];
    [self endEditing];
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    id value;
    NSRange effectiveRange;
    NSDictionary *attributes = [self.backingStore attributesAtIndex:location effectiveRange:range];

    value = [attributes objectForKey: OUTLINE_ATTRIBUTE_HEADING_FOLDED];
    if (value && [value intValue]) {
        [self.backingStore attribute: OUTLINE_ATTRIBUTE_HEADING_FOLDED atIndex:location longestEffectiveRange:&effectiveRange inRange:NSMakeRange(0, [self.backingStore length])];

            // We adds NSAttachmentAttributeName if in lineFoldingAttributeName
        if (location == effectiveRange.location) { // beginning of a folded range
            NSMutableDictionary *dict = [attributes mutableCopyWithZone:NULL];
            [dict setObject: [TextStorage foldingAttachment] forKey:NSAttachmentAttributeName];
            attributes = dict;
            effectiveRange.length = 1;
        } else {
            ++(effectiveRange.location); --(effectiveRange.length);
        }

        if (range) *range = effectiveRange;
    }
    
    return attributes;
}

    // Attribute Fixing Overrides
- (void)fixAttributesInRange:(NSRange)range {
    [super fixAttributesInRange:range];
    
        // we want to avoid extending to the last paragraph separator
    [self enumerateAttribute:OUTLINE_ATTRIBUTE_HEADING_FOLDED inRange:range options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value && (range.length > 1)) {
            NSUInteger paragraphStart, paragraphEnd, contentsEnd;

            [[self string] getParagraphStart:&paragraphStart end:&paragraphEnd contentsEnd:&contentsEnd forRange:range];

            if ((NSMaxRange(range) == paragraphEnd) && (contentsEnd < paragraphEnd)) {
                [self removeAttribute:OUTLINE_ATTRIBUTE_HEADING_FOLDED range:NSMakeRange(contentsEnd, paragraphEnd - contentsEnd)];
            }
        }
    }];
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
    
    NSRange effectiveRange;
    id attribute;
    
    NSGlyphProperty * properties = NULL;
    
        // find folding
    attribute = [self attribute: OUTLINE_ATTRIBUTE_HEADING_FOLDED atIndex: charIndexes[0] longestEffectiveRange: &effectiveRange inRange: NSMakeRange(0, [self.backingStore length])];
    if (attribute && [attribute intValue]) {
        NSInteger propertiesSize = sizeof(NSGlyphProperty) * glyphRange.length;
        NSGlyphProperty aProperty = NSGlyphPropertyNull;
        properties = NSZoneMalloc(NULL, propertiesSize);
        memset_pattern4(properties, &aProperty, propertiesSize);
        
        if (charIndexes[0] == effectiveRange.location) {
            properties[0] = NSGlyphPropertyControlCharacter;
        }
        
        [layoutManager setGlyphs:glyphs properties:properties characterIndexes:charIndexes font:aFont forGlyphRange:glyphRange];
        
        if (properties) NSZoneFree(NULL, properties);
        
        return glyphRange.length;
    }
    
    return 0;
}

- (NSControlCharacterAction)layoutManager:(NSLayoutManager *)layoutManager shouldUseAction:(NSControlCharacterAction)action forControlCharacterAtIndex:(NSUInteger)charIndex {
    if ([self attribute:OUTLINE_ATTRIBUTE_HEADING_FOLDED atIndex:charIndex effectiveRange:nil]) {
        return NSControlCharacterActionZeroAdvancement;
    }
    
    return action;
}

@end
