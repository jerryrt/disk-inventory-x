//
//  PrefsPageBase.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 29.11.04.
//
//  Copyright (C) 2004 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.

#import "PrefsPageBase.h"

@implementation PrefsPageBase

- (instancetype) initWithNibName: (NSString *) nibName
{
	self = [super init];
	if ( self != nil )
	{
		NSArray *topLevelObjects = nil;
		if ( ![[NSBundle mainBundle] loadNibNamed: nibName owner: self topLevelObjects: &topLevelObjects] )
		{
			return nil;
		}
		_topLevelObjects = topLevelObjects;
	}
	return self;
}


@end
