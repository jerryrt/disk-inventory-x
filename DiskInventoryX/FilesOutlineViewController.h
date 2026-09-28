/* FilesOutlineViewController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"
#import "ImageAndTextCell.h"
#import "FileSizeFormatter.h"
#import "DIXOutlineView.h"

@interface FilesOutlineViewController : NSObject
{
    __weak IBOutlet FileSystemDoc *_document;
    __weak IBOutlet DIXOutlineView *_outlineView;
    __weak IBOutlet NSMenu *_contextMenu;
}

- (FileSystemDoc*) document;

- (FSItem*) rootItem;

@end
