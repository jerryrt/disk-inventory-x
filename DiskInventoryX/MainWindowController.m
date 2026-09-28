//
//  MainWindowController.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on Mon Sep 29 2003.
//
//  Copyright (C) 2003 Tjark Derlien.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

//

#import "MainWindowController.h"
#import "InfoPanelController.h"
#import "Timing.h"
#import "TreeMapView.h"
#import "FSItem-Utilities.h"
#import "FileSizeTransformer.h"
#import "AppsForItem.h"
#import "NSURL-Extensions.h"
#import "NSAlert-Extensions.h"

NSString *MainWindowControllerSelectionListWillShowNotification = @"MainWindowControllerSelectionListWillShow";
NSString *MainWindowControllerSelectionListDidHideNotification = @"MainWindowControllerSelectionListDidHide";

@interface MainWindowController(Private)
- (void) moveItemToTrash: (FSItem*) item;
- (void) setUpPanes;
- (void) setPane: (NSView*) pane visible: (BOOL) visible;
- (void) growWindowBy: (CGFloat) delta forPaneInSplitView: (NSSplitView*) splitView;
@end

@implementation MainWindowController

+ (void)initialize
{
    /* Make sure code only gets executed once. */
    static BOOL initialized = NO;
    if ( initialized )
		return;
    initialized = YES;
	
	//initalize support for the service menu
    NSArray *sendTypes = [NSArray arrayWithObjects: NSPasteboardTypeFileURL, nil];
    NSArray *returnTypes = [NSArray array];
	
	[NSApp registerServicesMenuSendTypes: sendTypes returnTypes: returnTypes];
}

- (id) initWithWindowNibName:(NSString *)windowNibName
{
	self = [super initWithWindowNibName: windowNibName];
	
	if ( self != nil )
	{
		//register volume transformers needed by various controls
		[NSValueTransformer setValueTransformer:[FileSizeTransformer transformer] forName: @"fileSizeTransformer"];
	}
	
	return self;
}

- (void) dealloc
{
	[_kindsSplitter release];
	[_selectionListSplitter release];
	[super dealloc];
}

+ (FileSystemDoc*) documentForView: (NSView*) view
{
    FileSystemDoc* doc = nil;

    NSWindow *window = [view window];
    
    id delegate = [window delegate];
    NSAssert( delegate != nil, @"expecting to retrieve the document from the window controller, which should be the window's delegate; but the window has no delegte" );
    NSAssert( [delegate respondsToSelector: @selector(document)], @"window's delegate has no method 'document' to retrieve document object" );

	doc = [delegate document];
	NSAssert( [doc isKindOfClass: [FileSystemDoc class]], @"document object is not of expected kind 'FileSystemDoc'" );

    return doc;
}

- (void) awakeFromNib
{
	//split window horizontally?
	if ( [[NSUserDefaults standardUserDefaults] boolForKey: SplitWindowHorizontally] )
	{
		[_splitter setVertical: NO];		
	}
	
	[_splitter setAutosaveName: @"MainWindowSplitter"];
}

- (void) windowDidLoad
{
	[super windowDidLoad];
	
	//done here and not in awakeFromNib, so that all other nib objects are
	//awake when the selection list's visibility is announced
	[self setUpPanes];
}

- (BOOL) isKindStatisticsVisible
{
	return ![_kindsView isHidden];
}

- (void) setKindStatisticsVisible: (BOOL) visible
{
	[self setPane: _kindsView visible: visible];
}

- (BOOL) isSelectionListVisible
{
	return ![_selectionListView isHidden];
}

- (void) setSelectionListVisible: (BOOL) visible
{
	[self setPane: _selectionListView visible: visible];
}

#pragma mark -----------------menu and toolbar actions-----------------------

- (IBAction)toggleFileKindsDrawer:(id)sender
{
	[self setKindStatisticsVisible: ![self isKindStatisticsVisible]];
}

- (IBAction) toggleSelectionListDrawer:(id)sender
{
	[self setSelectionListVisible: ![self isSelectionListVisible]];
}

- (IBAction) openFile:(id)sender
{
	NSAssert( [sender isKindOfClass: [NSMenuItem class]], @"precondition failed" );
	NSMenuItem *menuItem = (NSMenuItem*) sender;
	
	FSItem *selectedItem = [(FileSystemDoc*)[self document] selectedItem];
	NSURL *appURL = [menuItem representedObject];
	
	if ( appURL == nil )
		appURL = [[AppsForItem appsForItemURL: [selectedItem fileURL]] defaultAppURL];
	
	[AppsForItem openItemURL: [selectedItem fileURL] withAppURL: appURL];
}

- (IBAction) zoomIn:(id)sender
{
    FSItem *selectedItem = [(FileSystemDoc*)[self document] selectedItem];

    if ( selectedItem != nil && [selectedItem isFolder] )
    {
        [[self document] zoomIntoItem: selectedItem];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) zoomOut:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *currentZoomedItem = [doc zoomedItem];

    if ( currentZoomedItem != [doc rootItem] )
    {
        [doc zoomOutOneStep];

        [doc setSelectedItem: currentZoomedItem];

        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (IBAction) zoomOutTo:(id)sender
{
    FileSystemDoc *doc = [self document];
	FSItem *item = [sender representedObject];
	
	NSAssert( [doc rootItem] == [item root], @"precondition failed" );
	NSAssert( [[doc zoomStack] indexOfObjectIdenticalTo: item] != NSNotFound, @"precondition failed" );
	
    FSItem *currentZoomedItem = [doc zoomedItem];
		
	[doc zoomOutToItem: item];
	
	[doc setSelectedItem: currentZoomedItem];
	
	[self synchronizeWindowTitleWithDocumentName];
}

- (IBAction) showInFinder:(id)sender
{
    FSItem *selectedItem = [(FileSystemDoc*)[self document] selectedItem];

    if ( selectedItem != nil && [selectedItem exists] )
        [[NSWorkspace sharedWorkspace] selectFile: [selectedItem path] inFileViewerRootedAtPath: @""];
}

- (IBAction) refresh:(id)sender
{
	FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	
	if ( selectedItem == nil )
		return;
	
	[doc refreshItem: selectedItem];
	
	//the zoomed item might have changed
	[self synchronizeWindowTitleWithDocumentName];
}	

- (IBAction) refreshAll:(id)sender
{
	[[self document] refreshItem: nil];
	
	//the zoomed item might have changed
	[self synchronizeWindowTitleWithDocumentName];
}	

- (IBAction) moveToTrash:(id)sender
{
	FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	
	if ( selectedItem == nil || selectedItem == [doc zoomedItem] || [selectedItem isSpecialItem] )
		return;
	
	//if file/folder lies on a network volume, it will be deleted!
	//So warn the user and ask to proceed.
	//(only local items can be moved to trash)
	if ( ![[selectedItem fileURL] isLocalVolume] )
	{
		NSString *msg = [NSString stringWithFormat: NSLocalizedString(@"The item \"%@\" could not be moved to the trash.",@""),
													[selectedItem displayName]];

		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setAlertStyle: NSAlertStyleWarning];
		[alert setMessageText: msg];
		[alert setInformativeText: NSLocalizedString(@"Would you like to delete it immediately?",@"")];
		[alert addButtonWithTitle: NSLocalizedString(@"No",@"")];
		[[alert addButtonWithTitle: NSLocalizedString(@"Yes",@"")] setHasDestructiveAction: YES];
		
		[alert beginSheetModalForWindow: [self window] completionHandler: ^(NSModalResponse returnCode) {
			if ( returnCode == NSAlertSecondButtonReturn )
				[self moveItemToTrash: selectedItem];
		}];
	}
	else
	{
		[self moveItemToTrash: selectedItem];
	}
}

- (IBAction) showPackageContents:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowPackageContents: ![doc showPackageContents]];
}

- (IBAction) showFreeSpace:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowFreeSpace: ![doc showFreeSpace]];
}

- (IBAction) showOtherSpace:(id)sender
{
    FileSystemDoc *doc = [self document];
	
    [doc setShowOtherSpace: ![doc showOtherSpace]];
}

- (IBAction) selectParentItem:(id)sender
{
    FileSystemDoc *doc = [self document];
    
    FSItem *selectedItem = [doc selectedItem];

	//don't set selection to parent if selected item is zoomed item or one of it's direct childs
    if ( selectedItem != [doc zoomedItem] && [selectedItem parent] != [doc zoomedItem] )
    {
        [doc setSelectedItem: [selectedItem parent]];
    }
}

- (IBAction) changeSplitting:(id)sender
{
	[_splitter setVertical: ![_splitter isVertical]];
	
	[[[self window] contentView] setNeedsDisplay: TRUE];
}

- (IBAction) showInformationPanel:(id)sender
{
	InfoPanelController *infoController = [InfoPanelController sharedController];
	
	if ( [infoController panelIsVisible] )
		[infoController hidePanel];
	else
	{
		FSItem *item = [(FileSystemDoc*)[self document] selectedItem];
		[infoController showPanelWithFSItem: item];
	}
}

- (IBAction) showPhysicalSizes:(id) sender
{
	FileSystemDoc *doc = [self document];
	
	[doc setShowPhysicalFileSize: ![doc showPhysicalFileSize]];
	
	[self synchronizeWindowTitleWithDocumentName];
}

- (IBAction) ignoreCreatorCode:(id) sender
{
	FileSystemDoc *doc = [self document];
	
	[doc setIgnoreCreatorCode: ![doc ignoreCreatorCode]];
}

- (IBAction) performRenderBenchmark:(id)sender
{
	uint64_t startTime = getTime();
	
	unsigned count = 20;
	
	[_treeMapView benchmarkRenderingWithImageSize: NSMakeSize( 1024, 768 ) count: count];
	
	uint64_t doneTime = getTime();
	
	NSString *msg = [NSString stringWithFormat: @"rendering %u times took %.2f seconds", count, subtractTime(doneTime, startTime)];
	[NSAlert showInformationalAlertWithMessage: msg informativeText: nil forWindow: [self window]];
}

- (IBAction) performLayoutBenchmark:(id)sender
{
	uint64_t startTime = getTime();
	
	unsigned count = 100;
	
	[_treeMapView benchmarkLayoutCalculationWithImageSize: NSMakeSize( 1024, 768 ) count: count];
	
	uint64_t doneTime = getTime();
	
	NSString *msg = [NSString stringWithFormat: @"layout calculation %u times took %.2f seconds", count, subtractTime(doneTime, startTime)];
	[NSAlert showInformationalAlertWithMessage: msg informativeText: nil forWindow: [self window]];
}

#pragma mark -----------------UI elment validation-----------------------

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
    FileSystemDoc *doc = [self document];
    FSItem *selectedItem = [doc selectedItem];
	SEL menuAction = [menuItem action];

#define SET_TITLE( condition, string1, string2 ) \
	[menuItem setTitle: NSLocalizedString( (condition) ? string1 : string2, @"")]
		
#define SET_TITLE_AND_IMAGE( condition, string1, string2 )	\
	SET_TITLE( (condition), string1, string2 );				\
	if ( [menuItem isKindOfClass: [NSToolbarItemValidationAdapter class]] )\
		 [menuItem setState: (condition) ? NSControlStateValueOff : NSControlStateValueOn];
	
    if ( menuAction == @selector(openFile:) )
    {
        if ( selectedItem == nil )
			return NO;
		
		AppsForItem *apps = [AppsForItem appsForItemURL: [selectedItem fileURL]];
		return [apps defaultAppURL] != nil;
    }
    else if ( menuAction == @selector(zoomIn:) )
    {
        return selectedItem != nil && [selectedItem isFolder] && ![_treeMapView zoomingInProgress];
    }
    else if ( menuAction == @selector(zoomOut:) )
    {
        return [doc rootItem] != [doc zoomedItem] && ![_treeMapView zoomingInProgress];
    }
    else if ( menuAction == @selector(showInFinder:)
			  || menuAction == @selector(refresh:))
    {
        return selectedItem != nil;
    }
    else if ( menuAction == @selector(moveToTrash:) )
    {
		//the trash folder and items residing in it can't be moved to trash
		BOOL selectItemResidesInTrash = NO;
		if ( selectedItem != nil )
		{
            NSURL *selectedURL = [selectedItem fileURL];

            NSURL *trashURL = [[NSFileManager defaultManager] URLForDirectory:NSTrashDirectory inDomain:NSUserDomainMask appropriateForURL:selectedURL create:NO error:nil];
            
			if ( trashURL != nil )
			{
                selectItemResidesInTrash = [selectedURL isEqualToURL: trashURL] || [selectedURL residesInDirectoryURL:trashURL];
			}
		}
        return !selectItemResidesInTrash && selectedItem != nil && selectedItem != [doc zoomedItem] && ![selectedItem isSpecialItem];
    }
    else if ( menuAction == @selector(showPackageContents:) )
    {
        SET_TITLE_AND_IMAGE( [doc showPackageContents], @"Hide Package Contents", @"Show Package Contents" );
    }
    else if ( menuAction == @selector(showFreeSpace:) )
    {
        SET_TITLE_AND_IMAGE( [doc showFreeSpace], @"Hide Free Space", @"Show Free Space" );
    }
    else if ( menuAction == @selector(showOtherSpace:) )
    {
        SET_TITLE_AND_IMAGE( [doc showOtherSpace], @"Hide Other Space", @"Show Other Space" );
		if ( [[[doc zoomedItem] fileURL] isVolume] )
			return NO;
    }
    else if ( menuAction == @selector(showPhysicalSizes:) )
    {
        SET_TITLE_AND_IMAGE( [doc showPhysicalFileSize], @"Show Logical File Size", @"Show Physical File Size" );
    }
    else if ( menuAction == @selector(ignoreCreatorCode:) )
    {
        SET_TITLE_AND_IMAGE( [doc ignoreCreatorCode], @"Respect Creator Code", @"Ignore Creator Code" );
    }
    else if ( menuAction == @selector(toggleFileKindsDrawer:) )
    {
        SET_TITLE_AND_IMAGE( ![self isKindStatisticsVisible],
							 @"Show File Kind Statistics", @"Hide File Kind Statistics" );
    }
    else if ( menuAction == @selector(toggleSelectionListDrawer:) )
    {
        SET_TITLE( ![self isSelectionListVisible],
							 @"Show Selection List", @"Hide Selection List" );
    }
    else if ( menuAction == @selector(selectParentItem:) )
    {
        return selectedItem != nil && selectedItem != [doc zoomedItem];
    }   
    else if ( menuAction == @selector(showInformationPanel:) )
    {
        SET_TITLE_AND_IMAGE( [[InfoPanelController sharedController] panelIsVisible],
							 @"Hide Information", @"Show Information" );
    }   
    else if ( menuAction == @selector(changeSplitting:) )
    {
        SET_TITLE( [_splitter isVertical], @"Split Horizontally", @"Split Vertically" );
    }   
    
#undef SET_TITLE
#undef SET_TITLE_AND_IMAGE
	
    return YES;
}

#pragma mark -----------------Toolbar support---------------------

//used by ToolbarWindowController to load the toolbar configuration file (.toolbar)
- (NSString *)toolbarConfigurationName;
{
    return @"MainWindowToolbar";
}

#pragma mark -----------------window title-----------------------

- (void) synchronizeWindowTitleWithDocumentName
{
	[super synchronizeWindowTitleWithDocumentName];
	
	//show the icon of the zoomed folder (not of the document's root folder) in the title bar
	NSURL *zoomedURL = [[(FileSystemDoc*)[self document] zoomedItem] fileURL];
	if ( zoomedURL != nil )
		[[self window] setRepresentedURL: zoomedURL];
}

#pragma mark -----------------NSWindow delegates-----------------------

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	if ( [[InfoPanelController sharedController] panelIsVisible] )
	{
		FSItem *item = [(FileSystemDoc*)[self document] selectedItem];
		[[InfoPanelController sharedController] showPanelWithFSItem: item];
	}
}

- (void)windowDidResignMain:(NSNotification *)notification;
{
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ( [[aNotification object] isMainWindow]
		&& [[InfoPanelController sharedController] panelIsVisible] )
	{
		[[InfoPanelController sharedController] showPanelWithFSItem: nil];
	}
}

#pragma mark -----------------NSSplitView delegates-----------------------

//only used for the split views holding the file kinds and selection list panes

static const CGFloat PaneMinimumSize = 100;
static const CGFloat ContentMinimumSize = 200;

- (BOOL) splitView: (NSSplitView *) splitView shouldAdjustSizeOfSubview: (NSView *) view
{
	return view != _kindsView && view != _selectionListView;
}

- (CGFloat) splitView: (NSSplitView *) splitView constrainMinCoordinate: (CGFloat) proposedMinimumPosition ofSubviewAt: (NSInteger) dividerIndex
{
	//the kinds pane is the first subview, the selection list the second
	return splitView == _kindsSplitter ? PaneMinimumSize : ContentMinimumSize;
}

- (CGFloat) splitView: (NSSplitView *) splitView constrainMaxCoordinate: (CGFloat) proposedMaximumPosition ofSubviewAt: (NSInteger) dividerIndex
{
	CGFloat total = [splitView isVertical] ? NSWidth( [splitView bounds] ) : NSHeight( [splitView bounds] );
	CGFloat trailingMinimum = splitView == _kindsSplitter ? ContentMinimumSize : PaneMinimumSize;
	return total - trailingMinimum - [splitView dividerThickness];
}

#pragma mark -----------------NSMenu delegates-----------------------

//populates the "Open With" sub menu which the default and additional applications which can open the selected file
- (void) menuNeedsUpdate: (NSMenu*) menu
{	
	NSAssert( _openWithSubMenu == menu, @"precondition failed" );
	
    FSItem *selectedItem = [(FileSystemDoc*)[self document] selectedItem];
	if ( selectedItem == nil )
		return;
	
	AppsForItem *apps = [AppsForItem appsForItemURL: [selectedItem fileURL]];
	
	NSMenuItem *menuItem = nil;
	NSURL *appURL = [apps defaultAppURL];
	
	if ( appURL != nil )
	{
		//the first and second menu item is the default app and a serperator item
		if ( [_openWithSubMenu numberOfItems] == 0 )
		{
			[_openWithSubMenu addItem: [[[NSMenuItem alloc] init] autorelease]];
			[_openWithSubMenu addItem: [NSMenuItem separatorItem]];
		}

		menuItem = [_openWithSubMenu itemAtIndex: 0];
		
		[menuItem setTitle:             [appURL displayName]];
		[menuItem setToolTip:           [appURL displayPath]];
		[menuItem setRepresentedObject: appURL];
		[menuItem setTarget:            self];
		[menuItem setAction:            @selector(openFile:)];
        // set icon
        {
            NSImage *icon = [appURL icon];
            [icon setSize:NSMakeSize(16,16)];
            [menuItem setImage: icon];
        }
        
		NSArray<NSURL*> *appURLs = [apps additionalAppURLs];
		for ( unsigned i = 0; i < [appURLs count]; i++ )
		{
			unsigned menuItemIndex = i+2;
			if ( menuItemIndex >= ((unsigned) [_openWithSubMenu numberOfItems]) )
				[_openWithSubMenu addItem: [[[NSMenuItem alloc] init] autorelease]];
			
			menuItem = [_openWithSubMenu itemAtIndex: menuItemIndex];
			appURL = [appURLs objectAtIndex: i];
			
			[menuItem setTitle:             [appURL displayName]];
			[menuItem setToolTip:           [appURL displayPath]];
			[menuItem setRepresentedObject: appURL];
			[menuItem setTarget:            self];
			[menuItem setAction:            @selector(openFile:)];
            
            NSImage *icon = [appURL icon];
            [icon setSize:NSMakeSize(16,16)];
            [menuItem setImage: icon];
		}
	}
	
	//remove any supernumerary menu items (removed all items if is there is no app which can open this file)
	NSUInteger removeMenuItemsFromIndex = ([apps defaultAppURL] != nil) ? [[apps additionalAppURLs] count] +2 : 0;
	
	while ( ((unsigned) [_openWithSubMenu numberOfItems]) > removeMenuItemsFromIndex )
		[_openWithSubMenu removeItemAtIndex: [_openWithSubMenu numberOfItems] -1];
}

#pragma mark -----------------service menu support-----------------------

- (id)validRequestorForSendType: (NSString *) sendType
					 returnType: (NSString *) returnType
{
	FSItem *selectedItem = [(FileSystemDoc*)[self document] selectedItem];
	
    if ( selectedItem != nil
		 && ![selectedItem isSpecialItem]
		 && [returnType length] == 0 //we don't accept any input, so returnType must be emty
		 && [selectedItem exists]
		 && [sendType isEqualToString: NSPasteboardTypeFileURL] )
	{
		return self;
    }
	
    return [super validRequestorForSendType: sendType returnType: returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard
							 types:(NSArray *)types
{
	FSItem *item = [(FileSystemDoc*)[self document] selectedItem];
	
	if ( item != nil && ![item isSpecialItem] )
	{
		[pboard clearContents];
		return [pboard writeObjects: @[[item pasteboardWriter]]];
	}
	else
		return NO;
}

@end

@implementation MainWindowController(Private)

//Scroll views moved into a new superview or laid out while hidden keep
//their first row under the table header (which floats over the content on
//current macOS), so scroll every table below "view" to its first row.
static void ScrollTablesToTop( NSView *view )
{
	if ( [view isKindOfClass: [NSTableView class]] )
	{
		NSTableView *tableView = (NSTableView*) view;
		if ( [tableView numberOfRows] > 0 )
			[tableView scrollRowToVisible: 0];
		return;
	}
	
	for ( NSView *subview in [view subviews] )
		ScrollTablesToTop( subview );
}

static NSSplitView *NewPaneSplitView( BOOL vertical, NSRect frame )
{
	NSSplitView *splitView = [[NSSplitView alloc] initWithFrame: frame];
	[splitView setVertical: vertical];
	[splitView setDividerStyle: NSSplitViewDividerStyleThin];
	[splitView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	return splitView;
}

//The file kinds statistic and the selection list used to live in drawers.
//They are now panes of two split views wrapped around the files/treemap
//splitter: the kinds pane on the left, the selection list at the bottom.
- (void) setUpPanes
{
	NSView *contentView = [_splitter superview];
	NSRect frame = [_splitter frame];
	CGFloat kindsWidth = NSWidth( [_kindsView frame] );
	CGFloat selectionListHeight = NSHeight( [_selectionListView frame] );
	
	_selectionListSplitter = NewPaneSplitView( NO, frame );
	_kindsSplitter = NewPaneSplitView( YES, [_selectionListSplitter bounds] );
	
	[_splitter retain];
	[_splitter removeFromSuperview];
	
	for ( NSView *view in @[_kindsView, _selectionListView, _splitter] )
		[view setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
	[_kindsSplitter addSubview: _kindsView];
	[_kindsSplitter addSubview: _splitter];
	[_selectionListSplitter addSubview: _kindsSplitter];
	[_selectionListSplitter addSubview: _selectionListView];
	[_splitter release];
	
	[contentView addSubview: _selectionListSplitter];
	
	//default layout: sizes as designed in the nib, selection list hidden
	[_kindsSplitter adjustSubviews];
	[_kindsSplitter setPosition: kindsWidth ofDividerAtIndex: 0];
	[_selectionListSplitter adjustSubviews];
	[_selectionListSplitter setPosition: NSHeight( frame ) - selectionListHeight - [_selectionListSplitter dividerThickness]
					   ofDividerAtIndex: 0];
	[_selectionListView setHidden: YES];
	[_selectionListSplitter adjustSubviews];
	
	//the panes keep their size when the window is resized (see split view delegate methods)
	[_kindsSplitter setDelegate: self];
	[_selectionListSplitter setDelegate: self];
	
	//on first launch make room for the kinds pane, like the drawer did
	//(later the window frame is restored together with the pane layout)
	NSString *kindsAutosaveName = @"MainWindowKindsSplitter";
	if ( [[NSUserDefaults standardUserDefaults] objectForKey: [@"NSSplitView Subview Frames " stringByAppendingString: kindsAutosaveName]] == nil )
		[self growWindowBy: kindsWidth + [_kindsSplitter dividerThickness] forPaneInSplitView: _kindsSplitter];
	
	//restore the layout the user left (including which panes are visible)
	[_kindsSplitter setAutosaveName: kindsAutosaveName];
	[_selectionListSplitter setAutosaveName: @"MainWindowSelectionListSplitter"];
	
	if ( [self isSelectionListVisible] )
		[[NSNotificationCenter defaultCenter] postNotificationName: MainWindowControllerSelectionListWillShowNotification object: self];
	
	ScrollTablesToTop( _selectionListSplitter );
}

- (void) growWindowBy: (CGFloat) delta forPaneInSplitView: (NSSplitView*) splitView
{
	NSWindow *window = [self window];
	NSRect frame = [window frame];
	
	//the kinds pane is on the left and the selection list at the bottom,
	//so the window grows to the left or downwards
	if ( [splitView isVertical] )
	{
		frame.origin.x -= delta;
		frame.size.width += delta;
	}
	else
	{
		frame.origin.y -= delta;
		frame.size.height += delta;
	}
	
	//keep the window on screen
	NSRect screenFrame = [[window screen] visibleFrame];
	if ( !NSIsEmptyRect( screenFrame ) )
	{
		frame.size.width = MIN( NSWidth( frame ), NSWidth( screenFrame ) );
		frame.size.height = MIN( NSHeight( frame ), NSHeight( screenFrame ) );
		frame.origin.x = MAX( NSMinX( frame ), NSMinX( screenFrame ) );
		frame.origin.y = MAX( NSMinY( frame ), NSMinY( screenFrame ) );
		frame.origin.x = MIN( NSMinX( frame ), NSMaxX( screenFrame ) - NSWidth( frame ) );
		frame.origin.y = MIN( NSMinY( frame ), NSMaxY( screenFrame ) - NSHeight( frame ) );
	}
	
	[window setFrame: frame display: YES animate: [window isVisible]];
}

- (void) setPane: (NSView*) pane visible: (BOOL) visible
{
	if ( visible == ![pane isHidden] )
		return;
	
	NSSplitView *splitView = (NSSplitView*) [pane superview];
	BOOL isSelectionList = ( pane == _selectionListView );
	
	//remember the pane's size as the split view doesn't restore it
	CGFloat size = [splitView isVertical] ? NSWidth( [pane frame] ) : NSHeight( [pane frame] );
	if ( size < 50 )
		size = 200;
	
	if ( visible && isSelectionList )
		[[NSNotificationCenter defaultCenter] postNotificationName: MainWindowControllerSelectionListWillShowNotification object: self];
	
	[pane setHidden: !visible];
	[splitView adjustSubviews];
	
	if ( visible )
	{
		CGFloat total = [splitView isVertical] ? NSWidth( [splitView bounds] ) : NSHeight( [splitView bounds] );
		CGFloat position = ( [[splitView subviews] indexOfObjectIdenticalTo: pane] == 0 )
							? size
							: total - size - [splitView dividerThickness];
		[splitView setPosition: position ofDividerAtIndex: 0];
	}
	
	//Like the drawers did, the pane adds to the window instead of taking
	//space from the files view and the treemap. As the panes keep their size
	//when the split view is resized, the window's size change goes to them.
	CGFloat delta = size + [splitView dividerThickness];
	[self growWindowBy: visible ? delta : -delta forPaneInSplitView: splitView];
	
	if ( visible )
		ScrollTablesToTop( pane );
	
	if ( !visible && isSelectionList )
		[[NSNotificationCenter defaultCenter] postNotificationName: MainWindowControllerSelectionListDidHideNotification object: self];
}

- (void) moveItemToTrash: (FSItem*) item
{
	FileSystemDoc *doc = [self document];
	
	NSParameterAssert(	item != nil
						&& item != [doc zoomedItem] 
						&& ![item isSpecialItem] );
	
    NSError *error = nil;
    if ( [doc moveItemToTrash: item error:&error] )
	{
        [self synchronizeWindowTitleWithDocumentName];
	}
	else
	{
		//failed
        NSString *msg = [NSString stringWithFormat: NSLocalizedString(@"\"%@\" cannot be moved to the trash by Disk Inventory X.",@""), [item displayName] ];
        
		[NSAlert showInformationalAlertWithMessage: msg
								   informativeText: [error localizedFailureReason]
										 forWindow: [self window]];
 	}
}

@end
