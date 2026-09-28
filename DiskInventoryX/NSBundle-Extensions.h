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

// Loads a nib from the main bundle with the ownership rules of the
// deprecated +loadNibNamed:owner:, i.e. every top-level object is retained
// once on behalf of the owner. Code written for that method (e.g. panels
// which release themselves when closed) keeps working unchanged.
+ (BOOL) loadRetainingNibNamed: (NSString *) nibName owner: (id) owner;

@end

NS_ASSUME_NONNULL_END
