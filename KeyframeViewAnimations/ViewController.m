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

//------------------------------------------------------------------------------------------------------

- (void) viewDidAppear:(BOOL)animated
{
  //Remember where our image vew is positioned at first.
  startingCenter = imageViewToAnimate.center;
}

//------------------------------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//------------------------------------------------------------------------------------------------------
/*
 This method uses a CABasicAnimation to animate a 720 degree rotation on our image view's layer.
 There are a couple of things that are noteworthy.
 
 1. normally you can't control the rotation direction (clockwise/counterclockwize) of rotations of 1/2
 turn or more, since the system simple rotates the object in the direction that requires the smallest
 rotation.
 
 To solve this, we're the valueFunction property of the animation, 
 with a value of kCAValueFunctionRotateZ. This tells the system that we want to apply a rotation 
 around the Z axis, and the value(s) we're providing in fromValue and toValue are angles instead
 of a full transformation matrix. This makes it possible to animate a rotation of an arbitrary amount,
 including multiple full rotations - something that's normally not possible with a single step
 
 2. Normally a CAAnimation will always invoke a single delegate method, animationDidStop:finished:,
 once the animation is completed. If you are managing multiple CAAnimation objects that need 
 custom completion code, this quickly becomes a mess.
 
 What we've done here is to take advantage of an interesting behavior of CAAnimation objects:
 
 They support the methods setValue:forKey and valueForKey:. You can attach an arbitrary object
 to an animation, and that object will stay attached. We take advantage of this by creating a custom
 block type, animationCompletionBlock, and attaching an animationCompletionBlock to our animation,
 using the key kAnimationCompletionBlock 
 (which is just a #define for @"animationCompletionBlock").
 
 Our animationDidStop:finished method simply uses valueForKey:kAnimationCompletionBlock to look
 for a code block attached to the aniamtion. If it exists, the completion method executes it.
 
 Using this approach, you can specify completion code when you define your animation, instead of
 having to maintain a big switch statement in your global animationDidStop:finished method.

 */

- (void) handleRotate;
{
#define full_rotation M_PI*2
#define rotation_count 2
  
  animationCompletionBlock completionBlock;
  
  
  static float change =-full_rotation* rotation_count;
  
  change *= -1;
  CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform"];
  rotation.duration =  rotation_count;
  rotation.fromValue = @(angle);
  angle += change;
  rotation.toValue = @(angle);
  
  rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  rotation.valueFunction = [CAValueFunction functionWithName:kCAValueFunctionRotateZ];
  rotation.delegate = self;
  
  
  //Create a block of code to be executed once our animation finishes.
  completionBlock = ^void(void)
  {
    animateButton.enabled = YES;
    rotateButton.enabled = YES;
    imageViewToAnimate.layer.transform = CATransform3DIdentity;
  };
  
  /*
    Attach the completion block to the animation using the key kAnimationCompletionBlock.
    Our animationDidStop:finished: delegate method will execute this block when the animation completes
   */
  [rotation setValue: completionBlock forKey: kAnimationCompletionBlock];
  
  /*
    Set the layer's transform to it's final state before submitting the animation, so it is in it's
    final state once the animation completes.
   */
  imageViewToAnimate.layer.transform = CATransform3DRotate(imageViewToAnimate.layer.transform, change, 0, 0, 1.0);
  
  //Now actually add the animation to the layer.
  [imageViewToAnimate.layer addAnimation:rotation forKey:@"transform.rotation.z"];
}

//------------------------------------------------------------------------------------------------------
/*
 This method uses the new iOS 7 UIView class method
 animateKeyframesWithDuration:delay:options:animations:completion: to run a multi-step keyframe animation
 on our image view "imageViewToAnimate".
 */

- (void) doKeyFrameViewAnimation;
{
  
  CGSize imageSize = imageViewToAnimate.bounds.size;
  
  //Create a rectangle to contain the center-point of our animations
  //(inset by 20 pixels + the height & width of the image view
  CGRect animationBounds = CGRectIntegral(
                                          CGRectInset(
                                                      animationView.bounds, 20 + imageSize.width/2,
                                                      20+imageSize.height/2));
  CGFloat totalDuration = 8;
  
  __block CGFloat animationSteps = 6;
  
  CGFloat stepDistance = round(animationBounds.size.width / animationSteps);
  
  __block int stepCount = 1;
  
  
  /*
   First we define a block of code that we will use in a call to
   addKeyframeWithRelativeStartTime:relativeDuration:animations:
   This block of code simply alternates the image view from top to bottom of the screen
   as it moves it from left to right.
   */
  
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
    
    newX = truncf(animationBounds.origin.x + stepDistance * stepCount);
    stepCenter = CGPointMake(newX, newY );
    imageViewToAnimate.center = stepCenter;
  };
  
  //--------------
  /*
   The method animateKeyframesWithDuration:delay:options:animations:completion: lets you trigger
   a sequence of animations in a block. Each animation in the sequence is specified 
   with a call to addKeyframeWithRelativeStartTime:relativeDuration:animations:
   The start time is in the range 0..1 
   (0= first instanct of the keyframe sequence, and 1= the last instanct of the keyframe sequence.)
   
   Likewise the relativeDuration parameter ranges from 0 to 1, where 0 means it takes no time at all, and 1
   means it uses the duration of the entire keyframe sequence.
   
   you can submit your individual keyframe steps in any order, and you can even have mulitple 
   keframes running at the same time.
   
   Furthermore, these keyframe animation steps can operate on mulitple different view objects.
   */
  
  [UIView animateKeyframesWithDuration:totalDuration
                                 delay:0.0
                               options: UIViewKeyframeAnimationOptionCalculationModeCubic + UIViewAnimationOptionCurveLinear
                            animations:
   ^{
     
     /*
      In a for loop, make repeated calls to addKeyframeWithRelativeStartTime:relativeDuration:animations: to
      add multiple animation steps to the keyframe sequence. We pass in the block we defined above.
     */
     
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
     
     /*
      Also animate a change to the rotation of the view's layer. We run this animation in 6 steps to show that
      the 2 sets of keyframes are run independently.
      */
     
     animationSteps = 6;
     for (stepCount = 1; stepCount <= animationSteps; stepCount++)
     {
       CGFloat startTime = (stepCount-1)/animationSteps;
       CGFloat relDuration = 1/animationSteps;
       
       [UIView addKeyframeWithRelativeStartTime: startTime
                               relativeDuration: relDuration
                                     animations:
        ^{
          //Make the rotation change go through a full 4 pi angle change (2 full rotations) during the sequence
          CGFloat viewAngle =M_PI * 4 * stepCount/animationSteps;
          CGAffineTransform transform = CGAffineTransformMakeRotation(viewAngle);
          imageViewToAnimate.transform = transform;
        }
        ];
     }
   }
   //Provide a completion block for the entire keyframe sequnce.
                            completion: ^(BOOL finished)
   {
     
     //Animate the image view back to it's starting point.
     [UIView animateWithDuration: .5
                           delay: .5
                         options: 0
                      animations:
      ^{
        imageViewToAnimate.center = startingCenter;
        imageViewToAnimate.transform = CGAffineTransformIdentity;
      }
      //And in the completion block for THIS animation, re-enable the animation buttons.
                      completion: ^(BOOL finished)
      {
        animateButton.enabled = YES;
        rotateButton.enabled = YES;
      }];
   }];
}

//-----------------------------------------------------------------------------------------------------------
//This is the delegate method for a CAAnimation. Instead of putting custom code in this method, we check
//To see if the animation has a code block attached to it

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
  //Is there a completion block attached to this CAAnimation?
  animationCompletionBlock theBlock = [theAnimation valueForKey: kAnimationCompletionBlock];
  
  //If yes, execute it.
  if (theBlock)
    theBlock();
}


//-----------------------------------------------------------------------------------------------------------
#pragma mark - IBAction methods
//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleAnimateButton:(id)sender
{
  //Before we start, disable the animation buttons so the user can't trigger an animation until we're done
  animateButton.enabled = NO;
  rotateButton.enabled = NO;

  //First move the image view to it's starting position in the lower left corner of the screen
  [UIView animateWithDuration: 1.0
                   animations:
   ^{
     imageViewToAnimate.center = keyframeAnimationPlaceholder.center;
   }
                   completion:^(BOOL finished)
   {
     //Once that animation is done, trigger the keyframe animation after a brief pause.
     [self performSelector: @selector(doKeyFrameViewAnimation) withObject: nil afterDelay: .5];
   }
   ];
}

//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleRotateButton:(UIButton *)sender
{
  //Before we start, disable the animation buttons so the user can't trigger an animation until we're done
  animateButton.enabled = NO;
  rotateButton.enabled = NO;

  [self handleRotate];
}

@end
