//
//  NSObject+setAssocValueForKey.h
//  ChromaKey
//
//  Created by Duncan Champney on 12/4/12.
//
//

/*
 //-----------------------------------------------------------------------------------------------------------
 This category allows you to add key/value pairs to any NSObject. 
 
 To use it, simply #import the header NSObject+setAssocValueForKey.h. 
 That lets the compiler know about the 2 methods setAssocValue:forKey: and assocValueForKey (described below)
 
 It forces you to use an NSString object as the key, and also forces the value obejct to be an NSObject,
 not an id pointer, for better type safety. 
 
 Call setAssocValue:forKey: on an object to add a key/value to that object. 
 (Used just like the KVO method setValue:forKey:, 
 except the property in the key does not need to be defined in the target object.
 
 Call assocValueForKey: to fetch the value stored for a key (if any) 
 (Just like the KVO method valueForKey: )
 
 The associated storage is released automatically when the "target object" is released.
 This code should work perfectly in either ARC or manual reference counted programs.
 //-----------------------------------------------------------------------------------------------------------
 */

#import <Foundation/Foundation.h>

@interface NSObject (setAssocValueForKey)

//-----------------------------------------------------------------------------------------------------------
//Add a key/value pair to an object

- (void) setAssocValue: (NSObject *) value forKey: (NSString *) key;

//-----------------------------------------------------------------------------------------------------------
//Fetch a saved value for the specified key. Returns nil if no object can be found with that key.

- (NSObject *) assocValueForKey: (NSString *) key;
//-----------------------------------------------------------------------------------------------------------


@end
