//
//  TextStorage.m
//  TextStorage
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextStorage.h"

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

@end
