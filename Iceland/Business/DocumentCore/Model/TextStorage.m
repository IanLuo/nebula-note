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
#import <Business/Business-Swift.h>

static NSTextAttachment *foldingAttachment;
static NSTextAttachment *linkAttachment;

static NSDictionary *attachmentMap;

@interface TextStorage()

@property (strong) NSTextStorage *backingStore;

@property (strong) NSDictionary *attachmentCache; // user added attachment saved here

@end

@implementation TextStorage

+ (void)initialize {
    if ([self class] == [TextStorage class]) {
        foldingAttachment = [[NSTextAttachment alloc] init];
        foldingAttachment.image = [UIImage imageNamed: @"more"];
        foldingAttachment.bounds = CGRectMake(0, 0, 14, 4);
        
        linkAttachment = [[NSTextAttachment alloc] init];;
        linkAttachment.image = [UIImage imageNamed: @"document"];
        linkAttachment.bounds = CGRectMake(0, 0, 20, 20);
        
        attachmentMap = @{
                          OUTLINE_ATTRIBUTE_HEADING_FOLDED: foldingAttachment,
                          OUTLINE_ATTRIBUTE_LINK_URL: linkAttachment,
                          OUTLINE_ATTRIBUTE_SEPARATOR: [[SeparaterAttachment alloc]init]
                          };
    }
}

- (instancetype)init {
    if ([super init]) {
        self.backingStore = [[NSTextStorage alloc]init];
        self.attachmentCache = @{};
    }
    
    return self;
}

- (NSString *)string {
    return [self.backingStore mutableString];
}

+ (NSTextAttachment *)foldingAttachment {
    return foldingAttachment;
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self beginEditing];
    [self.backingStore replaceCharactersInRange:range withString:str];
    [self edited: NSTextStorageEditedCharacters range:range changeInLength: str.length - range.length];
    [self endEditing];
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    NSRange effectiveRange;
    NSDictionary *attributes = [self.backingStore attributesAtIndex:location effectiveRange: range];

    NSTextAttachment *attachment;
    NSString *attachmentKey = [attributes objectForKey: OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT];
    if (attachmentKey) {
        attachment = attachmentMap[attachmentKey];
    }

    if (attachment) {
        [self.backingStore attribute: OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT atIndex:location longestEffectiveRange:&effectiveRange inRange:NSMakeRange(0, [self.backingStore length])];
        if (location == effectiveRange.location) {
            NSMutableDictionary *dict = [attributes mutableCopyWithZone:NULL];
            [dict setObject: attachment forKey:NSAttachmentAttributeName];
            attributes = dict;
            effectiveRange.length = 1;
        } else {
            ++(effectiveRange.location); --(effectiveRange.length);
        }

        if (range) *range = effectiveRange;
    }

    return attributes;
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
    
    NSGlyphProperty * properties = NULL;
    NSRange effectiveRange;

    NSNumber *hiddenType = [self attribute: OUTLINE_ATTRIBUTE_HIDDEN atIndex:charIndexes[0] longestEffectiveRange:&effectiveRange inRange:NSMakeRange(0, [self.backingStore length])];
    
    if (hiddenType && hiddenType.intValue != 0) {
        NSInteger propertiesSize = sizeof(NSGlyphProperty) * glyphRange.length;
        NSGlyphProperty aProperty = NSGlyphPropertyNull;
        properties = malloc(propertiesSize);
        memset_pattern4(properties, &aProperty, propertiesSize);
        
        if (charIndexes[0] == effectiveRange.location
            && (hiddenType.intValue == 2 || hiddenType.intValue == 3)) {
            properties[0] = NSGlyphPropertyControlCharacter;
        }
    }

    if (properties) {
        [layoutManager setGlyphs:glyphs properties:properties characterIndexes:charIndexes font:aFont forGlyphRange:glyphRange];

        free(properties);

        return glyphRange.length;
    }

    return 0;
}

- (NSGlyphProperty *)replaceGlyphPropertiesAtCharacterLocation:(NSUInteger)location glyphRange:(NSRange)glyphRange hasAttachment:(BOOL)hasAttachment for:(NSString*)key {
    NSRange effectiveRange;
    NSGlyphProperty * properties = NULL;
    if ([self attribute: key atIndex: location longestEffectiveRange: &effectiveRange inRange: NSMakeRange(0, [self.backingStore length])]) {
        NSInteger propertiesSize = sizeof(NSGlyphProperty) * glyphRange.length;
        NSGlyphProperty aProperty = NSGlyphPropertyNull;
        properties = malloc(propertiesSize);
        memset_pattern4(properties, &aProperty, propertiesSize);
        
        if (location == effectiveRange.location && hasAttachment) {
            properties[0] = NSGlyphPropertyControlCharacter;
        }
    }
    return properties;
}

- (NSControlCharacterAction)layoutManager:(NSLayoutManager *)layoutManager shouldUseAction:(NSControlCharacterAction)action forControlCharacterAtIndex:(NSUInteger)charIndex {
    if ([self attribute:OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT atIndex:charIndex effectiveRange:nil]) {
        return NSControlCharacterActionZeroAdvancement;
    }
    
    return action;
}

@end
