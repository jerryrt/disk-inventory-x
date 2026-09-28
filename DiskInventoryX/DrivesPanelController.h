//
//  DrivesPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 15.11.04.
//
//  Copyright (C) 2004 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.

//

#import <Cocoa/Cocoa.h>


@interface DrivesPanelController : NSObject
{
	NSArray *_nibObjects; //top-level objects of our nib
	NSMutableArray *_volumes;
	NSMutableArray *_progressIndicators;
	__weak IBOutlet NSTableView* _volumesTableView;
	__weak IBOutlet NSWindow* _volumesPanel;
	__weak IBOutlet NSButton* _openVolumeButton;
	__weak IBOutlet NSArrayController *_volumesController;
    
    unsigned long long _maxVolumeSize; // size of largest volumes
}

+ (DrivesPanelController*) sharedController;

- (BOOL) panelIsVisible;
- (void) showPanel;
- (NSWindow*) panel;

- (NSArray*) volumes;

- (IBAction) openVolume:(id)sender;

@end
