KeyframeViewAnimations
======================

A project that demonstrates a number of iOS animation techniques:



##Animating a view/layer along a curved path using 2 different types of keyframe animation:




  1. Using the new UIView animation method `animateKeyframesWithDuration:delay:options:animations:completion:`

  2. Using a CAKeyframeAnimation with an array of position values.
  

<br>

##Rotating a view/layer > 180º

animating the view's transform using a `CAValueFunction` of type "kCAValueFunctionRotateZ".


<br>

##Pausing and resuming an "in flight" animation on a layer.

All of the animations in this demo can be paused by clicking a pause/continue button, stopped with a stop button, or "scrubbed" back and forth along their timeline by dragging on a slider.

This works for `UIView` animations as well as animations you create using `CAAnimation` objects. It works because `UIView` aniamtions create `CAAnimation` objects "under the covers" to perform the requested animation.

This is done by manipulating the layer's `speed`, `beginTime`, and `timeoffset` properties.

<br>
##Sleuthing the animations created by UIView animation methods

It's possible to watch the animations that iOS creates when you use `UIView` animation methods like `animateWithDuration:animations:` or `animateKeyframesWithDuration:delay:options:animations:completion:`. Take a look at [this article on sleuthing UIView animations](Sleuthing UIView animations.md).