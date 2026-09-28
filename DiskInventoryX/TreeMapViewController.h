/* TreeMapViewController */

#import <Cocoa/Cocoa.h>
#import "FileSystemDoc.h"

@interface TreeMapViewController : NSObject
{
    __weak IBOutlet id _fileNameTextField;
    __weak IBOutlet id _fileSizeTextField;
    __weak IBOutlet id _treeMapView;
    __weak IBOutlet FileSystemDoc *_document;
	
	FSItem *_otherSpaceItem;
	FSItem *_freeSpaceItem;
}

- (FileSystemDoc*) document;

- (FSItem*) rootItem;

@end
