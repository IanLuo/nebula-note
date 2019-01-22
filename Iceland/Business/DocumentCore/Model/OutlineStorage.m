//
//  OutlineStorage.m
//  Business
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

#import "OutlineStorage.h"

@interface OutlineStorage()

@property (strong) NSMutableAttributedString *backingStore;

@end

@implementation OutlineStorage

- (instancetype)init {
    if ([super init]) {
        self.backingStore = [[NSMutableAttributedString alloc] init];
    }
    
    return self;
}

- (NSString *)string {
    return [[self backingStore] string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range {
    return [self.backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str {
    [self.backingStore replaceCharactersInRange: range withString:str];
    [self edited: NSTextStorageEditedAttributes|NSTextStorageEditedCharacters range:range changeInLength: str.length - str.length];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range {
    [self.backingStore setAttributes: attrs range:range];
    [self edited: NSTextStorageEditedAttributes range:range changeInLength: 0];
}

@end
