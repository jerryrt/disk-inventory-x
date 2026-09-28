/* FileKindsTableController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "FileSizeFormatter.h"
#import "MainWindowController.h"

@interface FileKindsTableController : NSObject
{
    __weak IBOutlet NSTableView *_tableView;
    __weak IBOutlet MainWindowController *_windowController;
	__weak IBOutlet NSArrayController *_kindsPopupArrayController;
	__weak IBOutlet NSArrayController *_kindsTableArrayController;

    NSMutableDictionary *_cushionImages;
}

- (FileSystemDoc*) document;

- (IBAction) showFilesInSelectionList: (id) sender;

@end
