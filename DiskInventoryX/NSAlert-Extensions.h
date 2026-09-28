//
//  NSAlert-Extensions.h
//  Disk Inventory X
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 3
//  of the License, or any later version.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAlert(Extensions)

// Shows an informational alert with an "OK" button as a sheet on "window",
// or as a modal panel if there is no window.
+ (void) showInformationalAlertWithMessage: (NSString *) message
						   informativeText: (nullable NSString *) informativeText
								 forWindow: (nullable NSWindow *) window;

@end

NS_ASSUME_NONNULL_END
