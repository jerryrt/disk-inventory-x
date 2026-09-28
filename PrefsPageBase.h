//
//  PrefsPageBase.h
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

#import <Cocoa/Cocoa.h>

// Owner of a preference page nib. The nib connects "controlBox" to the view
// holding the page's controls, which are bound to the shared user defaults
// controller.
@interface PrefsPageBase : NSObject
{
	NSView *controlBox;
	NSView *initialFirstResponder;
	NSView *lastKeyView;
	NSArray *_topLevelObjects;
}

@property (nonatomic, retain) IBOutlet NSView *controlBox;
@property (nonatomic, assign) IBOutlet NSView *initialFirstResponder;
@property (nonatomic, assign) IBOutlet NSView *lastKeyView;

- (instancetype) initWithNibName: (NSString *) nibName;

@end
