//
//  ViewController.h
//  KeyframeViewAnimations
//
//  Created by Duncan Champney on 2/4/14.
//  Copyright (c) 2014 WareTo. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAnimationCompletionBlock @"animationCompletionBlock"
typedef void (^animationCompletionBlock)(void);

@interface ViewController : UIViewController
{
  __weak IBOutlet UIImageView *imageViewToAnimate;
  __weak IBOutlet UIView *animationView;
  __weak IBOutlet UIButton *animateButton;
  __weak IBOutlet UIButton *rotateButton;
  
  CGPoint startingCenter;
  CGFloat angle;
}

- (IBAction)handleAnimateButton:(id)sender;
- (IBAction)handleRotateButton:(UIButton *)sender;

@end
