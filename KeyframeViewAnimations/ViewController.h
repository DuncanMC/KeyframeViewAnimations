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

typedef enum
{
  keyframeAnimation,
  rotationAnimation
} animationType;

@interface ViewController : UIViewController
{
  __weak IBOutlet UIImageView *imageViewToAnimate;
  __weak IBOutlet UIView *animationView;
  __weak IBOutlet UIButton *animateButton;
  __weak IBOutlet UIButton *animateCAButton;
  __weak IBOutlet UIButton *rotateButton;
  
  __weak IBOutlet UIButton *pauseButton;
  __weak IBOutlet UIButton *stopButton;
  __weak IBOutlet UISlider *animationSlider;
  
  __weak IBOutlet UIView *keyframeAnimationPlaceholder;
  CGPoint startingCenter;
  CGFloat angle;
  CFTimeInterval animationStartTime;
  CFTimeInterval totalAnimationTime;
  CGFloat animationProgress;
  
  CAShapeLayer *pathLayer;
  __weak NSTimer *sliderTimer;
}

@property (nonatomic, assign)   BOOL animationIsPaused;

- (IBAction)handleAnimateButton:(UIButton *)sender;
- (IBAction)handleRotateButton:(UIButton *)sender;
- (IBAction)handlePauseButton:(UIButton *)sender;
- (IBAction)handleAnimationSlider:(UISlider *)sender;
- (IBAction)handleStopButton:(UIButton *)sender;

@end
