//
//  ViewController.m
//  KeyframeViewAnimations
//
//  Created by Duncan Champney on 2/4/14.
//  Copyright (c) 2014 WareTo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void) viewDidAppear:(BOOL)animated
{
  startingCenter = imageViewToAnimate.center;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)handleAnimateButton:(id)sender
{
  imageViewToAnimate.center = startingCenter;
  animateButton.enabled = NO;
  CGSize imageSize = imageViewToAnimate.bounds.size;
  
  //Create a rectangle to contain the center-point of our animations (inset by 20 pixels+ the height & width of the image view
  CGRect animationBounds = CGRectIntegral(CGRectInset( animationView.bounds, 20 + imageSize.width/2, 20+imageSize.height/2));
  
  CGFloat totalDuration = 8;
  
  __block CGFloat animationSteps = 6;
  
  CGFloat stepDistance = round(animationBounds.size.width / animationSteps);
  
  __block int stepCount = 1;
  
  void (^animationStepBlock)() =
  ^{
    CGPoint stepCenter;
    CGFloat newY;
    CGFloat newX;
    //Alternate between the top and bottom of the animation view
    
    if (stepCount %2 == 0) //even step (0, 2, 4, 6). Position along the bottom
      newY = floorf(animationBounds.origin.y +animationBounds.size.height);
    else
      newY =animationBounds.origin.y;
    
    newX = floorf(animationBounds.origin.x + stepDistance * stepCount);
    stepCenter = CGPointMake(newX, newY );
    imageViewToAnimate.center = stepCenter;
  };
  
  [UIView animateKeyframesWithDuration:totalDuration
                                 delay:0.0
                               options: UIViewKeyframeAnimationOptionCalculationModeCubic + UIViewAnimationOptionCurveLinear
                            animations:
   ^{
     for (stepCount = 1; stepCount <= animationSteps; stepCount++)
     {
       CGFloat startTime = (stepCount-1)/animationSteps;
       CGFloat relDuration = 1/animationSteps;
       //NSLog(@"Adding animation step %d, start time = %.3f, duration = %.3f", stepCount, startTime, relDuration);
       [UIView addKeyframeWithRelativeStartTime: startTime
                               relativeDuration: relDuration
                                     animations: animationStepBlock
        ];
     }
     
     //Also add a rotation transform
     animationSteps = 8;
     for (stepCount = 1; stepCount <= animationSteps; stepCount++)
     {
       CGFloat startTime = (stepCount-1)/animationSteps;
       CGFloat relDuration = 1/animationSteps;

       [UIView addKeyframeWithRelativeStartTime: startTime
                               relativeDuration: relDuration
                                     animations:
        ^{
          CGFloat angle =M_PI * 4 * stepCount/animationSteps;
          CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
          imageViewToAnimate.transform = transform;
        }
        ];
     }

   }
                            completion: ^(BOOL finished)
   {
     [UIView animateWithDuration: .5
                           delay: .5
                         options: 0
                      animations:
      ^{
        imageViewToAnimate.center = startingCenter;
        imageViewToAnimate.transform = CGAffineTransformIdentity;
      }
                      completion: ^(BOOL finished)
      {
        animateButton.enabled = YES;
      }];
   }];
  
  
}
@end
