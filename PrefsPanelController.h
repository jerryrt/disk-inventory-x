//
//  PrefsPanelController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 28.11.04.
//
//  Copyright (C) 2004 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.

#import <Cocoa/Cocoa.h>

// Preferences window with one toolbar button per preference page.
@interface PrefsPanelController : NSWindowController <NSToolbarDelegate>
{
	NSArray<NSDictionary*> *_pageDescriptions;
	NSMutableDictionary *_pages;
}

+ (PrefsPanelController*) sharedPreferenceController;

- (IBAction) showPreferencesPanel: (id) sender;

@end
