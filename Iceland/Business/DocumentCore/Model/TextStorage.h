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
#define OUTLINE_ATTRIBUTE_HIDDEN_VALUE_DEFAULT 1
#define OUTLINE_ATTRIBUTE_HIDDEN_VALUE_WITH_ATTACHMENT 2
#define OUTLINE_ATTRIBUTE_HIDDEN_VALUE_FOLDED 3

#define OUTLINE_ATTRIBUTE_TEMPORARY_HIDDEN @"temp-hidden"

#define OUTLINE_ATTRIBUTE_BUTTON @"OUTLINE_ATTRIBUTE_BUTTON"
#define OUTLINE_ATTRIBUTE_BUTTON_BORDER @"OUTLINE_ATTRIBUTE_BUTTON_BORDER"

#define OUTLINE_ATTRIBUTE_DATE_AND_TIME @"OUTLINE_ATTRIBUTE_DATE_AND_TIME"

#define OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT @"OUTLINE_ATTRIBUTE_SHOW_ATTACHMENT"
#define OUTLINE_ATTRIBUTE_TEMPAROTY_SHOW_ATTACHMENT @"OUTLINE_ATTRIBUTE_TEMPARATY_SHOW_ATTACHMENT"

#define OUTLINE_ATTRIBUTE_HEADING_FOLDED @"OUTLINE_ATTRIBUTE_HEADING_FOLDED"
#define OUTLINE_ATTRIBUTE_HEADING_FOLD_UNFOLDED @"OUTLINE_ATTRIBUTE_HEADING_FOLD_UNFOLDED"
#define OUTLINE_ATTRIBUTE_HEADING_FOLD_FOLDED @"OUTLINE_ATTRIBUTE_HEADING_FOLD_FOLDED"
#define OUTLINE_ATTRIBUTE_HEADING_LEVEL @"OUTLINE_ATTRIBUTE_HEADING_LEVEL"
#define OUTLINE_ATTRIBUTE_HEADING_SCHEDULE @"OUTLINE_ATTRIBUTE_HEADING_SCHEDULE"
#define OUTLINE_ATTRIBUTE_HEADING_DUE @"OUTLINE_ATTRIBUTE_HEADING_DUE"
#define OUTLINE_ATTRIBUTE_HEADING_TAGS @"OUTLINE_ATTRIBUTE_HEADING_TAGS"
#define OUTLINE_ATTRIBUTE_HEADING_PRIORITY @"OUTLINE_ATTRIBUTE_HEADING_PRIORITY"
#define OUTLINE_ATTRIBUTE_HEADING_PLANNING @"OUTLINE_ATTRIBUTE_HEADING_PLANNING"

#define OUTLINE_ATTRIBUTE_CHECKBOX @"checkbox"

#define OUTLINE_ATTRIBUTE_LINK_OTHER @"link-other"
#define OUTLINE_ATTRIBUTE_LINK_TITLE @"link-title"
#define OUTLINE_ATTRIBUTE_LINK_URL @"link-URL"

#define OUTLINE_ATTRIBUTE_UNORDERED_LIST @"unordered-list"
#define OUTLINE_ATTRIBUTE_UNORDERED_LIST_PREFIX @"unordered-list-prefix"

#define OUTLINE_ATTRIBUTE_ORDERED_LIST @"ordered-list"
#define OUTLINE_ATTRIBUTE_ORDERED_LIST_INDEX @"ordered-list-index"

#define OUTLINE_ATTRIBUTE_SEPARATOR @"separator"

#define OUTLINE_ATTRIBUTE_ATTACHMENT @"attachment"
#define OUTLINE_ATTRIBUTE_ATTACHMENT_TYPE @"attachment-type"
#define OUTLINE_ATTRIBUTE_ATTACHMENT_VALUE @"attachment-value"

#define OUTLINE_ATTRIBUTE_ATTACHMENT_UNAVAILABLE @"OUTLINE_ATTRIBUTE_ATTACHMENT_UNAVAILABLE"

@protocol ContentUpdatingProtocol<NSObject>
    
- (void)performContentUpdate:(NSString *)string range:(NSRange)range delta:(NSInteger)delta action:(NSTextStorageEditActions)action;
    
@end

@interface TextStorage: NSTextStorage<NSLayoutManagerDelegate>
    
@property (nonatomic, weak) id<ContentUpdatingProtocol> attributeChangeDelegate;

- (void)addAttachment:(NSTextAttachment *)attachment for:(NSString *)key;
    
- (NSTextAttachment *)cachedAttachmentWith:(NSString *)key;
    
@end

