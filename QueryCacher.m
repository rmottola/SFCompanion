/*
   Project: SFCompanion

   Copyright (C) 2014-2017 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2014-07-11 14:14:35 +0000 by multix

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

#import "QueryCacher.h"

static NSString *query1 = @"Select Id From Case Where IsClosed = false";

static NSString *query2 = @"Select id From Case Where IsClosed = true";



@implementation QueryCacher

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"QueryCacher" owner:self];
      [querySelector removeAllItems];
      [querySelector addItemWithTitle:@"Example 1"];
      [querySelector addItemWithTitle:@"Example 2"];
    }
  return self;
}

- (void)show:(id)sender
{
  [win makeKeyAndOrderFront:nil];
}

- (IBAction)execute:(id)sender
{
  NSString *query;
  NSMutableArray *resArray;
  BOOL wentTimeOut;
  NSInteger iteration;
  BOOL done;
  
  switch ([querySelector indexOfSelectedItem])
    {
      case 0:
        query = query1;
        break;
      case 1:
         query = query2;
        break;
     default:
        query = nil;
        NSLog(@"Unexpected query index");
        break;
    }
  if (query)
    {
      switch ([limitSelector indexOfSelectedItem])
        {
        case 0:
          query = [query stringByAppendingString:@" LIMIT 1"];
          break;
        case 1:
          query = [query stringByAppendingString:@" LIMIT 10"];
          break;
        case 2:
          query = [query stringByAppendingString:@" LIMIT 100"];
          break;
        default:
          break;
        }
    }

  [query retain];
  [countField setStringValue:@""];
  [iterationField setStringValue:@""];
  [logger log: LogStandard :@"[QueryCacher] Query: %@\n", query];
  iteration = 1;
  done = NO;
  wentTimeOut = NO;
  while (!done)
    {
      NS_DURING
        {
          wentTimeOut = NO;
          resArray = [dbs queryFull :query queryAll:NO  progressMonitor:self];
          [resArray retain];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[QueryCacher] %@\n", [localException reason]];
              NSLog(@"Exception reason: %@", [localException reason]);
              NSLog(@"Exception userInfo: %@", [localException userInfo]);
              if ([[localException reason] isEqualToString:@"Your query request was running for too long."])
                {
                  NSLog(@"Query Timeout!");
                  wentTimeOut = YES;
                }
            }
          else
            {
              NSLog(@"Unexpected exception reason: %@", [localException reason]);
              NSLog(@"Unexpected exception userInfo: %@", [localException userInfo]);
              done = YES;
            }
          resArray = nil;
        }
      NS_ENDHANDLER
       
      if (!done && ([retryButton state] == NSOnState) && wentTimeOut)
        {
          NSLog(@"we should retry");
          if (iteration > 10)
            done = YES;
        }
      else
        done = YES;

      [iterationField setIntValue:iteration];
      iteration++;
    }
  
  if (resArray != nil)
    {
      NSLog(@"executed, return array %@", resArray);
      NSLog(@"query returns: %u", (unsigned int)[resArray count]);
      [countField setIntValue:(NSInteger)[resArray count]];
      [resArray release];
    }
  [query release];
}

/* ---- DBProgressProtocol ---- */

-(void)reset
{
  [currProgressField setStringValue:@""];
}

-(void)setMaximumValue:(unsigned long)max
{
  [logger log:LogDebug :@"[DBProgress] maximum: %lu\n", max];
}

-(void)setCurrentValue:(unsigned long)current
{
  [logger log:LogDebug :@"[DBProgress] current: %lu\n", current];
}

-(void)incrementCurrentValue:(unsigned long)amount
{
  [logger log:LogDebug :@"[DBProgress] amount: %lu\n", amount];
}

-(void)setEnd
{
  [logger log:LogDebug :@"[DBProgress]: End\n"];
}


-(void)setCurrentDescription:(NSString *)desc
{
  [currProgressField setStringValue:desc];
  [logger log:LogStandard :@"[DBProgress]:[%@]\n", desc];
}

- (BOOL)shouldStop
{
  return NO;
}

- (void)setShouldStop:(BOOL)flag
{
  
}

@end
