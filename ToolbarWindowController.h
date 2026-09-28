//
//  ToolbarWindowController.h
//  Disk Inventory X
//
//  Created by Tjark Derlien on 01.12.04.
//
//  Copyright (C) 2004 Tjark Derlien.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.

//

#import <Cocoa/Cocoa.h>

// Passed to -validateMenuItem: in place of a menu item when a toolbar item
// is validated, so that one validation method serves menus and toolbars.
@interface NSToolbarItemValidationAdapter : NSObject
{
	NSToolbarItem* _toolbarItem;
}

- (void) setToolbarItem: (NSToolbarItem*) toolbarItem;
- (void) forwardInvocation: (NSInvocation*) anInvocation;

@end

// Window controller which builds its window's toolbar from a property list
// "<toolbarConfigurationName>.toolbar" in the main bundle. The file contains
// "defaultItemIdentifiers", "allowedItemIdentifiers" and
// "itemInfoByIdentifier". Each item info may have the keys "action",
// "target" (a key path relative to the window controller), "imageName",
// "imageNameOffState", "imageNameMixedState", "label", "paletteLabel" and
// "toolTip". Missing labels and tool tips are taken from the main menu item
// with the same action.
@interface ToolbarWindowController : NSWindowController <NSToolbarDelegate>
{
	NSDictionary *_toolbarConfiguration;
}

// name of the .toolbar file; subclasses must override
- (NSString *) toolbarConfigurationName;

- (NSDictionary *) toolbarInfoForItem: (NSString *) identifier;

- (NSImage*) toolbar: (NSToolbar*) theToolbar imageForToolbarItem: (NSToolbarItem*) item forState: (NSControlStateValue) state;

- (BOOL) validateToolbarItem: (NSToolbarItem *) theItem;

@property (readonly) NSDocumentController *documentController;
@property (readonly) NSApplication *application;

@end
