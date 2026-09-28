//
//  InfoPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 16.11.04.
//
//  Copyright (C) 2004 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.

//

#import <Cocoa/Cocoa.h>
#import "FSItem.h"

@class DIXFileInfoView;

@interface InfoPanelController : NSObject
{
	NSArray *_nibObjects; //top-level objects of our nib
	__weak IBOutlet DIXFileInfoView *_infoView;
	__weak IBOutlet NSWindow* _infoPanel;
	__weak IBOutlet NSTextField* _displayNameTextField;
	__weak IBOutlet NSImageView* _iconImageView;
}

+ (InfoPanelController*) sharedController;

- (BOOL) panelIsVisible;
- (void) showPanel;
- (void) hidePanel;
- (void) showPanelWithFSItem: (FSItem*) fsItem;
- (NSWindow*) panel;

@end
