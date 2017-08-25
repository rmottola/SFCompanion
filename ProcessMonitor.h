/*
   Project: SFCompanion

   Copyright (C) 2013-2015 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2013-01-10 10:58:48 +0100 by multix

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#import <AppKit/AppKit.h>
#import <DataBasinKit/DBProgressProtocol.h>

#import "DBInteractiveTool.h"


@interface ProcessMonitor : DBInteractiveTool
{
  IBOutlet NSWindow    *window;
  IBOutlet NSTextField *fieldFuturesQueued;
  IBOutlet NSTextField *fieldFuturesProcessing;  
  IBOutlet NSTextField *fieldBatchQueued;
  IBOutlet NSTextField *fieldBatchProcessing;
  IBOutlet NSTextField *fieldBatchPreparing;
  IBOutlet NSButton    *updateButton;
}

- (IBAction)update:(id)sender;

@end


