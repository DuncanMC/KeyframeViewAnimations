//
//  ViewController.h
//  KeyframeViewAnimations
//
//  Created by Duncan Champney on 2/4/14.
//  Copyright (c) 2014 WareTo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
{
  __weak IBOutlet UIImageView *imageViewToAnimate;
  __weak IBOutlet UIView *animationView;
  __weak IBOutlet UIButton *animateButton;
  
  CGPoint startingCenter;
}

- (IBAction)handleAnimateButton:(id)sender;

@end
