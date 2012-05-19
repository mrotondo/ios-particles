//
//  IPAppDelegate.h
//  iOSParticles
//
//  Created by Mike Rotondo on 5/14/12.
//  Copyright (c) 2012 Mike Rotondo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IPViewController;

@interface IPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) IPViewController *viewController;

@end
