//
//  NSAlert-Extensions.m
//  Disk Inventory X
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

#import "NSAlert-Extensions.h"

@implementation NSAlert(Extensions)

+ (void) showInformationalAlertWithMessage: (NSString *) message
						   informativeText: (NSString *) informativeText
								 forWindow: (NSWindow *) window
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle: NSAlertStyleInformational];
	[alert setMessageText: message];
	if ( informativeText != nil )
		[alert setInformativeText: informativeText];
	[alert addButtonWithTitle: NSLocalizedString(@"OK",@"")];
	
	if ( window != nil )
		[alert beginSheetModalForWindow: window completionHandler: nil];
	else
		[alert runModal];
}

@end
