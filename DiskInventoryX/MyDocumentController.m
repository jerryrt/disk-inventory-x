//
//  MyDocumentController.m
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

#import "MyDocumentController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "NSBundle-Extensions.h"
#import "DrivesPanelController.h"
#import "Preferences.h"
#import "PrefsPanelController.h"
#import "FileSystemDoc.h"
#import "MainWindowController.h"

//global variable which enables/disables logging
BOOL g_EnableLogging;

//============ implementation MyDocumentController ==========================================================

@implementation MyDocumentController

- (NSInteger) runModalOpenPanel: (NSOpenPanel*) openPanel forTypes: (NSArray*) extensions
{
    //we want the user to choose a directory (including packages)
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    [openPanel setTreatsFilePackagesAsDirectories: YES];
	
	return [openPanel runModal];
}

- (void) openFolderAtURL: (NSURL*) url
{
	[self openDocumentWithContentsOfURL: url
								display: YES
					  completionHandler: ^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
		//a canceled scan is reported as NSUserCancelledError, which isn't shown
		if ( document == nil && error != nil )
			[self presentError: error];
	}];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender
{
    //we don't want any untitled document as we need an existing folder
    return NO;
}

//every directory (folder, package or volume) is opened as a document of the
//type declared in Info.plist (document types declared by UTI are named by it)
- (NSString *) typeForContentsOfURL: (NSURL *) url error: (NSError **) outError
{
	NSNumber *isDirectory = nil;
	if ( [url getResourceValue: &isDirectory forKey: NSURLIsDirectoryKey error: NULL] && [isDirectory boolValue] )
		return UTTypeDirectory.identifier;
	
	return [super typeForContentsOfURL: url error: outError];
}

//"Open..." menu handler
- (IBAction)openDocument:(id)sender
{
	//we implement this method by ourself, so we can avoid that stupid message "document couldn't be opened"
	//in the case the user canceled the opening
	NSArray<NSURL *> *fileNames = [self URLsFromRunningOpenPanel];
	
	if ( fileNames == nil )
		return; //cancel pressed in open panel
	
	for ( NSURL *dir in fileNames )
		[self openFolderAtURL: dir];
}

+ (void)restoreWindowWithIdentifier:(NSUserInterfaceItemIdentifier)identifier
                              state:(NSCoder *)state
                  completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    // prevent any window, which was open when quitting the app last time, to be re-opened now at the next lauch
    // (see https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocBasedAppProgrammingGuideForOSX/StandardBehaviors/StandardBehaviors.html#//apple_ref/doc/uid/TP40011179-CH5-SW4
    // Document-Based App Programming Guide for Mac/Core App Behaviors/Windows Are Restored Automatically)
    completionHandler(nil, nil);
}

//Application's delegate; called if file from recent list is selected
- (BOOL) application: (NSApplication*) theApp openFile: (NSString*) fileName
{
	//if "fileName" doesn't exist or isn't a folder, return NO so that it is removed from the recent list
	NSDictionary *attribs = [[NSFileManager defaultManager] attributesOfItemAtPath: fileName error:nil];
    if ( attribs == nil || ![[attribs fileType] isEqualToString: NSFileTypeDirectory] )
		return NO;

	[self openFolderAtURL: [NSURL fileURLWithPath: fileName]];
	
	//return TRUE to avoid nasty message if user canceled loading
	return TRUE;
}

- (IBAction) showPreferencesPanel: (id) sender
{
	[[PrefsPanelController sharedPreferenceController] showPreferencesPanel: self];
	//[[OAPreferenceController sharedPreferenceController] showPreferencesPanel: self];
}

- (IBAction) gotoHomepage: (id) sender
{
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.derlien.com"]];
}

- (IBAction) closeDonationPanel: (id) sender;
{
	[_donationPanel close]; //will release itself
	_donationPanel = nil;
}


#pragma mark --------app notifications-----------------

- (void) applicationWillFinishLaunching: (NSNotification*) notification
{
    //verify that our custom DocumentController is in use 
    NSAssert( [[NSDocumentController sharedDocumentController] isKindOfClass: [MyDocumentController class]], @"the shared DocumentController is not our custom class!" );
    
    //@@test
    //[[OAController sharedController] applicationWillFinishLaunching:notification];
	
	g_EnableLogging = [[NSUserDefaults standardUserDefaults] boolForKey: EnableLogging];
    
	//show the drives panel before "applicationDidFinishLaunching" so the panel is visible before the first document is loaded
	//(e.g. through drag&drop)
	[[DrivesPanelController sharedController] showPanel];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    //@@test
    //[[OAController sharedController] applicationDidFinishLaunching:notification];

    //show donate message
	if ( ![[NSUserDefaults standardUserDefaults] boolForKey: DontShowDonationMessage] )
	{
		_nibObjects = [NSBundle topLevelObjectsOfNibNamed: @"DonationPanel" owner: self];
		[_donationPanel setWorksWhenModal: YES];
	}
	
//	DIXFinderCMInstaller *installer = [DIXFinderCMInstaller installer];
//	if ( ![installer isInstalled] )
//		[installer installToDomain: kUserDomain];
}

#pragma mark -----------------NSMenu delegates-----------------------

- (void) menuNeedsUpdate: (NSMenu*) zoomStackMenu
{
	NSAssert( _zoomStackMenu == zoomStackMenu, @"precondition failed" );
	
	FileSystemDoc *doc = [self currentDocument];
	NSArray *zoomStack = [doc zoomStack];
	
	//thanks to ObjC, [zoomStack count] will evaluate to 0 if there is no current doc
	unsigned i;
	for ( i = 0; i < [zoomStack count]; i++ )
	{
		FSItem *fsItem = nil;
		if ( i == 0 )
			fsItem = [doc rootItem];
		else
			fsItem = [zoomStack objectAtIndex: i-1];
		
		if ( i >= ((unsigned) [zoomStackMenu numberOfItems]) )
			[zoomStackMenu addItem: [[NSMenuItem alloc] init]];
		
		NSMenuItem *menuItem = [zoomStackMenu itemAtIndex: i];
		
		[menuItem setTitle: [fsItem displayName]];
		if ( i > 0 ) //no tooltip for first item as the tooltip is the same as the title
			[menuItem setToolTip: [fsItem displayPath]];
		[menuItem setImage: [fsItem iconWithSize: 16]];
		[menuItem setRepresentedObject: fsItem];
		[menuItem setTarget: nil];
		[menuItem setAction: @selector(zoomOutTo:)];
	}
	
	//remove any supernumerary menu items
	while ( ((unsigned) [zoomStackMenu numberOfItems]) > [zoomStack count] )
		[zoomStackMenu removeItemAtIndex: [zoomStackMenu numberOfItems] -1];
}

@end

