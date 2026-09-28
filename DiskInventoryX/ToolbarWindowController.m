//
//  ToolbarWindowController.m
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

#import "ToolbarWindowController.h"

@implementation NSToolbarItemValidationAdapter

- (void) dealloc
{
	[_toolbarItem release];
	[super dealloc];
}

- (void) setToolbarItem: (NSToolbarItem*) toolbarItem
{
	[toolbarItem retain];
	[_toolbarItem release];
	_toolbarItem = toolbarItem;
}

- (void) forwardInvocation: (NSInvocation*) anInvocation
{
	if ( [_toolbarItem respondsToSelector: [anInvocation selector]] )
	{
		[anInvocation setTarget: _toolbarItem];
		[anInvocation invoke];
	}
	else
		[super forwardInvocation: anInvocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL)aSelector
{
	if ( [_toolbarItem respondsToSelector: aSelector] )
		return [_toolbarItem methodSignatureForSelector: aSelector];
	else
		return [super methodSignatureForSelector: aSelector];
}

// Menu items change their title to reflect the current state (e.g. "Show ..."
// and "Hide ..."). NSToolbarItem's own title would appear inside the item's
// button, so the title goes to the label instead.
- (void)setTitle:(NSString *)title
{
	[_toolbarItem setLabel: title];
}

- (void)setState:(NSControlStateValue)itemState
{
	ToolbarWindowController *controller = (ToolbarWindowController *)[[_toolbarItem toolbar] delegate];

    if ( [controller respondsToSelector:@selector(toolbar:imageForToolbarItem:forState:)] )
    {
        NSImage *image = [controller toolbar: [_toolbarItem toolbar]
                         imageForToolbarItem: _toolbarItem
                                    forState: itemState];

        if ( image != nil && image != [_toolbarItem image] )
            [_toolbarItem setImage: image];
    }
}

@end

// Toolbar item which asks the window controller for validation, so that the
// controller has the last word even if the item's target is someone else.
@interface ControllerValidatedToolbarItem : NSToolbarItem
@end

@implementation ControllerValidatedToolbarItem

- (void) validate
{
	id delegate = [[self toolbar] delegate];
	if ( [delegate respondsToSelector: @selector(validateToolbarItem:)] )
		[self setEnabled: [delegate validateToolbarItem: self]];
	else
		[super validate];
}

@end

@interface NSMenu(FindExtensions)

- (NSMenuItem*) menuItemWithAction: (SEL) action;

@end

static NSToolbarItemValidationAdapter *g_toolbarItemValidationAdapter = nil;
static NSMutableDictionary *g_toolbatStateImages = nil;

@implementation ToolbarWindowController

#pragma mark -----------------Toolbar support---------------------

+ (void) initialize
{
	if ( self != [ToolbarWindowController class] )
		return;

	g_toolbarItemValidationAdapter = [[NSToolbarItemValidationAdapter alloc] init];
	g_toolbatStateImages = [[NSMutableDictionary alloc] init];
}

- (void) dealloc
{
	[_toolbarConfiguration release];
	[super dealloc];
}

- (NSString *) toolbarConfigurationName
{
	return nil;
}

- (NSDictionary *) toolbarConfiguration
{
	if ( _toolbarConfiguration == nil )
	{
		NSURL *url = [[NSBundle mainBundle] URLForResource: [self toolbarConfigurationName] withExtension: @"toolbar"];
		NSAssert1( url != nil, @"toolbar configuration '%@' not found", [self toolbarConfigurationName] );

		_toolbarConfiguration = [[NSDictionary alloc] initWithContentsOfURL: url];
	}
	return _toolbarConfiguration;
}

- (void) windowDidLoad
{
	[super windowDidLoad];

	if ( [self toolbarConfigurationName] == nil )
		return;

	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: [self toolbarConfigurationName]];
	[toolbar setDelegate: self];
	[toolbar setAllowsUserCustomization: YES];
	[toolbar setAutosavesConfiguration: YES];

	[[self window] setToolbarStyle: NSWindowToolbarStyleExpanded];
	[[self window] setToolbar: toolbar];
	[toolbar release];
}

// Identifiers of standard items which AppKit no longer supports.
static BOOL IsObsoleteToolbarItemIdentifier( NSString *identifier )
{
	return [identifier isEqualToString: @"NSToolbarSeparatorItem"]
		|| [identifier isEqualToString: @"NSToolbarCustomizeToolbarItem"];
}

- (NSArray<NSToolbarItemIdentifier> *) itemIdentifiersForKey: (NSString *) key
{
	NSMutableArray *identifiers = [NSMutableArray array];
	for ( NSString *identifier in [[self toolbarConfiguration] objectForKey: key] )
	{
		if ( !IsObsoleteToolbarItemIdentifier( identifier ) )
			[identifiers addObject: identifier];
	}
	return identifiers;
}

- (NSArray<NSToolbarItemIdentifier> *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
	return [self itemIdentifiersForKey: @"defaultItemIdentifiers"];
}

- (NSArray<NSToolbarItemIdentifier> *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
	return [self itemIdentifiersForKey: @"allowedItemIdentifiers"];
}

- (NSImage*) toolbar: (NSToolbar*) theToolbar imageForToolbarItem: (NSToolbarItem*) item forState: (NSControlStateValue) state
{
	NSString *imageKey = nil;
	switch( state )
	{
		case NSControlStateValueOn:
			imageKey = @"imageName";
			break;
		case NSControlStateValueOff:
			imageKey = @"imageNameOffState";
			break;
		case NSControlStateValueMixed:
			imageKey = @"imageNameMixedState";
			break;
		default:
			NSAssert( NO, @"invalid item state for ToolbarItem" );
	}

	//get the image cache for our toolbar
	NSMutableDictionary *toolbarImageCache = [g_toolbatStateImages objectForKey: [self toolbarConfigurationName]];
	if ( toolbarImageCache == nil )
	{
		toolbarImageCache = [NSMutableDictionary dictionary];
		[g_toolbatStateImages setObject: toolbarImageCache forKey: [self toolbarConfigurationName]];
	}

	//get image cache for the toolbar item
	NSMutableDictionary *itemImageCache = [toolbarImageCache objectForKey: [item itemIdentifier]];
	if ( itemImageCache == nil )
	{
		itemImageCache = [NSMutableDictionary dictionary];
		[toolbarImageCache setObject: itemImageCache forKey: [item itemIdentifier]];
	}

	//get the state image from the toolbar item image cache
	NSImage *image = [itemImageCache objectForKey: imageKey];
	if ( image == nil )
	{
		NSDictionary *itemInfo = [[[self toolbarConfiguration] objectForKey: @"itemInfoByIdentifier"] objectForKey: [item itemIdentifier]];

		//get image name from info dictionary
		NSString *imageName = [itemInfo objectForKey: imageKey];
		if ( imageName == nil )
			imageName = [itemInfo objectForKey: @"imageName"];

		NSAssert1( imageName != nil, @"no image name for item '%@'", [item itemIdentifier] );

		image = [NSImage imageNamed: imageName];
		NSAssert1( image != nil, @"couldn't load image '%@'", imageName );

		[itemImageCache setObject: image forKey: imageKey];
	}

	return image;
}

- (NSDictionary *)toolbarInfoForItem:(NSString *)identifier
{
	NSDictionary *rawInfo = [[[self toolbarConfiguration] objectForKey: @"itemInfoByIdentifier"] objectForKey: identifier];
	NSMutableDictionary *itemInfo = [NSMutableDictionary dictionaryWithDictionary: rawInfo];

	//localize existing strings
#define LOCALIZE_PROPERTY( propname )									\
	if ( [[itemInfo objectForKey: propname] length] > 0 )				\
	{																	\
		NSString *localized = NSLocalizedString( [itemInfo objectForKey: propname], @"" ); \
		[itemInfo setObject: localized forKey: propname];				\
	}

	LOCALIZE_PROPERTY( @"label" );
	LOCALIZE_PROPERTY( @"paletteLabel" );
	LOCALIZE_PROPERTY( @"toolTip" );

#undef LOCALIZE_PROPERTY

	//We now try get the title and tooltip for the toolbar item from the menu.
	//This is done by searching for a menu item with the same action as the toolbar item.
	//Doing this, we don't need to type indentical strings in both the menu resource and the toolbar resource (.toolbar plist file).
	//And they only need to be localized in one place!

	NSString *actionString = [itemInfo objectForKey:@"action"];
	//did someone forgot the ':' at the end of the string? (actions always have the sender as a parameter)
	if ( [actionString length] > 0 && [actionString characterAtIndex: [actionString length] -1] != ':' )
	{
		actionString = [actionString stringByAppendingString: @":"];
		[itemInfo setObject: actionString forKey:@"action"];
	}

	SEL action = [actionString length] > 0 ? NSSelectorFromString( actionString ) : 0;

	if (  action != 0
		  && ( [itemInfo objectForKey:@"label"] == nil || [itemInfo objectForKey:@"toolTip"] == nil ) )
	{
		NSMenuItem * menuItem = [[NSApp mainMenu] menuItemWithAction: action];
		if ( menuItem != nil )
		{
			//set label?
			if ( [itemInfo objectForKey:@"label"] == nil && [[menuItem title] length] > 0 )
			{
				//delete periods at end of title (e.g. "Preferences...")
				NSString *title = [menuItem title];
				NSCharacterSet *trailing = [NSCharacterSet characterSetWithCharactersInString: @". …"];
				while ( [title length] > 1 && [trailing characterIsMember: [title characterAtIndex: [title length] -1]] )
					title = [title substringToIndex: [title length] -1];

				[itemInfo setObject: title forKey: @"label"];
			}
			//set tooltip?
			if ( [itemInfo objectForKey:@"toolTip"] == nil && [[menuItem toolTip] length] > 0 )
				[itemInfo setObject: [menuItem toolTip] forKey: @"toolTip"];
		}
	}

	//if no string for "paletteLabel" is set, use the one for "label"
	//(the paletteLabel is used as the toolbar item's title in the customizable sheet)
	if ( [itemInfo objectForKey:@"paletteLabel"] == nil && [itemInfo objectForKey:@"label"] != nil )
		[itemInfo setObject: [itemInfo objectForKey:@"label"] forKey: @"paletteLabel"];

    return itemInfo;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)willInsert
{
	NSDictionary *itemInfo = [self toolbarInfoForItem: itemIdentifier];
	if ( itemInfo == nil )
		return nil;

	NSToolbarItem *toolbarItem = [[[ControllerValidatedToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];

	NSString *string = [itemInfo objectForKey: @"label"];
	if ( string != nil )
		[toolbarItem setLabel: string];

	string = [itemInfo objectForKey: @"paletteLabel"];
	if ( string != nil )
		[toolbarItem setPaletteLabel: string];

	string = [itemInfo objectForKey: @"toolTip"];
	if ( string != nil )
		[toolbarItem setToolTip: string];

	[toolbarItem setImage: [self toolbar: aToolbar imageForToolbarItem: toolbarItem forState: NSControlStateValueOn]];

	string = [itemInfo objectForKey: @"action"];
	if ( string != nil )
		[toolbarItem setAction: NSSelectorFromString( string )];

	//the target is a key path relative to us; no target means first responder
	string = [itemInfo objectForKey: @"target"];
	if ( string != nil )
		[toolbarItem setTarget: [self valueForKeyPath: string]];

	return toolbarItem;
}


- (NSDocumentController*) documentController
{
    return [NSDocumentController sharedDocumentController];
}

- (NSApplication*) application
{
    return NSApp;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ( ![[self window] isKeyWindow] )
		return NO;

	[g_toolbarItemValidationAdapter setToolbarItem: theItem];

	return [self validateMenuItem: (NSMenuItem*) g_toolbarItemValidationAdapter];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return YES;
}

@end


@implementation NSMenu(FindExtensions)

- (NSMenuItem*) menuItemWithAction: (SEL) action
{
	//we enumerate backwards as for the main menu bar the more application specific actions
	//are often in the menus after "File" and "Edit", so it is more likely to find the
	//item in question in the rear menus (this may not apply to sub menus, but we do a linar search anyway)
	NSInteger i = [self numberOfItems];
	while ( i-- )
	{
		NSMenuItem *menuItem = [self itemAtIndex: i];

		if ( [menuItem action] == action )
			return menuItem;

		if ( [menuItem hasSubmenu] )
		{
			menuItem = [[menuItem submenu] menuItemWithAction: action];
			if ( menuItem != nil )
				return menuItem;
		}
	}

	//not found
	return nil;
}

@end
