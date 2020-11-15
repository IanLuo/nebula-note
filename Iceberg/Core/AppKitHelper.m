//
//  AppKitHelper.m
//  Core
//
//  Created by ian luo on 2020/11/15.
//  Copyright © 2020 wod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Interface/Interface-Swift.h>

@implementation UIImage (ResourceProxyHack)

+ (UIImage *)_iconForResourceProxy:(id)proxy format:(int)format {

    return [UIImage imageNamed:@"image library" inBundle:[NSBundle bundleForClass:[OutlineTheme class]] compatibleWithTraitCollection:nil];
}

@end
    
