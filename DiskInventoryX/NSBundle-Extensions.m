//
//  NSBundle-Extensions.m
//  Disk Inventory X
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

#import "NSBundle-Extensions.h"

@implementation NSBundle(Extensions)

+ (NSArray *) topLevelObjectsOfNibNamed: (NSString *) nibName owner: (id) owner
{
	NSArray *topLevelObjects = nil;
	if ( ![[NSBundle mainBundle] loadNibNamed: nibName owner: owner topLevelObjects: &topLevelObjects] )
		return nil;
	
	return topLevelObjects;
}

@end
