//
//  NSObject+setAssocValueForKey.m
//  ChromaKey
//
//  Created by Duncan Champney on 12/4/12.
//
//
#import <objc/runtime.h>

#import "NSObject+setAssocValueForKey.h"


typedef uintptr_t objc_AssociationPolicy;
//id objc_getAssociatedObject(id object, void *key);
//void objc_setAssociatedObject(id object, void *key, id value, objc_AssociationPolicy policy);
void objc_removeAssociatedObjects(id object);


@implementation NSObject (setAssocValueForKey)

static const char associatedStorageKey;

//-----------------------------------------------------------------------------------------------------------
#pragma mark - Instance methods
//-----------------------------------------------------------------------------------------------------------

- (NSMutableDictionary *) associationDictionary;
{
  NSMutableDictionary *associationDictionary = objc_getAssociatedObject(self, (void*) &associatedStorageKey);
  if (!associationDictionary)
  {
    associationDictionary = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, (void*) &associatedStorageKey, associationDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return associationDictionary;
}

//-----------------------------------------------------------------------------------------------------------

- (void) setAssocValue: (NSObject *) value forKey: (NSString *) key;
{
  NSMutableDictionary * associationDictionary = [self associationDictionary];
  [associationDictionary setValue: value forKey: key];
}

//-----------------------------------------------------------------------------------------------------------

- (NSObject *) assocValueForKey: (NSString *) key;
{
  if (!key.length) return nil;
  
  NSMutableDictionary * associationDictionary = [self associationDictionary];

  return [associationDictionary objectForKey: key];
}

//-----------------------------------------------------------------------------------------------------------

@end
