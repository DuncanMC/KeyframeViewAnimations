//
//  DebugLayer.m
//  KeyframeViewAnimations
//
//  Created by Duncan Champney on 2/25/14.
//  Copyright (c) 2014 WareTo. All rights reserved.
//

#import "DebugLayer.h"
#import "Constants.h"

@implementation DebugLayer

- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key
{
  
#if K_LOG_KEYFRAME_STEPS
  NSLog(@"Adding animation for key \"%@\". Animation = %@", key, anim);
#endif
  if ([anim isMemberOfClass: [CAKeyframeAnimation class]])
  {
#if K_LOG_KEYFRAME_STEPS || K_FIX_ANIMATION
    CAKeyframeAnimation *keyframe = (CAKeyframeAnimation *) anim;
#endif
    
#if K_LOG_KEYFRAME_STEPS
    for (int index = 0; index<keyframe.values.count; index++ )
    {
      NSValue *aValue = keyframe.values[index];
      NSNumber *aTime = keyframe.keyTimes[index];
      NSLog(@"  Key %d, value = %@,\ttime = %.2f", index, aValue, aTime.floatValue);
    }
#endif
    
    
#if K_FIX_ANIMATION
    NSMutableArray *newValues = [keyframe.values mutableCopy];
    NSMutableArray *newTimes = [keyframe.keyTimes mutableCopy];
    [newValues removeObjectAtIndex: 8];
    [newTimes removeObjectAtIndex: 8];
#if K_LOG_KEYFRAME_STEPS
    NSLog(@"Removing extra indexes from values and keyTimes");
#endif
    [newValues removeObjectAtIndex: 5];
    [newTimes removeObjectAtIndex: 5];
    
    keyframe.values = newValues;
    keyframe.keyTimes = newTimes;

    for (int index = 0; index<keyframe.values.count; index++ )
    {
      NSValue *aValue = keyframe.values[index];
      NSNumber *aTime = keyframe.keyTimes[index];
#if K_LOG_KEYFRAME_STEPS
      NSLog(@"  Key %d, value = %@,\ttime = %.2f", index, aValue, aTime.floatValue);
#endif
    }
#endif
}
  [super addAnimation: anim
               forKey: key];
}
@end
