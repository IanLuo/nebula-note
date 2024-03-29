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
#import <Core/Core-Swift.h>
#import <Interface/Interface-Swift.h>

static NSTextAttachment *foldingAttachment;
static NSTextAttachment *linkAttachment;
static NSTextAttachment *documentAttachment;
static NSTextAttachment *foldedAttachment;
static NSTextAttachment *unfoldedAttachment;
static NSTextAttachment *scheduleAttachment;
static NSTextAttachment *dueAttachment;
static NSTextAttachment *tagAttachment;
static NSTextAttachment *unavailableAttachment;
static NSTextAttachment *checkboxCheckedAttachment;
static NSTextAttachment *checkboxUncheckedAttachment;

static NSMutableDictionary *attachmentMap;

@interface TextStorage()

@property (strong) NSTextStorage *backingStore;

@property (strong) NSMutableDictionary *attachmentCache; // user added attachment saved here

@end

@implementation TextStorage

+ (void)initialize {
    if ([self class] == [TextStorage class]) {
        foldingAttachment = [[NSTextAttachment alloc] init];
        foldingAttachment.image = [[UIImage imageNamed:@"ellipsis" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color] descriptive]];
        foldingAttachment.bounds = CGRectMake(0, ([[SettingsAccessor shared] lineHeight] - 14) / 2, [[SettingsAccessor shared] lineHeight] + 8, [[SettingsAccessor shared] lineHeight]);
        
        linkAttachment = [[NSTextAttachment alloc] init];
        linkAttachment.image = [[UIImage imageNamed: @"link" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]descriptive]];
        linkAttachment.bounds = CGRectMake(0, -2, 13, 15);
        
        documentAttachment = [[NSTextAttachment alloc] init];
        documentAttachment.image = [[[UIImage imageNamed: @"doc" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]descriptive]] translationWithOffset:CGPointMake(0, -2)];
        documentAttachment.bounds = CGRectMake(0, -2, 11, 15);
        
        foldedAttachment = [[NSTextAttachment alloc] init];
        foldedAttachment.image = [[[UIImage imageNamed: @"arrowtriangle.right.fill" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]descriptive]] insets:UIEdgeInsetsMake(5, 5, 5, 14)];
        foldedAttachment.bounds = CGRectMake(0, ([[SettingsAccessor shared] lineHeight] - 14) / 2, [[SettingsAccessor shared] lineHeight] + 9, [[SettingsAccessor shared] lineHeight]);
        
        unfoldedAttachment = [[NSTextAttachment alloc] init];
        unfoldedAttachment.image = [[[UIImage imageNamed: @"arrowtriangle.down.fill" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color] descriptive]] insets:UIEdgeInsetsMake(5, 5, 5, 14)];
        unfoldedAttachment.bounds = CGRectMake(0, ([[SettingsAccessor shared] lineHeight] - 14) / 2, [[SettingsAccessor shared] lineHeight] + 9, [[SettingsAccessor shared] lineHeight]);
        
        scheduleAttachment = [[NSTextAttachment alloc] init];
        scheduleAttachment.image = [[UIImage imageNamed: @"calendar.badge.clock" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]spotlight]];
        scheduleAttachment.bounds = CGRectMake(0, 0, 10, 10);
        
        dueAttachment = [[NSTextAttachment alloc] init];
        dueAttachment.image = [[UIImage imageNamed: @"calendar.badge.exclamationmark" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]spotlight]];
        dueAttachment.bounds = CGRectMake(0, 0, 10, 10);
        
        tagAttachment = [[NSTextAttachment alloc] init];
        tagAttachment.image = [[UIImage imageNamed: @"tag" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]spotlight]];
        tagAttachment.bounds = CGRectMake(0, 0, 10, 10);
        
        unavailableAttachment = [[NSTextAttachment alloc] init];
        unavailableAttachment.image = [UIImage imageNamed: @"xmark" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil];
        unavailableAttachment.bounds = CGRectMake(0, 0, 10, 10);
        
        checkboxCheckedAttachment = [[NSTextAttachment alloc] init];
        checkboxCheckedAttachment.image = [[UIImage imageNamed: @"checkmark.circle.fill" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color] spotlight]];
        checkboxCheckedAttachment.bounds = CGRectMake(0, ([[SettingsAccessor shared] lineHeight] - 17) / 2, 20, 19);
        
        checkboxUncheckedAttachment = [[NSTextAttachment alloc] init];
        checkboxUncheckedAttachment.image = [[UIImage imageNamed: @"circle" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil] fillWithColor:[[InterfaceTheme Color]spotlight]];
        checkboxUncheckedAttachment.bounds = CGRectMake(0, ([[SettingsAccessor shared] lineHeight] - 17) / 2, 20, 19);
        
        attachmentMap = [@{
                          OUTLINE_ATTRIBUTE_HEADING_FOLDED: foldingAttachment,
                          OUTLINE_ATTRIBUTE_LINK_URL: linkAttachment,
                          OUTLINE_ATTRIBUTE_DOCUMENT_URL: documentAttachment,
                          OUTLINE_ATTRIBUTE_SEPARATOR: [[SeparaterAttachment alloc]init],
                          OUTLINE_ATTRIBUTE_HEADING_FOLD_FOLDED: foldedAttachment,
                          OUTLINE_ATTRIBUTE_HEADING_FOLD_UNFOLDED: unfoldedAttachment,
                          OUTLINE_ATTRIBUTE_HEADING_SCHEDULE: scheduleAttachment,
                          OUTLINE_ATTRIBUTE_HEADING_DUE: dueAttachment,
                          OUTLINE_ATTRIBUTE_HEADING_TAGS: tagAttachment,
                          OUTLINE_ATTRIBUTE_ATTACHMENT_UNAVAILABLE: unavailableAttachment,
                          OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_CHECKED: checkboxCheckedAttachment,
                          OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_UNCHECKED: checkboxUncheckedAttachment
                          } mutableCopy];
    }
}

- (instancetype)init {
    if ([super init]) {
        self.backingStore = [[NSTextStorage alloc]init];
    }
    
    return self;
}

- (void)addAttachment:(NSTextAttachment *)attachment for:(NSString *)key {
    [attachmentMap setObject:attachment forKey:key];
}
    
- (NSTextAttachment *)cachedAttachmentWith:(NSString *)key {
    return [attachmentMap objectForKey:key];
}

- (NSString *)string {
    return [self.backingStore string];
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
    BOOL isUserAdded = NO;
    NSString *attachmentAttributeKey = OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT;
    
    // 检查是否有 temp attachment 如果没有，再检查 attachment
    NSString *attachmentKey = [attributes objectForKey: OUTLINE_ATTRIBUTE_TEMPAROTY_SHOW_ATTACHMENT];
    if (!attachmentKey || [attachmentKey isEqualToString: @""]) {
        attachmentKey = [attributes objectForKey: OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT];
    } else {
        attachmentAttributeKey = OUTLINE_ATTRIBUTE_TEMPAROTY_SHOW_ATTACHMENT;
    }
    
    if (attachmentKey && ![attachmentKey isEqualToString: @""]) {
        if ([attachmentKey isEqualToString: @"user_added"]) {
            NSLog(@"found user added attachment at location: %d", (int)location);
            isUserAdded = YES;
        } else {
            attachment = attachmentMap[attachmentKey];
        }
    }

    if (attachment || isUserAdded) {
        [self.backingStore attribute: attachmentAttributeKey atIndex:location longestEffectiveRange:&effectiveRange inRange:NSMakeRange(0, [self.backingStore length])];
        if (location == effectiveRange.location) {
            if (!isUserAdded) { // attachment already added
                NSMutableDictionary *dict = [attributes mutableCopyWithZone:NULL];
                [dict setObject: attachment forKey:NSAttachmentAttributeName];
                attributes = dict;
            }
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

    NSRange range = NSMakeRange(0, [self.backingStore length]);
    NSNumber *hiddenType = [self attribute: OUTLINE_ATTRIBUTE_TEMPORARY_HIDDEN atIndex:charIndexes[0] longestEffectiveRange:&effectiveRange inRange:range];
    if (hiddenType == nil || hiddenType.intValue == 0) {
        hiddenType = [self attribute: OUTLINE_ATTRIBUTE_HIDDEN atIndex:charIndexes[0] longestEffectiveRange:&effectiveRange inRange:range];
    }
    
    if (hiddenType && hiddenType.intValue != 0) {
        NSInteger propertiesSize = sizeof(NSGlyphProperty) * glyphRange.length;
        NSGlyphProperty aProperty = NSGlyphPropertyNull;
        properties = malloc(propertiesSize);
        memset_pattern4(properties, &aProperty, propertiesSize);
        
        if (charIndexes[0] == effectiveRange.location
            && (hiddenType.intValue == OUTLINE_ATTRIBUTE_HIDDEN_VALUE_WITH_ATTACHMENT || hiddenType.intValue == OUTLINE_ATTRIBUTE_HIDDEN_VALUE_FOLDED)) {
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

- (NSControlCharacterAction)layoutManager:(NSLayoutManager *)layoutManager shouldUseAction:(NSControlCharacterAction)action forControlCharacterAtIndex:(NSUInteger)charIndex {
    NSString *attachmentKey = [self attribute:OUTLINE_ATTRIBUTE_TEMPAROTY_SHOW_ATTACHMENT atIndex:charIndex effectiveRange:nil];
    if (!attachmentKey || [attachmentKey isEqualToString: @""]) {
        attachmentKey = [self attribute:OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT atIndex:charIndex effectiveRange:nil];
    }
    if (attachmentKey && ![attachmentKey isEqualToString: @""]) {
        return NSControlCharacterActionZeroAdvancement;
    }

    return action;
}

- (BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex {
    if ([self attribute:OUTLINE_ATTRIBUTE_BUTTON atIndex:charIndex effectiveRange:nil]) {
        return NO;
    } else {
        return YES;
    }
}

- (CGRect)layoutManager:(NSLayoutManager *)layoutManager boundingBoxForControlGlyphAtIndex:(NSUInteger)glyphIndex forTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)proposedRect glyphPosition:(CGPoint)glyphPosition characterIndex:(NSUInteger)charIndex {
    if ([self attribute:OUTLINE_ATTRIBUTE_BUTTON_BORDER atIndex:charIndex effectiveRange:nil]) {
        return proposedRect;
    }
    
    return proposedRect;
}

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return 10;
}

@end
