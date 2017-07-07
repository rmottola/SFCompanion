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

#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSObject.h>

#import "ProcessMonitor.h"
#import "DBLogger.h"


@implementation ProcessMonitor

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"ProcessMonitor" owner:self];
    }
  return self;
}

- (void)show:(id)sender
{
  [window makeKeyAndOrderFront:nil];
}

- (void)updateCompleted:(id)arg
{
  [updateButton setEnabled:YES];
}

/*
 Apex Job Types: Future, BatchApex, BatchApexWorker
 Apex Job Statuses: Queued, Processing, Aborted, Completed, Failed
 */
- (void)updateData:(id)arg
{
  NSString *query;
  NSMutableArray *resArray;
  unsigned k;
  NSAutoreleasePool *arp;
  
  arp = [NSAutoreleasePool new];
  
  resArray = [[NSMutableArray alloc] initWithCapacity:1];
  
  [logger log: LogStandard :@"[ProcessMonitor] Querying Queued Futures\n"];
  query = @"select count() from AsyncApexJob where JobType = 'Future' and Status = 'Queued'";
  [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
  if ([resArray count] == 1)
    {
      NSNumber *n;
      id o;

      o = [resArray objectAtIndex:0];
      n = [o valueForField:@"count"];
      [logger log: LogInformative :@"[ProcessMonitor] Queued Futures: %@\n", n];
      [fieldFuturesQueued setObjectValue:n];
      [resArray removeAllObjects];
    }

  [logger log: LogStandard :@"[ProcessMonitor] Querying Futures in processing\n"];
  query = @"select count() from AsyncApexJob where JobType = 'Future' and Status = 'Processing'";
  [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
  if ([resArray count] == 1)
    {
      NSNumber *n;
      id o;

      o = [resArray objectAtIndex:0];
      n = [o valueForField:@"count"];
      [fieldFuturesProcessing setObjectValue:n];
      [resArray removeAllObjects];
    }


  [logger log: LogStandard :@"[ProcessMonitor] Querying Queued\n"];
  [fieldBatchQueued setIntValue:0];
  [fieldBatchPreparing setIntValue:0];
  [fieldBatchProcessing setIntValue:0];
  query = @"select count(Id), Status from AsyncApexJob where JobType = 'BatchApex' and Status != 'Completed' group by status";
  [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
  for (k = 0; k < [resArray count]; k++)
    {
      DBSObject *sObj;
      NSNumber *n;
      NSString *name;

      sObj = [resArray objectAtIndex: k];
      //      NSLog(@" Obj: %@, names %@", sObj, [sObj fieldNames]);
      name = [sObj valueForField:@"Status"];
      n = [sObj valueForField:@"expr0"];
      NSLog(@"name: %@, %@", name, n);
      if ([name isEqualToString:@"Queued"])
        [fieldBatchQueued setObjectValue:n];
      else if ([name isEqualToString:@"Preparing"])
        [fieldBatchPreparing setObjectValue:n];
      else if ([name isEqualToString:@"Processing"])
        [fieldBatchProcessing setObjectValue:n];
    }

  [resArray release];
  [self performSelectorOnMainThread:@selector(updateCompleted:) withObject:self waitUntilDone:NO];
  [arp release];
}

- (IBAction)update:(id)sender
{
  [updateButton setEnabled:NO];
  [NSThread detachNewThreadSelector:@selector(updateData:) toTarget:self withObject:nil];
}

@end
