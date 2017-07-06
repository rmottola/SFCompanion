/*
   Project: SFCompanion

   Copyright (C) 2012-2015 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2012-07-16 16:11:09 +0200 by multix

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

#import <OresmeKit/OresmeKit.h>
#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSObject.h>

#import "DBLogger.h"

#import "AsyncTracker.h"

@implementation AsyncTracker

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"AsyncTracker" owner:self];
      threshold = [[NSNumber alloc] initWithInt: 10000];
    }
  return self;
}

- (void) dealloc
{
  [threshold release];
  [super dealloc];
}

- (void)setThreshold:(NSNumber *)value
{
  [threshold release];
  threshold = [value copy];
}

- (void)show:(id)sender
{
  [statWindow makeKeyAndOrderFront:nil];
}

- (void)updateCompleted:(id)arg
{
  [chartView setNeedsDisplay: YES];
  [updateButton setEnabled:YES];
}

- (void)updateData:(id)arg
{
  NSDate *now;
  NSTimeInterval resolution;
  NSTimeInterval hour;
  NSTimeInterval day;
  unsigned i;
  unsigned steps;
  NSMutableArray *futArray;
  NSMutableArray *batArray;
  NSMutableArray *schArray;
  NSMutableArray *queArray;
  NSMutableArray *totArray;
  NSAutoreleasePool *arp;

  arp = [NSAutoreleasePool new];
  hour = 3600;
  day = hour*24;
  resolution = hour / 1;
  steps = day / resolution;
  NSLog(@"Steps: %u", steps);
  now = [NSDate date];

  [updateProgress setMaxValue:(double)(steps-1)];
  [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithInt:0] waitUntilDone:NO];

  futArray = [NSMutableArray arrayWithCapacity:steps];
  batArray = [NSMutableArray arrayWithCapacity:steps];
  schArray = [NSMutableArray arrayWithCapacity:steps];
  queArray = [NSMutableArray arrayWithCapacity:steps];
  totArray = [NSMutableArray arrayWithCapacity:steps];

  for (i = 0; i < steps; i++)
    {
      NSDate *lowerLimitDate;
      NSDate *upperLimitDate;
      NSString *lowerQueryDate;
      NSString *upperQueryDate;
      NSString *query;
      NSMutableArray *resArray;
      NSNumber *totalN;
      NSNumber *futureN;
      NSNumber *batchN;
      NSNumber *schedN;
      NSNumber *queueN;
      
      futureN = nil;
      batchN = nil;
      schedN = nil;
      queueN = nil;

      resArray = [[NSMutableArray alloc] initWithCapacity:1];
      upperLimitDate = [[NSDate alloc] initWithTimeInterval:-(i*resolution) sinceDate:now];
      NSLog(@"upper limit date: %@", upperLimitDate);
      lowerLimitDate = [[NSDate alloc] initWithTimeInterval:-day sinceDate:upperLimitDate];
      NSLog(@"lower limit date: %@", lowerLimitDate);
      lowerQueryDate = [lowerLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      upperQueryDate = [upperLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      [upperLimitDate release];
      [lowerLimitDate release];
      
      query = [@"select count(Id), JobType from AsyncApexJob where JobType in ('Future', 'ScheduledApex', 'Queueable') and CreatedDate >= " stringByAppendingString: lowerQueryDate];
      query = [query stringByAppendingString:@" and CreatedDate <= "];
      query = [query stringByAppendingString:upperQueryDate];
      query = [query stringByAppendingString: @ " Group By JobType"];
      NSLog(@"query: %@", query);
      NS_DURING
        {
          [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[FutureTracker update] %@\n", [localException reason]];
            }
        }
      NS_ENDHANDLER

      if ([resArray count] > 0 )
	{
          NSInteger j;          

          for (j = 0; j < [resArray count]; j++)
            {
              DBSObject *sO;
              NSNumber *count;
              NSString *name;

              sO = [resArray objectAtIndex:j];
              name = [sO valueForField:@"JobType"];
              count = [sO valueForField:@"expr0"];
              NSLog(@"%@ %@", name, count);
              if ([name isEqualToString:@"Future"])
                futureN = count;
              else if ([name isEqualToString:@"ScheduledApex"])
                queueN = count;
              else if ([name isEqualToString:@"Queueable"])
                queueN = count;
              else
                NSLog(@"Unexpected Job Type: %@", name);
            }
          NSLog(@"values: f: %@, s: %@", futureN, schedN);
	}
      else
	{
 	  NSLog(@"unexpected result size: %d", [resArray count]);
	}
      [resArray release];
      /* we add our values, be their nil or not. We put in 0 for nil  */
      if(futureN == nil)
        futureN = [NSNumber numberWithInt:0];
      if(schedN == nil)
        schedN = [NSNumber numberWithInt:0];
      if(queueN == nil)
        queueN = [NSNumber numberWithInt:0];     
      [schArray addObject:schedN];
      [futArray addObject:futureN];
      [queArray addObject:queueN];
      
      resArray = [[NSMutableArray alloc] initWithCapacity:1];

      query = [@"select sum(JobItemsProcessed) from AsyncApexJob where JobType = 'BatchApex'  and CreatedDate >= " stringByAppendingString: lowerQueryDate];
      query = [query stringByAppendingString:@" and CreatedDate <= "];
      query = [query stringByAppendingString:upperQueryDate];
      [logger log: LogDebug :@"[FutureHandler] BatchQuery: %@\n", query];

 
      NSLog(@"query: %@", query);
      NS_DURING
        {
          [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[FutureTracker update] %@\n", [localException reason]];
            }
        }
      NS_ENDHANDLER
      if ([resArray count] == 1 )
	{
          DBSObject *sO;

          sO = [resArray objectAtIndex:0];
          batchN = [sO valueForField:@"expr0"];
	  /* certain aggregate expressions may return an empty string instead of a number */
	  if ([batchN isEqualTo:@""])
	    {
		batchN = nil;
	    }
        }
      else
        {
 	  NSLog(@"unexpected result size: %d", [resArray count]);
          batchN = nil;
	}
      [resArray release];

      if (batchN == nil)
        batchN = [NSNumber numberWithInt:0];
      NSLog(@"batch n: %@", batchN);
      [batArray addObject:batchN];

      totalN = [NSNumber numberWithLong: [futureN longValue] + [batchN longValue] + [schedN longValue] + [queueN longValue]];
      
      [totArray addObject:totalN];

      [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithInt:i] waitUntilDone:NO];
    } 

  [futSeries removeAllObjects];
  [batchSeries removeAllObjects];
  [schedSeries removeAllObjects];
  [queueSeries removeAllObjects];
  [totalSeries removeAllObjects];

  for (i = steps; i >0; i--)
    {
      [batchSeries addObject:[batArray objectAtIndex:i-1]];
      [schedSeries addObject:[schArray objectAtIndex:i-1]];
      [futSeries addObject:[futArray objectAtIndex:i-1]];
      [queueSeries addObject:[queArray objectAtIndex:i-1]];
      [totalSeries addObject:[totArray objectAtIndex:i-1]];
      [logger log: LogInformative :@"[FutureHandler] batch: %@, future: %@, total %@\n", [batArray objectAtIndex:i-1], [futArray objectAtIndex:i-1], [totArray objectAtIndex:i-1]];
    }

  [self selectSeries:nil];
  [self performSelectorOnMainThread:@selector(updateCompleted:) withObject:self waitUntilDone:NO];
  [arp release];
}

- (IBAction)update:(id)sender
{
  [updateButton setEnabled:NO];
  [NSThread detachNewThreadSelector:@selector(updateData:) toTarget:self withObject:nil];
}

- (void)_updateProgress:(NSNumber *)n
{
  [updateProgress setDoubleValue:[n doubleValue]];
}

- (IBAction)selectSeries:(id)sender
{
  switch ([legendMatrix selectedRow])
    {
    case 0: /* Future */
      [futSeries setHighlighted:YES];
      [batchSeries setHighlighted:NO];
      [schedSeries setHighlighted:NO];
      [queueSeries setHighlighted:NO];
      [totalSeries setHighlighted:NO];
      [peakField setObjectValue: [futSeries maxValue]];
      break;
    case 1: /* Batch */
      [futSeries setHighlighted:NO];
      [batchSeries setHighlighted:YES];
      [schedSeries setHighlighted:NO];
      [queueSeries setHighlighted:NO];
      [totalSeries setHighlighted:NO];
      [peakField setObjectValue: [batchSeries maxValue]];
      break;
    case 2: /* Scheduled */
      [futSeries setHighlighted:NO];
      [batchSeries setHighlighted:NO];
      [schedSeries setHighlighted:YES];
      [queueSeries setHighlighted:NO];
      [totalSeries setHighlighted:NO];
      [peakField setObjectValue: [schedSeries maxValue]];
      break;
    case 3: /* Queueable */
      [futSeries setHighlighted:NO];
      [batchSeries setHighlighted:NO];
      [schedSeries setHighlighted:NO];
      [queueSeries setHighlighted:YES];
      [totalSeries setHighlighted:NO];
      [peakField setObjectValue: [queueSeries maxValue]];
      break;
    case 4: /* Total */
      [futSeries setHighlighted:NO];
      [batchSeries setHighlighted:NO];
      [schedSeries setHighlighted:NO];
      [queueSeries setHighlighted:NO];
      [totalSeries setHighlighted:YES];
      [peakField setObjectValue: [totalSeries maxValue]];    
      break;
    default:
      [futSeries setHighlighted:NO];
      [batchSeries setHighlighted:NO];
      [schedSeries setHighlighted:NO];
      [queueSeries setHighlighted:NO];
      [totalSeries setHighlighted:NO];
      [peakField setObjectValue:nil];
      break;
    }
  
  [chartView setNeedsDisplay:YES];  
  
}

- (void) awakeFromNib
{
  OKChart *tempChart;
  NSView *superView;

  [legendMatrix setTarget:self];
  [legendMatrix setAction:@selector(selectSeries:)];
  [legendMatrix selectCellAtRow:4 column:0];
  
  superView = [chartView superview];
  tempChart = [[OKLineChart alloc] initWithFrame: [chartView frame]];
  [tempChart setAutoresizingMask:[chartView autoresizingMask]];
  [chartView removeFromSuperview];
  chartView = tempChart;
  [superView addSubview: chartView];
  [chartView setYAxisGridSizing:OKGridKiloMega];

  [chartView setMarginLeft:15];
  [chartView setYAxisLabelStyle:OKAllLabels];
  [chartView setYLabelNumberFormatting: OKNumFmtKiloMega];

  futSeries = [[OKSeries alloc] init];
  [futSeries setColor:[NSColor blueColor]];
  [chartView addSeries:futSeries];
  [futSeries autorelease];

  schedSeries = [[OKSeries alloc] init];
  [schedSeries setColor:[NSColor grayColor]];
  [chartView addSeries:schedSeries];
  [schedSeries autorelease];

  batchSeries = [[OKSeries alloc] init];
  [batchSeries setColor:[NSColor purpleColor]];
  [chartView addSeries:batchSeries];
  [batchSeries autorelease];

  queueSeries = [[OKSeries alloc] init];
  [queueSeries setColor:[NSColor orangeColor]];
  [chartView addSeries:queueSeries];
  [queueSeries autorelease];


  totalSeries = [[OKSeries alloc] init];
  [totalSeries setColor:[NSColor redColor]];
  [chartView addSeries:totalSeries];
  [totalSeries autorelease];

  [updateProgress setDoubleValue:0.0];
}

@end
