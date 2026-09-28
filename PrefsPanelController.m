//
//  PrefsPanelController.m
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

#import "PrefsPanelController.h"
#import "PrefsPageBase.h"

static NSString *PageIdentifierKey = @"identifier";
static NSString *PageClassKey = @"class";
static NSString *PageNibKey = @"nib";
static NSString *PageIconKey = @"icon";
static NSString *PageTitleKey = @"title";

static NSString *SelectedPageDefaultsKey = @"PreferencesSelectedPage";

@interface PrefsPanelController(Private)
- (void) selectPage: (NSString *) identifier;
@end

@implementation PrefsPanelController

+ (PrefsPanelController*) sharedPreferenceController
{
	static PrefsPanelController *sharedPreferenceController = nil;
	
	if (sharedPreferenceController == nil)
		sharedPreferenceController = [[self alloc] init];

	return sharedPreferenceController;
}

- (instancetype) init
{
	NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect( 0, 0, 400, 200 )
												   styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
													 backing: NSBackingStoreBuffered
													   defer: YES];
	[window setReleasedWhenClosed: NO];
	
	self = [super initWithWindow: window];
	[window release];
	
	if ( self != nil )
	{
		_pageDescriptions = [@[
			@{ PageIdentifierKey: @"GeneralPrefPage",
			   PageClassKey: @"GeneralPrefPage",
			   PageNibKey: @"GeneralPreferencesPage",
			   PageIconKey: @"GeneralPreferences",
			   PageTitleKey: @"General" },
			@{ PageIdentifierKey: @"TreeMapPrefPage",
			   PageClassKey: @"TreeMapPrefPage",
			   PageNibKey: @"TreeMapPreferencesPage",
			   PageIconKey: @"TreeMapPreferences",
			   PageTitleKey: @"Treemap" },
		] retain];
		_pages = [[NSMutableDictionary alloc] init];
		
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: @"PreferencesToolbar"];
		[toolbar setDelegate: self];
		[toolbar setAllowsUserCustomization: NO];
		[window setToolbarStyle: NSWindowToolbarStylePreference];
		[window setToolbar: toolbar];
		[toolbar release];
		
		NSString *selected = [[NSUserDefaults standardUserDefaults] stringForKey: SelectedPageDefaultsKey];
		if ( [self descriptionForPage: selected] == nil )
			selected = [[_pageDescriptions firstObject] objectForKey: PageIdentifierKey];
		[self selectPage: selected];
		
		[window center];
	}
	return self;
}

- (void) dealloc
{
	[_pageDescriptions release];
	[_pages release];
	[super dealloc];
}

- (IBAction) showPreferencesPanel: (id) sender
{
	[self showWindow: sender];
}

- (NSDictionary *) descriptionForPage: (NSString *) identifier
{
	for ( NSDictionary *description in _pageDescriptions )
	{
		if ( [[description objectForKey: PageIdentifierKey] isEqualToString: identifier] )
			return description;
	}
	return nil;
}

- (IBAction) selectPageFromToolbar: (NSToolbarItem *) sender
{
	[self selectPage: [sender itemIdentifier]];
}

#pragma mark -----------------NSToolbar delegate-----------------------

- (NSArray<NSToolbarItemIdentifier> *) pageIdentifiers
{
	return [_pageDescriptions valueForKey: PageIdentifierKey];
}

- (NSArray<NSToolbarItemIdentifier> *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [self pageIdentifiers];
}

- (NSArray<NSToolbarItemIdentifier> *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [self pageIdentifiers];
}

- (NSArray<NSToolbarItemIdentifier> *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar
{
	return [self pageIdentifiers];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar itemForItemIdentifier: (NSToolbarItemIdentifier) identifier willBeInsertedIntoToolbar: (BOOL) flag
{
	NSDictionary *description = [self descriptionForPage: identifier];
	if ( description == nil )
		return nil;
	
	NSString *title = NSLocalizedStringFromTable( [description objectForKey: PageTitleKey], @"Preferences", @"" );
	
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier: identifier] autorelease];
	[item setLabel: title];
	[item setPaletteLabel: title];
	[item setImage: [NSImage imageNamed: [description objectForKey: PageIconKey]]];
	[item setTarget: self];
	[item setAction: @selector(selectPageFromToolbar:)];
	
	return item;
}

@end

@implementation PrefsPanelController(Private)

- (void) selectPage: (NSString *) identifier
{
	NSDictionary *description = [self descriptionForPage: identifier];
	NSAssert1( description != nil, @"unknown preference page '%@'", identifier );
	
	PrefsPageBase *page = [_pages objectForKey: identifier];
	if ( page == nil )
	{
		Class pageClass = NSClassFromString( [description objectForKey: PageClassKey] );
		page = [[[pageClass alloc] initWithNibName: [description objectForKey: PageNibKey]] autorelease];
		NSAssert1( page != nil, @"couldn't load preference page '%@'", identifier );
		[_pages setObject: page forKey: identifier];
	}
	
	NSWindow *window = [self window];
	NSView *view = [page controlBox];
	
	[[window toolbar] setSelectedItemIdentifier: identifier];
	[window setTitle: NSLocalizedStringFromTable( [description objectForKey: PageTitleKey], @"Preferences", @"" )];
	
	if ( [window contentView] == view )
		return;
	
	//resize the window to fit the page, keeping its top edge in place
	NSRect frame = [window frameRectForContentRect: [view frame]];
	NSRect oldFrame = [window frame];
	frame.origin.x = NSMinX( oldFrame );
	frame.origin.y = NSMaxY( oldFrame ) - NSHeight( frame );
	
	[window setContentView: [[[NSView alloc] initWithFrame: NSZeroRect] autorelease]];
	[window setFrame: frame display: YES animate: [window isVisible]];
	[window setContentView: view];
	
	if ( [page initialFirstResponder] != nil )
		[window makeFirstResponder: [page initialFirstResponder]];
	
	[[NSUserDefaults standardUserDefaults] setObject: identifier forKey: SelectedPageDefaultsKey];
}

@end
