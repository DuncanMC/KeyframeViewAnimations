//
//  ViewController.m
//  KeyframeViewAnimations
//
//  Created by Duncan Champney on 2/4/14.
//  Copyright (c) 2014 WareTo. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"

@interface ViewController ()

@end

@implementation ViewController

//------------------------------------------------------------------------------------------------------
#pragma mark - property methods
//------------------------------------------------------------------------------------------------------
/*
 This property method either pauses or unpauses the current animation.
 */
-(void) setAnimationIsPaused:(BOOL)animationIsPaused;
{
  _animationIsPaused = animationIsPaused;
  
  [self setPauseButtonTitle];
  
  CALayer *theLayer = imageViewToAnimate.layer;

  if (animationIsPaused)
  //Pause the current animation on the image view's layer.
  {
    //Stop the slider timer
    [sliderTimer invalidate];
    
    //Setting the layer's speed to zero freezes the animmation.
    theLayer.speed = 0;
    
    //Calculate how far we into the animation based on current media time minus the media time when
    //The animation started.
    CFTimeInterval mediaTime = CACurrentMediaTime();
    animationProgress = mediaTime - animationStartTime;
    
    CFTimeInterval pausedTime = mediaTime;
    
    //Shift the layer's timing so it appears at the current time.
    theLayer.timeOffset = pausedTime-theLayer.beginTime;
    animationStartTime -= theLayer.beginTime;
    theLayer.beginTime = 0;
  }
  else //else un-pause the animation
  {
    //Get the layer's current time offset.
    CFTimeInterval pausedTime = [theLayer timeOffset];
    
    //Now reset the time offset and beginTime to zero.
    theLayer.timeOffset = 0.0;
    theLayer.beginTime = 0.0;
    
    CFTimeInterval mediaTime = CACurrentMediaTime();
    
    //Figure out how much time has elapsed since the animation was paused.
    CFTimeInterval timeSincePause = mediaTime - pausedTime;
    
    //Set the layer's beginTime to that time-since-pause
    theLayer.beginTime = timeSincePause;
    
    //Figure out when the animation would have started in order to be this far along in its progress.
    animationStartTime = CACurrentMediaTime() -animationProgress;
    
    //Start the animation running again
    theLayer.speed = 1.0;
    
    //Start the slider timer so the slider updates.
    [self startSliderTimer];
  }
}

//------------------------------------------------------------------------------------------------------
#pragma mark - view lifecycle methods
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
#pragma mark - custom instance methods
//------------------------------------------------------------------------------------------------------

/*
 This method uses a CABasicAnimation to animate a 720 degree rotation on our image view's layer.
 There are a couple of things that are noteworthy.
 
 1. normally you can't control the rotation direction (clockwise/counterclockwize) of rotations of 1/2
 turn or more, since the system simple rotates the object in the direction that requires the smallest
 rotation.
 
 To solve this, we're going to use the valueFunction property of the animation,
 with a value of kCAValueFunctionRotateZ. This tells the system that we want to apply a rotation
 around the Z axis, and the value(s) we're providing in fromValue and toValue are angles instead
 of a full transformation matrix. This makes it possible to animate a rotation of an arbitrary amount,
 including multiple full rotations - something that's normally not possible with a single animation.
 
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
  
  change *= -1;  //Have our rotation alternate between clockwise and counter-clockwise.
  
  //Create a CABasicAnimation object to manage our rotation.
  CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform"];
  totalAnimationTime = rotation_count;
  
  //Make sure the begin time on the animation is 0,
  //in case we left at a different value on the last animation.
  imageViewToAnimate.layer.beginTime = 0;

  rotation.duration =  totalAnimationTime;
  
  //Start the animation at the previous value of angle
  rotation.fromValue = @(angle);
  
  //Add change (which will be a change of +/- 2pi*rotation_count
  angle += change;
  
  //Set the ending value of the rotation to the new angle.
  rotation.toValue = @(angle);
  
  //Have the rotation use linear timing.
  rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  
  /*
  
   This is the magic bit. We add a CAValueFunction that tells the CAAnimation we are modifying
   the transform's rotation around the Z axis.
   Without this, we would supply a transform as the fromValue and toValue, and for rotations
    > a half-turn, we could not control the rotation direction.

   By using a value function, we can specify arbitrary rotation amounts and directions, and even
   Rotations greater than 360 degrees.
  */
  
  rotation.valueFunction = [CAValueFunction functionWithName: kCAValueFunctionRotateZ];
  
  //Make ourselves the animation's delegate, so we get called when it's finished.
  rotation.delegate = self;
  animationStartTime = CACurrentMediaTime();

  
  //Create a block of code to be executed once our animation finishes.
  completionBlock = ^void(void)
  {
    animateButton.enabled = YES;
    animateCAButton.enabled = YES;
    rotateButton.enabled = YES;
    pauseButton.enabled = NO;
    stopButton.enabled = NO;

    animationSlider.enabled = NO;
    animationSlider.value = 0;

    imageViewToAnimate.layer.transform = CATransform3DIdentity;
    [sliderTimer invalidate];
    _animationIsPaused = NO;
    imageViewToAnimate.layer.timeOffset = 0;
    [self setPauseButtonTitle];
  };
  
  /*
   Attach the completion block to the animation using the key kAnimationCompletionBlock.
   Our animationDidStop:finished: delegate method will execute this block when the animation completes.
   
   Unlike most objects, CAAnimation and CALayer objects allow you 
   to attach any arbitrary key/value pair to them.
   */
  
  [rotation setValue: completionBlock forKey: kAnimationCompletionBlock];
  
  /*
    Set the layer's transform to it's final state before submitting the animation, so it is in it's
    final state once the animation completes.
   */
  imageViewToAnimate.layer.transform = CATransform3DRotate(imageViewToAnimate.layer.transform, angle, 0, 0, 1.0);
  
  //Now actually add the animation to the layer.
  [self startSliderTimer];
  [imageViewToAnimate.layer addAnimation:rotation forKey:@"transform.rotation.z"];
}

//------------------------------------------------------------------------------------------------------
/*
 This method does a keyframe animation that is visually identical to the doKeyFrameViewAnimation method,
 But it uses CAKeyframeAnimation objects instead of using the new iOS 7 view-based keframe animations.
 
 */


- (void) doKeyframeCAAnimation;
{
  CGSize imageSize = imageViewToAnimate.bounds.size;
  
  //Create a rectangle to contain the center-point of our animations
  //(inset by 20 pixels + the height & width of the image view
  CGRect animationBounds = CGRectIntegral(
                                          CGRectInset(
                                                      animationView.bounds, 20 + imageSize.width/2,
                                                      20+imageSize.height/2));
  totalAnimationTime = 8.0;
  
  //Remember the time when we start the animation (we'll use that value in calculating the slider
  //Poistion as well as in figuring out how to pause the animation.
  animationStartTime = CACurrentMediaTime();
  
  //Make sure the animation is set to begin at the start of the animation duration.
  imageViewToAnimate.layer.beginTime = 0;
  
  animationProgress = 0;
  
  [self startSliderTimer];
  
  __block CGFloat animationSteps = K_KEYFRAME_STEPS;
  
  CGFloat stepDistance = round(animationBounds.size.width / animationSteps);
  
   int stepCount;
  
  animationSlider.enabled = YES;
  pauseButton.enabled = YES;
  stopButton.enabled = YES;

  animationCompletionBlock completionBlock;

  //-----------------------------------
  
//  imageViewToAnimate.center = keyframeAnimationPlaceholder.center;

  //Create a keyframe CAAnimation that moves the view's layer using cubic calculations
  CAKeyframeAnimation* keyframeMove = nil;
  keyframeMove=  [CAKeyframeAnimation animationWithKeyPath: @"position"];
  keyframeMove.duration = totalAnimationTime;
  keyframeMove.beginTime = 0;
  keyframeMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  keyframeMove.calculationMode = kCAAnimationCubic;
  keyframeMove.removedOnCompletion = FALSE;
  keyframeMove.fillMode = kCAFillModeBackwards;

  NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:animationSteps];
  
  //Add the starting point
  [pathArray addObject: [NSValue valueWithCGPoint: keyframeAnimationPlaceholder.layer.position]];
  for (stepCount = 1; stepCount <= animationSteps; stepCount++)
  {
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

    [pathArray addObject: [NSValue valueWithCGPoint: stepCenter]];
  }

  keyframeMove.values = pathArray;
  
  //Create a block of code to be executed once our animation finishes.
  completionBlock = ^void(void)
  {
    pauseButton.enabled = NO;
    stopButton.enabled = NO;
    
    animationSlider.enabled = NO;
    animationSlider.value = 0;
    
    imageViewToAnimate.layer.transform = CATransform3DIdentity;
    [sliderTimer invalidate];
    _animationIsPaused = NO;
    imageViewToAnimate.layer.timeOffset = 0;

    //After a pause, Animate the image view back to it's starting point.
    _animationIsPaused = NO;
    imageViewToAnimate.layer.speed = 1.0;
    [UIView animateWithDuration: .2
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
       animateCAButton.enabled = YES;
       rotateButton.enabled = YES;
       
       [self setPauseButtonTitle];
     }];
};

  [keyframeMove setValue: completionBlock forKey: kAnimationCompletionBlock];
  keyframeMove.delegate = self;

  [imageViewToAnimate.layer addAnimation: keyframeMove forKey: @"CALayerKeyframes"];
  imageViewToAnimate.layer.position = [[pathArray lastObject] CGPointValue];
  
  //-----------------------------------
//Create a keyframe CAAnimation that rotates the view's layer as it moves
  

  
#if K_ROTATE
  CAKeyframeAnimation* keyframeRotate;
  angle = 0;
  animationSteps = 6;
  keyframeRotate=  [CAKeyframeAnimation animationWithKeyPath: @"transform"];
  keyframeRotate.removedOnCompletion = FALSE;
  keyframeRotate.duration = totalAnimationTime;
  keyframeRotate.beginTime = 0;
  keyframeRotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  
  keyframeRotate.valueFunction = [CAValueFunction functionWithName: kCAValueFunctionRotateZ];
  keyframeRotate.delegate = self;
  
  //Build an array of angles for rotating the view
  NSMutableArray *anglesArray = [NSMutableArray arrayWithCapacity:animationSteps];
  //Add the starting angle
  [anglesArray addObject: @0];

  for (stepCount = 1; stepCount <= animationSteps; stepCount++)
  {
    angle = M_PI * 4 * stepCount/animationSteps;
    [anglesArray addObject: @(angle)];
  }
  keyframeRotate.values = anglesArray;
  [imageViewToAnimate.layer addAnimation: keyframeRotate forKey: @"CALayerRotateKeyframes"];
#endif
}
//------------------------------------------------------------------------------------------------------
/*
 This method uses the new iOS 7 UIView class method
 animateKeyframesWithDuration:delay:options:animations:completion:
 to run a multi-step keyframe animation on our image view "imageViewToAnimate".
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
  totalAnimationTime = 8.0;
  
  //Remember the time when we start the animation (we'll use that value in calculating the slider
  //Poistion as well as in figuring out how to pause the animation.
  animationStartTime = CACurrentMediaTime();
  
  //Make sure the animation is set to begin at the start of the animation duration.
  imageViewToAnimate.layer.beginTime = 0;
  
  animationProgress = 0;

  [self startSliderTimer];
  
  __block CGFloat animationSteps = K_KEYFRAME_STEPS;
  
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
#if K_LOG_KEYFRAME_STEPS
    NSLog(@"    Animation center = %@", NSStringFromCGPoint(stepCenter));
#endif
    imageViewToAnimate.center = stepCenter;
  };
  
  //--------------
  /*
   The method animateKeyframesWithDuration:delay:options:animations:completion: lets you trigger
   a sequence of animations in a block. Each animation in the sequence is specified 
   with a call to addKeyframeWithRelativeStartTime:relativeDuration:animations:
   The start time is in the range 0..1 
   (0= first instant of the keyframe sequence, and 1= the last instanct of the keyframe sequence.)
   
   Likewise the relativeDuration parameter ranges from 0 to 1, where 0 means it takes no time at all, and 1
   means it uses the duration of the entire keyframe sequence.
   
   you can submit your individual keyframe steps in any order, and you can even have mulitple 
   keframes running at the same time.
   
   Furthermore, these keyframe animation steps can operate on mulitple different view objects.
   */
  
  animationSlider.enabled = YES;
  pauseButton.enabled = YES;
  stopButton.enabled = YES;

  printf("\n");
#if K_LOG_KEYFRAME_STEPS
  NSLog(@"Building keyframe view animation");
#endif
  [UIView animateKeyframesWithDuration: totalAnimationTime
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
#if K_LOG_KEYFRAME_STEPS
       NSLog(@"  Adding animation step %d, start time = %.3f, duration = %.3f", stepCount, startTime, relDuration);
#endif
       [UIView addKeyframeWithRelativeStartTime: startTime
                               relativeDuration: relDuration
                                     animations: animationStepBlock
        ];
     }
     printf("\n");

#if K_ROTATE

     /*
      Also animate a change to the rotation of the view's layer. We run this animation in 6 steps to show that
      the 2 sets of keyframes are run independently and concurrently.
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
#endif
   }
   //Provide a completion block for the entire keyframe sequnce.
                            completion: ^(BOOL finished)
   {
     //Stop the slider animation
     [sliderTimer invalidate];
     
     //Disable the slider, pause/resume button, and stop button
     animationSlider.enabled = NO;
     pauseButton.enabled = NO;
     stopButton.enabled = NO;

     //Reset the slider value to zero.
     animationSlider.value = 0;


     //After a pause, Animate the image view back to it's starting point.
     _animationIsPaused = NO;
     [UIView animateWithDuration: .2
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
        animateCAButton.enabled = YES;
        rotateButton.enabled = YES;

        [self setPauseButtonTitle];
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

- (void) startSliderTimer;
{
  sliderTimer = [NSTimer scheduledTimerWithTimeInterval: 1/30.0
                                                 target: self selector: @selector(handleSliderTimer:)
                                               userInfo: nil
                                                repeats: YES];
}

//-----------------------------------------------------------------------------------------------------------
//This timer method simply figures out how far we are into the current animation
//and updates the slider position.

- (void) handleSliderTimer: (NSTimer *) timer;
{
  animationProgress = CACurrentMediaTime() - animationStartTime;
  CGFloat sliderValue = animationProgress/totalAnimationTime;
  animationSlider.value = sliderValue;
}

//-----------------------------------------------------------------------------------------------------------
//Set the title of the pause/resume button based on the state of _animationIsPaused

- (void) setPauseButtonTitle;
{
  NSString *buttonTitle;
  
  //Create localized version of the strings "Pause" & "Continue"
  NSString *pauseString = NSLocalizedString(@"Pause", nil);
  NSString *continueString = NSLocalizedString(@"Continue", nil);
  
  buttonTitle = _animationIsPaused ? continueString: pauseString;
  [pauseButton setTitle: buttonTitle forState: UIControlStateNormal];
}

//-----------------------------------------------------------------------------------------------------------
#pragma mark - IBAction methods
//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleAnimateButton:(UIButton *)sender
{
  NSInteger tag = sender.tag;
  //Before we start, disable the animation buttons so the user can't trigger an animation until we're done
  animateButton.enabled = NO;
  animateCAButton.enabled = NO;
  rotateButton.enabled = NO;
  
  //Don't enable the pause/continue button or stop button until after we animate the image view to its
  //Starting position.

  animationProgress = 0;

  imageViewToAnimate.layer.timeOffset = 0;


  //First move the image view to it's starting position in the lower left corner of the screen
  [UIView animateWithDuration: .2
                   animations:
   ^{
     imageViewToAnimate.center = keyframeAnimationPlaceholder.center;
   }
                   completion:^(BOOL finished)
   {
     //Once that animation is done, trigger the keyframe animation after a brief pause.
     if (tag == 1)
       [self performSelector: @selector(doKeyFrameViewAnimation) withObject: nil afterDelay: .75];
     else
       [self performSelector: @selector(doKeyframeCAAnimation) withObject: nil afterDelay: .75];
   }
   ];
}

//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleRotateButton:(UIButton *)sender
{
  //Before we start, disable the animation buttons so the user can't trigger an animation until we're done
  animateButton.enabled = NO;
  animateCAButton.enabled = NO;
 rotateButton.enabled = NO;
  
  //enable the pause/resume and stop buttons
  pauseButton.enabled =YES;
  stopButton.enabled = YES;
  animationSlider.enabled = YES;
  
  //Remember the time when we start the animation (we'll use that value in calculating the slider
  //Poistion as well as in figuring out how to pause the animation.)
  animationStartTime = CACurrentMediaTime();
  
  animationProgress = 0;
  
  [self handleRotate];
}
//-----------------------------------------------------------------------------------------------------------

- (IBAction)handlePauseButton:(UIButton *)sender
{
  self.animationIsPaused = !self.animationIsPaused;
}

//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleAnimationSlider:(UISlider *)sender
{
  CGFloat sliderValue = sender.value;
  
  //Calculate how far we should be into the total animation, in seconds.
  CGFloat temp = sliderValue * totalAnimationTime;

  //Calculate an offset into the animation based on the previous value of animationProgress.
  //Do this before pausing the animation, because pausing the animation changes animationProgress.
  CFTimeInterval offset = animationStartTime + animationProgress;
  
  if (!self.animationIsPaused)
    self.animationIsPaused = YES;

  imageViewToAnimate.layer.timeOffset = offset;
  animationProgress =  temp;
}


//-----------------------------------------------------------------------------------------------------------

- (IBAction)handleStopButton:(UIButton *)sender
{
  //Stop the slider timer
  [sliderTimer invalidate];
  
  //Remove all CAAnimations running on our image view layer (this works both for UIView animations and for
  //Explicit CAAnimations, because UIView animations create CACAnimations "under the covers"
  [imageViewToAnimate.layer removeAllAnimations];
  imageViewToAnimate.layer.speed = 1.0;
}

@end
