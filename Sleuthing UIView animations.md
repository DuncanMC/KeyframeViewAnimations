##Tutorial: Sleuthing UIView animations:


With early versions of iOS, UIView animations were pretty limited. Prior to iOS 4, you had to use `beginAnimations:context:` …  `commitAnimations` to create `UIView` animations.

For many types of animation, you had to resort to writing your own `CAAnimation` code and manipulating `CALayer`s instead of views.

Apple has been gradually adding better and more powerful animation methods to the UIKit classes like `UIView`.
Beginning with iOS 4, Apple added animations that took block parameters, in the form `animateWithDuration:animations:` (and variations)

Since then, Apple has added view and view controller transitions, keyframe view animations, animations with spring dynamics, UIKit dynamics, and lots of other cool tricks. These higher-level animation methods are usually simpler to use and easier to understand than their Core Animation counterparts.

Behind the scenes, though, these higher level animation methods are still creating `CAAnimation` objects and attaching them to your view's layers, along with custom code to make everything work correctly.

Sometimes it's useful to see what's going on and how the UIKit makes the animations work.

It is also possible to manipulate the under-the-covers `CAAnimation`s. You can pause or restart an animation that was created using `UIView` animation calls, or "scrub" it (a video editing term) backwards or forwards by manipulating the underlying `CAAnimation` objects and their settings. As it turns out you can also fix bugs in the animations that the system creates on your behalf (see below) before submitting them.

It's actually pretty easy to make the animations the system creates visible. Credit for this technique goes to David Rönnqvist on Stack Overflow. 

Here is the technique I came up with, based on his idea:

Create a custom subclass of the view class that you're animating. (e.g. if it's a `UIImageView`, create a custom subclass of `UIImageView`. If it's some other view type, make the base class that other type, or you can  even subclass `UIView` directly.)

In my example I'll use a view class of **DebugImageView** and a CALayer subclass of **DebugLayer**. You might want to add your company's initials (or your initials if you are an individual developer) as a prefix to the class name to avoid possible name conflicts. (e.g. for a company called "MyCompany", you might use the prefix "MC", making the custom UIImageView class name "**MCDebugImageView**" and your custom `CALayer` subclass "**MCDebugLayer**." I skip that step here for simplicity.

In the .m for your custom UIView subclass, add the following method:

```Objective-C
+ (Class)layerClass
{
  return [DebugLayer class];
}
```

This one method causes your custom view to use a custom layer type of DebugLayer as the backing layer for the view instead of a generic CALayer object. So any time you create a view of your custom type, it's layer will by a DebugLayer rather than a normal CALayer.


In the examples below we'll be working with animations on a `UIImageView`, so that's the type of view for which we create a custom subclass. If you're debugging animations on other types of views, you may find that your view type uses a different type of backing layer than a CALayer. To figure out what type of layer a view takes, you would create a custom subclass of the view you were trying to animate, and then add a `+layerClass` class method like this to your custom `UIView` subclass:

```Objective-C
+ (Class)layerClass
{
  Class myLayerClass = [super layerClass];
  NSLog(@"The UIView subclass %@  uses a backing layer of class %@", [self superclass], myLayerClass);
  return myLayerClass;
}
```

Then create a new class, DebugLayer (or MCDebugLayer), that inherits from CALayer (or the layer class used by your particular UIView, if you're animating a view type that uses a different kind of layer.)

The DebugLayer header is very simple:


```Objective-C
#import <QuartzCore/QuartzCore.h>

@interface DebugLayer : CALayer

@end
```

In your **DebugLayer**'s .m file, add the following method:


```Objective-C
- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key
{
  NSLog(@"Adding animation for key \"%@\". Animation = %@", key, anim);
  [super addAnimation: anim forKey: key];
}
```

Now, in your project's XIB file or Storyboard, anywhere you have a `UIImageView` object that you want to animate, select the view object in IB, display the identity inspector, and switch the object's class from it's base class to your custom subclass. In the demo below, we're working with animations added to a UIImageView, so we created a custom subclass of `UIImageView` called **DebugImageView**. 

Once you've added the classes **DebugImageView** class and **DebugLayer** class to your project, and changed the class of a UIImageView object in your XIB/Storyboard to DebugImageView, you will see a simple entry in the debug console for every animation that is added to your image view object.

I originally did this because I was trying to track down an odd behavior with the new iOS 7 keyframe view animation method `animateKeyframesWithDuration:delay:options:animations:completion:`. That method uses a series of other method calls to the UIView class method `addKeyframeWithRelativeStartTime:relativeDuration:animations:` to add one or more keyframe animations to one or more views.

Keyframe `UIView` animations end up creating one or more corresponding `CAKeyframeAnimation` objects and adding them to your view's layer, so when you run a keyframe view animation on a **DebugImageView**, you'll see an entry in the debug console listing one or more  `CAKeyframeAnimation` objects being added to your view's layer.

CAKeyframeAnimation animations can either take an array of key values or a CGPath (which is the Core Graphics object that backs a UIBezierPath. It is based on Core Foundation rather than NSObject.) If you create a UIView keyframe animation using animateKeyframesWithDuration:delay:options:animations:completion:, you will find that the system creates one or more CAKeyframeAnimation objects with an NSArray of NSValue objects in it's values property that correspond to the key values you specify, plus an array of time values in the keyTimes property.

I first started sleuthing UIView keyframe animations when I was animating the position of a UIImageView using cubic calculation mode, which causes the image view to follow a curved path through the list of positions that I specified. I was getting some odd behavior in the path my animations followed. It looked like there was a bug in the resulting animations. For some of the points in the animation, my image view would bounce off the point rather than following a smooth curve through it. Exactly which points, and how many points, showed the odd behavior varied with the number of keyframes in the animation.

I thus developed a DebugLayer class that logged all the keyframe values for every CAKeyframeAnimation that was submitted to the layer.

For a keyframe UIView animation, the system creates a CAKeyframeAnimation that has an NSArray of CGPoint coordinates. The CGPoint values are packaged as NSValue objects so they can be contained in an NSArray.

I found that for the keyframe values that showed the odd behavior, the system was submitting a duplicate entry in the values array. (Both the coordinates of the point in the values array and the value of the time entry in the keyTimes array were duplicated, although the floating point value for the entry in keyTimes was different by a very tiny amount, so I needed to make the logic check for keyTime values that were "really close" to the other value (I settled on checking for key time values that were within .0001 of each other.

I then went on to write code that detected the duplicate values in values & keyTimes and remove the duplicates. (I did that by creating mutable copies of the values and keyTimes arrays, and copying all the non-duplicate entries to the new array, then installing the "condensed" arrays back into the animation object before submitting to the system with a call to 

  [super addAnimation: anim forKey: key];

Sure enough, when I remove duplicate keyframe entries from the values and keyTimes arrays, the odd bouncing effect goes away from position animations.

I ended up with a custom DebugLayer class that will optionally log each animation that is added to it, and also optionally detect and remove duplicate keyframe/keyTime values. The code is driven by a set of compiler switches that lets me turn logging and fixes on or off at will. I also added compiler switches that let me turn cubic calculation mode on or off, turn off a rotation animation that also submitted at the same time, vary the number of steps in the keyframe animation.  The switch definitions look like this:


#define K_USE_CUBIC_PACING 1
#define K_ROTATE 1
#define K_KEYFRAME_STEPS 6
#define K_FIX_ANIMATION 1
#define K_LOG_KEYFRAME_STEPS 0

The code for my custom DebugLayer's addAnimation:forKey: method has gotten pretty convoluted in order to handle the different compiler flags, but the concept is pretty straightforward. It would be easy to add code to log lots of different animation settings for the types of animations you are analyzing. 

A sample project that uses the DebugImageView and DebugLayer class described above is available on github at https://github.com/DuncanMC/KeyframeViewAnimations.


Duncan Champney
WareTo
