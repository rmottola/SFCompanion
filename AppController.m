/* 
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

#import <DataBasinKit/DBSoap.h>

#import "AppController.h"
#import "DBLogger.h"
#import "AsyncTracker.h"
#import "BatchTracker.h"
#import "UserExecTracker.h"
#import "ProcessMonitor.h"
#import "QueryCacher.h"

@implementation AppController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

  /*
   * Register your app's defaults here by adding objects to the
   * dictionary, eg
   *
   * [defaults setObject:anObject forKey:keyForThatObject];
   *
   */
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) init
{
  if ((self = [super init]))
    {
      db = [[DBSoap alloc] init];
      logger = [[DBLogger alloc] init];
      [logger setLogLevel:LogDebug];
      [db setLogger: logger];
      asyncTracker = nil;
    }
  return self;
}

- (void) dealloc
{
  [prefChoiceMatrix release];
  [db release];
  [logger release];
  [asyncTracker release];
  [super dealloc];
}

- (void) awakeFromNib
{
  NSButtonCell *cell;

  /* set up preferences scroll */
  cell = [[NSButtonCell alloc] init];
  [cell setButtonType: NSPushOnPushOffButton];
  [cell setImagePosition: NSImageOverlaps]; 
  prefChoiceMatrix = [[NSMatrix alloc] initWithFrame: NSZeroRect
                                                mode: NSRadioModeMatrix prototype: cell
                                        numberOfRows: 1 numberOfColumns: 2];
  [cell release];
  [prefChoiceMatrix setIntercellSpacing: NSZeroSize];
  [prefChoiceMatrix setCellSize: NSMakeSize(80, 40)];
  [prefChoiceMatrix setAllowsEmptySelection: YES];
  [prefChoiceMatrix setTarget: self];
  [prefChoiceMatrix setAction: @selector(selectPreferencesPane:)];
  [prefChoiceScroll setDocumentView: prefChoiceMatrix];

  cell = [prefChoiceMatrix cellAtRow: 0 column: 0];
  [cell setTitle:@"Connection"];
  [cell setTag: 0];
  
  cell = [prefChoiceMatrix cellAtRow: 0 column: 1];
  [cell setTitle:@"Future\nMonitor"];
  [cell setTag: 1];

  [prefChoiceMatrix sizeToCells];
}

- (void)windowDidLoad
/* some initialization stuff */
{

}

- (void) applicationDidFinishLaunching: (NSNotification *)aNotif
{
  [logger show:nil];
  [self doLogin:nil];
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (id)sender
{
  return NSTerminateNow;
}

- (void) applicationWillTerminate: (NSNotification *)aNotif
{
}

- (BOOL) application: (NSApplication *)application
	    openFile: (NSString *)fileName
{
  return NO;
}


- (IBAction)doLogin:(id)sender
{
  NSString *userName;
  NSString *password;
  NSString *token;
  NSURL    *url;
  NSUserDefaults *defaults;
  NSString *env;

  defaults = [NSUserDefaults standardUserDefaults];

  userName = [defaults valueForKey: @"username"];
  password = [defaults valueForKey: @"password"];
  token = [defaults valueForKey: @"token"];
  env = [defaults valueForKey: @"environment"];
 
  if (userName == nil || password == nil)
    return;

  /* if present, we append the security token to the password */
  if (token != nil)
    password = [password stringByAppendingString:token];

  url = [DBSoap loginURLProduction];
  if (env && [env isEqualToString:@"sandbox"])
    url = [DBSoap loginURLTest];
 
  NS_DURING
    [db login :url :userName :password :YES];

  NS_HANDLER
    NSLog(@"Login failed");
    if ([[localException name] hasPrefix:@"DB"])
      {
        [faultTextView setString:[localException reason]];
        [faultPanel makeKeyAndOrderFront:nil];
	return;
      }
  NS_ENDHANDLER
    NSLog(@"logged in successfully");
}

/* LOGGER */
- (IBAction)showLog:(id)sender
{
  [logger show:sender];
}

- (IBAction)showFutureCounter: (id)sender
{
  NSUserDefaults *defaults;
  NSNumber *thres;

  defaults = [NSUserDefaults standardUserDefaults];
  if (asyncTracker == nil)
    {
      asyncTracker = [[AsyncTracker alloc] init];
    }
  [asyncTracker setSoapHandler: db];

  thres = [defaults valueForKey:@"FutureThreshold"];
  if (thres)
    [asyncTracker setThreshold:thres];
  [asyncTracker show:nil];
}

- (IBAction)showBatchTracker: (id)sender
{
  if (batchTracker == nil)
    {
      batchTracker = [[BatchTracker alloc] init];
    }
  [batchTracker setSoapHandler: db];

  [batchTracker show:nil];
}

- (IBAction)showUserExecTracker: (id)sender
{
  if (userExecTracker == nil)
    {
      userExecTracker = [[UserExecTracker alloc] init];
    }
  [userExecTracker setSoapHandler: db];

  [userExecTracker show:nil];
}

- (IBAction)showProcessMonitor: (id)sender
{
  if (processMonitor == nil)
    {
      processMonitor = [[ProcessMonitor alloc] init];
    }
  [processMonitor setSoapHandler: db];
  
  [processMonitor show:nil];
}


- (IBAction)showQueryCacher: (id)sender
{
  if (queryCacher == nil)
    {
      queryCacher = [[QueryCacher alloc] init];
    }
  [queryCacher setSoapHandler: db];
  [queryCacher show:nil];
}


/* ---- Preferences ---- */
- (void) showPrefPanel: (id)sender
{
  NSUserDefaults *defaults;
  NSString *env;
  NSString *str;

  defaults = [NSUserDefaults standardUserDefaults];

  env = [defaults valueForKey: @"environment"];

  str = [defaults valueForKey: @"username"];
  if (str)
    [fieldUserName setStringValue: str];

  str = [defaults valueForKey: @"password"];
  if (str)
    [fieldPassword setStringValue: str];
  str = [defaults valueForKey: @"token"];

  if (str)
    [fieldToken setStringValue: str];
  if ([env isEqualToString:@"sandbox"])
    [popupEnvironment selectItemAtIndex:1];
  else
    [popupEnvironment selectItemAtIndex:0];

  [prefChoiceMatrix selectCellAtRow:0 column:0];
  [prefChoiceMatrix sendAction];
  
  [prefPanel makeKeyAndOrderFront:self];
}

- (void)selectPreferencesPane:(id)sender
{
  NSView *superView;
  NSInteger tag;
  NSPoint origin;

  superView = [prefPanelView superview];
  [prefPanelView retain];
  origin = [prefPanelView frame].origin;
  [prefPanelView removeFromSuperview];

  tag = [[sender selectedCell] tag];
  if (tag == 0)
    prefPanelView = connPrefView;

  [superView addSubview: prefPanelView];
  [prefPanelView setFrameOrigin: origin];
  [superView displayIfNeeded];
}

- (IBAction)prefCancel:(id)sender
{
  [prefPanel performClose:nil];
}

- (IBAction)prefOk:(id)sender
{
  NSString *userName;
  NSString *password;
  NSString *token;
  NSString *env;
  NSUserDefaults *defaults;

  userName = [fieldUserName stringValue];
  password = [fieldPassword stringValue];
  token = [fieldToken stringValue];

  defaults = [NSUserDefaults standardUserDefaults];

  if([popupEnvironment indexOfSelectedItem] == 1)
    env = @"sandbox";
  else
    env = @"production";

  if (userName)
    [defaults setObject: userName forKey: @"username"];
  else
    [defaults removeObjectForKey: @"username"];

 if (password)
    [defaults setObject: password forKey: @"password"];
  else
    [defaults removeObjectForKey: @"password"];

 if (token && [token length] > 0)
    [defaults setObject: token forKey: @"token"];
  else
    [defaults removeObjectForKey: @"token"];

  [defaults setObject: env forKey: @"environment"];

  [prefPanel performClose:nil];
}


@end
