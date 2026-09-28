//
//  NSBundle-Extensions.h
//  Disk Inventory X
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle(Extensions)

// Loads a nib from the main bundle and returns its top-level objects, or nil
// if it could not be loaded. The caller keeps the returned array for as long
// as it needs the nib's objects.
+ (nullable NSArray *) topLevelObjectsOfNibNamed: (NSString *) nibName owner: (id) owner;

@end

NS_ASSUME_NONNULL_END
