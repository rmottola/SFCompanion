/* -*- mode: objc -*-

   Project: SFCompanion

   Author: Riccardo Mottola

   Created: 2012-07-12 11:57:19 +0200 by multix
   
   Application Controller
 
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

@class DBSoap;
@class DBLogger;
@class AsyncTracker;
@class BatchTracker;
@class UserExecTracker;
@class ProcessMonitor;
@class QueryCacher;

@interface AppController : NSObject
{
  DBSoap *db;
  DBLogger *logger;

  AsyncTracker *asyncTracker;
  BatchTracker *batchTracker;
  UserExecTracker *userExecTracker;
  ProcessMonitor *processMonitor;
  QueryCacher *queryCacher;

  /* fault panel */
  IBOutlet NSPanel    *faultPanel;
  IBOutlet NSTextView *faultTextView;

  /* preferences */
  NSMatrix *prefChoiceMatrix;
  IBOutlet NSPanel       *prefPanel;
  IBOutlet NSScrollView  *prefChoiceScroll;
  IBOutlet NSView        *prefPanelView;
  IBOutlet NSView        *connPrefView;
  IBOutlet NSTextField   *fieldUserName;
  IBOutlet NSTextField   *fieldPassword;
  IBOutlet NSTextField   *fieldToken;
  IBOutlet NSPopUpButton *popupEnvironment;
}

- (void) showPrefPanel: (id)sender;

- (IBAction)prefCancel:(id)sender;
- (IBAction)prefOk:(id)sender;

- (IBAction)doLogin:(id)sender;
- (IBAction)showFutureCounter: (id)sender;
- (IBAction)showBatchTracker: (id)sender;
- (IBAction)showUserExecTracker: (id)sender;
- (IBAction)showProcessMonitor: (id)sender;
- (IBAction)showQueryCacher: (id)sender;
- (IBAction)showLog:(id)sender;

@end
