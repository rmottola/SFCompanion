/*
   Project: SFCompanion

   Copyright (C) 2014-2015 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2014-02-10 12:21:23 +0100 by multix

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <DataBasinKit/DBProgressProtocol.h>

#import "DBInteractiveTool.h"

@class OKChart;
@class OKSeries;
@class DBSoap;

@interface BatchTracker : DBInteractiveTool
{
  IBOutlet OKChart     *batchView;
  IBOutlet NSWindow    *win;
  IBOutlet NSMatrix    *legendMatrix;
  IBOutlet NSButton    *updateButton;
  IBOutlet NSProgressIndicator *updateProgress;
}

- (IBAction)update:(id)sender;
- (void)matrixAction:(id)sender;

@end

