/* MainWindowController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "TreeMapView.h"
#import "ToolbarWindowController.h"

// posted when the selection list pane is shown or hidden; the object is the window controller
extern NSString *MainWindowControllerSelectionListWillShowNotification;
extern NSString *MainWindowControllerSelectionListDidHideNotification;

@interface MainWindowController : ToolbarWindowController <NSSplitViewDelegate>
{
    IBOutlet NSView *_kindsView;
    IBOutlet NSView *_selectionListView;
	NSSplitView *_kindsSplitter;
	NSSplitView *_selectionListSplitter;
	IBOutlet NSSplitView *_splitter;
	IBOutlet NSOutlineView *_filesOutlineView;
	IBOutlet TreeMapView *_treeMapView;
	IBOutlet NSMenu *_openWithSubMenu;
}

+ (FileSystemDoc*) documentForView: (NSView*) view;

+ (void) poofEffectInView: (NSView*)view inRect: (NSRect) rect; //rect in view coords

- (BOOL) isKindStatisticsVisible;
- (void) setKindStatisticsVisible: (BOOL) visible;

- (BOOL) isSelectionListVisible;
- (void) setSelectionListVisible: (BOOL) visible;

- (IBAction) openFile:(id)sender;
- (IBAction) toggleFileKindsDrawer:(id)sender;
- (IBAction) toggleSelectionListDrawer:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) zoomOutTo:(id)sender;
- (IBAction) showInFinder:(id)sender;
- (IBAction) refresh:(id)sender;
- (IBAction) refreshAll:(id)sender;
- (IBAction) moveToTrash:(id)sender;
- (IBAction) showPackageContents:(id)sender;
- (IBAction) showFreeSpace:(id)sender;
- (IBAction) showOtherSpace:(id)sender;
- (IBAction) selectParentItem:(id)sender;
- (IBAction) changeSplitting:(id)sender;
- (IBAction) showInformationPanel:(id)sender;
- (IBAction) showPhysicalSizes:(id) sender;
- (IBAction) ignoreCreatorCode:(id) sender;

- (IBAction) performRenderBenchmark:(id)sender;
- (IBAction) performLayoutBenchmark:(id)sender;
@end
