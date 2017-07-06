/*
   Project: SFCompanion

   Copyright (C) 2014-2015 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2014-08-01 10:14:16 +0200 by multix

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <DataBasinKit/DBProgressProtocol.h>

#import "DBInteractiveTool.h"

@interface UserExecTracker : DBInteractiveTool
{
  IBOutlet OKChart       *usersView;
  IBOutlet NSWindow      *win;
  IBOutlet NSMatrix      *legendMatrix;
  IBOutlet NSPopUpButton *popupJobType;
  IBOutlet NSPopUpButton *popupGroupBy;
  IBOutlet NSTextField   *peakField;
  IBOutlet NSButton      *updateButton;
  IBOutlet NSProgressIndicator *updateProgress;
}

- (IBAction)update:(id)sender;
- (void)_updateProgress:(NSNumber *)n;
- (void)matrixAction:(id)sender;

@end


