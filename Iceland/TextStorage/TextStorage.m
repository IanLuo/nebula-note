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

@property (strong) NSMutableAttributedString *backingStore;

@end

@implementation TextStorage

- (instancetype)init {
    if ([super init]) {
        self.backingStore = [[NSMutableAttributedString alloc]init];
    }
    
    return self;
}

- (NSString *)string {
    return [self.backingStore mutableString];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self.backingStore replaceCharactersInRange:range withString:str];
    [self edited: NSTextStorageEditedCharacters|NSTextStorageEditedAttributes range:range changeInLength: str.length - range.length];
}

- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range {
    [self.backingStore setAttributes:attrs range:range];
    [super edited: NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (void)processEditing {
    [super processEditing];
}

- (NSUInteger)layoutManager:(NSLayoutManager *)layoutManager shouldGenerateGlyphs:(const CGGlyph *)glyphs properties:(const NSGlyphProperty *)props characterIndexes:(const NSUInteger *)charIndexes font:(UIFont *)aFont forGlyphRange:(NSRange)glyphRange {
    
    NSGlyphProperty *controlCharProps = malloc(sizeof(NSGlyphProperty) * glyphRange.length);
    BOOL souldGenrate = NO;
    
    for (int i = 0; i < glyphRange.length; i++) {
        NSDictionary * attributes = [self attributesAtIndex: glyphRange.location + i effectiveRange: nil];
        
        if (attributes[OUTLINE_ATTRIBUTE_HEADING_FOLDED] != nil) {
            controlCharProps[i] = NSGlyphPropertyNull;
            souldGenrate = YES;
        } else if (attributes[OUTLINE_ATTRIBUTE_LINK] != nil && attributes[OUTLINE_ATTRIBUTE_LINK_TITLE] == nil) {
            controlCharProps[i] = NSGlyphPropertyNull;
            souldGenrate = YES;
        }  else if (attributes[OUTLINE_ATTRIBUTE_CHECKBOX_STATUS] != nil && attributes[OUTLINE_ATTRIBUTE_CHECKBOX_BOX] == nil) {
            controlCharProps[i] = NSGlyphPropertyNull;
            souldGenrate = YES;
        } else {
            controlCharProps[i] = props[i];
        }
    }
    
    if (souldGenrate) {
        [layoutManager setGlyphs:glyphs properties:controlCharProps characterIndexes:charIndexes font:aFont forGlyphRange:glyphRange];
        return glyphRange.length;
    } else {
        return 0;
    }
}

@end
