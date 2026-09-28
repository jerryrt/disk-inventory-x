//
//  MyDocumentController.h
//  Disk Accountant
//
//  Created by Tjark Derlien on Wed Oct 08 2003.
//
//  Copyright (C) 2003 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

//

#import <Foundation/Foundation.h>


@interface MyDocumentController : NSDocumentController
{
	NSArray *_nibObjects; //top-level objects of our nib
	__weak IBOutlet NSMenu* _zoomStackMenu;
	__weak IBOutlet NSPanel* _donationPanel;
}

- (IBAction) showPreferencesPanel: (id) sender;
- (IBAction) gotoHomepage: (id) sender;
- (IBAction) closeDonationPanel: (id) sender;

// opens a folder, package or volume, reporting errors (but not a canceled scan)
- (void) openFolderAtURL: (NSURL*) url;
@end
