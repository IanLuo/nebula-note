//
//  TextStorage.h
//  TextStorage
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for TextStorage.
FOUNDATION_EXPORT double TextStorageVersionNumber;

//! Project version string for TextStorage.
FOUNDATION_EXPORT const unsigned char TextStorageVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TextStorage/PublicHeader.h>

#define OUTLINE_ATTRIBUTE_HIDDEN @"hidden"

#define OUTLINE_ATTRIBUTE_HEADING_FOLDED @"heading-folded"
#define OUTLINE_ATTRIBUTE_HEADING_LEVEL @"heading-level"
#define OUTLINE_ATTRIBUTE_HEADING_SCHEDULE @"heading-schedule"
#define OUTLINE_ATTRIBUTE_HEADING_DUE @"heading-due"
#define OUTLINE_ATTRIBUTE_HEADING_TAGS @"heading-tags"

#define OUTLINE_ATTRIBUTE_CHECKBOX_STATUS @"checkbox-status"
#define OUTLINE_ATTRIBUTE_CHECKBOX_BOX @"checkbox-box"

#define OUTLINE_ATTRIBUTE_LINK @"link"
#define OUTLINE_ATTRIBUTE_LINK_TITLE @"link-title"

#define OUTLINE_ATTRIBUTE_UNORDERED_LIST @"unordered-list"
#define OUTLINE_ATTRIBUTE_UNORDERED_LIST_PREFIX @"unordered-list-prefix"

#define OUTLINE_ATTRIBUTE_ORDERED_LIST @"ordered-list"
#define OUTLINE_ATTRIBUTE_ORDERED_LIST_INDEX @"ordered-list-index"

@protocol ContentUpdatingProtocol<NSObject>

- (void)performContentUpdate:(NSString *)string range:(NSRange)range delta:(NSInteger)delta action:(NSTextStorageEditActions)action;

@end

@interface TextStorage: NSTextStorage<NSLayoutManagerDelegate>

@property (nonatomic, weak) id<ContentUpdatingProtocol> attributeChangeDelegate;

@end
