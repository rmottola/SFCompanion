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

#import <OresmeKit/OresmeKit.h>

#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSObject.h>


#import "BatchTracker.h"

@implementation BatchTracker

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"BatchTracker" owner:self];
    }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void)show:(id)sender
{
  [win makeKeyAndOrderFront:nil];
}

- (void)updateCompleted:(id)arg
{
  [batchView setNeedsDisplay: YES];
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
  NSDate *lowerLimitDate;
  NSDate *upperLimitDate;
  NSString *lowerQueryDate;
  NSString *upperQueryDate;
  NSString *query;
  NSMutableArray *resArray;
  NSMutableArray *apexClassNames;
  NSArray *colorArray;
  NSMutableArray *arrayBatchNamesCount;
  NSMutableArray *legendCellArray;
  NSAutoreleasePool *arp;

  arp = [NSAutoreleasePool new];

  colorArray = [[NSArray alloc] initWithObjects:
                                  [NSColor redColor],
                                [NSColor blueColor],
                                [NSColor greenColor],
                                [NSColor yellowColor],
                                [NSColor purpleColor],
                                [NSColor orangeColor],
                                [NSColor brownColor],
                                [NSColor cyanColor],
                                [NSColor colorWithCalibratedRed:0.2 green:0.0 blue:0.8 alpha:1.0],
                                [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.8 alpha:1.0],
                                nil];
  hour = 3600;
  day = hour*24;
  resolution = hour / 1;
  steps = day / resolution;
  now = [NSDate date];

  [updateProgress setMaxValue:(double)(steps-1)];
  [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithInt:0] waitUntilDone:NO];
  
  /* first let's gather all ApexClass.Name in the whole execution interval which is twice a day */
  resArray = [[NSMutableArray alloc] initWithCapacity:1];
  upperLimitDate = [[NSDate alloc] initWithTimeInterval:0 sinceDate:now];
  NSLog(@"upper limit date: %@", upperLimitDate);
  lowerLimitDate = [[NSDate alloc] initWithTimeInterval:-(2*day) sinceDate:upperLimitDate];
  NSLog(@"lower limit date: %@", lowerLimitDate);
  lowerQueryDate = [lowerLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
  upperQueryDate = [upperLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
  [upperLimitDate release];
  [lowerLimitDate release];
      
  query = [@"select ApexClass.Name from AsyncApexJob where JobType = 'BatchApex' and CreatedDate >= " stringByAppendingString: lowerQueryDate];
  query = [query stringByAppendingString:@" and CreatedDate <= "];
  query = [query stringByAppendingString:upperQueryDate];
  query = [query stringByAppendingString: @ " group by ApexClass.Name"];
  NSLog(@"query: %@", query);
  [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
  
  apexClassNames = [[NSMutableArray alloc] initWithCapacity:[resArray count]];
  for (i = 0; i < [resArray count]; i++)
    {
      NSString *name;
      
      name = [[resArray objectAtIndex: i] valueForField:@"Name"];
      [apexClassNames addObject: name];
    }
  [resArray removeAllObjects];
  NSLog(@"ApexClass.Names: %@", apexClassNames);
  

  arrayBatchNamesCount = [NSMutableArray arrayWithCapacity:steps];
  for (i = 0; i < steps; i++)
    {
      NSMutableDictionary *dictBatchNamesCount;

      resArray = [[NSMutableArray alloc] initWithCapacity:1];
      upperLimitDate = [[NSDate alloc] initWithTimeInterval:-(i*resolution) sinceDate:now];
      NSLog(@"upper limit date: %@", upperLimitDate);
      lowerLimitDate = [[NSDate alloc] initWithTimeInterval:-day sinceDate:upperLimitDate];
      NSLog(@"lower limit date: %@", lowerLimitDate);
      lowerQueryDate = [lowerLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      upperQueryDate = [upperLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      [upperLimitDate release];
      [lowerLimitDate release];
      
      query = [@"select sum(JobItemsProcessed), ApexClass.Name from AsyncApexJob where JobType = 'BatchApex' and CreatedDate >= " stringByAppendingString: lowerQueryDate];
      query = [query stringByAppendingString:@" and CreatedDate <= "];
      query = [query stringByAppendingString:upperQueryDate];
      query = [query stringByAppendingString: @ " group by ApexClass.Name"];
      NSLog(@"query: %@", query);
      NS_DURING
        {
          [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[BachTracker update] %@\n", [localException reason]];
            }
        }
      NS_ENDHANDLER

      /* we create anyway an empty object */
      dictBatchNamesCount = [NSMutableDictionary dictionary];
      [arrayBatchNamesCount addObject:dictBatchNamesCount];
      /* now we populate it */
      if ([resArray count] > 0 )
        {
          NSInteger j;          

          for (j = 0; j < [resArray count]; j++)
            {
              DBSObject *sO;
              NSNumber *count;
              NSString *name;

              sO = [resArray objectAtIndex:j];
                  
              name = [sO valueForField:@"Name"];
              count = [sO valueForField:@"expr0"];
	      /* certain aggregate expressions may return an empty string instead of a number */
	      if (count == nil || [count isEqualTo:@""])
		count = [NSNumber numberWithInt:0];
              NSLog(@"Name %@, count %@", name, count);
              [dictBatchNamesCount setObject: count forKey:name];
            }
        }
      else
        {
          NSLog(@"unexpected result size: %d", [resArray count]);
        }
      [resArray removeAllObjects];
      
#if 0
      
      /* now let's gather execution times */
      query = [@"select CompletedDate. CreatedDate, JobItemProcessed, ApexClass.Name from AsyncApexJob where JobType = 'BatchApex' and CreatedDate >= " stringByAppendingString: lowerQueryDate];
      query = [query stringByAppendingString:@" and CreatedDate <= "];
      query = [query stringByAppendingString:upperQueryDate];
      query = [query stringByAppendingString: @ " "];
      NSLog(@"query: %@", query);
      [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
#endif

      [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithInt:i] waitUntilDone:NO];

    }
  [resArray release];

  NSLog(@"batch names array count: %@", arrayBatchNamesCount);
  legendCellArray = [NSMutableArray arrayWithCapacity:[apexClassNames count]];
  [batchView removeAllSeries];
  [legendMatrix removeColumn:0];

  NSLog(@"all series removed");
  for (i = 0; i < [apexClassNames count]; i++)
    {
      OKSeries *s;
      NSUInteger j;
      NSTextFieldCell *cell;

      s = [[OKSeries alloc] init];
      [s setTitle:[apexClassNames objectAtIndex:i]];
      [s setColor: [colorArray objectAtIndex: i % [colorArray count]]];
      [batchView addSeries: s];
      cell = [[NSTextFieldCell alloc] init];
      [cell setTextColor: [s color]];
      [cell setStringValue: [s title]];
      [cell setTag:i];
      [legendCellArray addObject:cell];
      [cell release];
      NSLog(@"processing series: %@", [apexClassNames objectAtIndex:i]);
      for (j = steps; j > 0; j--)
        {
          NSNumber *n;

          n = [[arrayBatchNamesCount objectAtIndex:j-1] objectForKey:[apexClassNames objectAtIndex:i]];
          NSLog(@"value: %@, %@", [apexClassNames objectAtIndex:i], n);
          if (n == nil)
            n = [NSNumber numberWithFloat:0.0];
          [s addObject:n];
        }
      NSLog(@"series: %@", s);
      [s release];
    }
  [legendMatrix renewRows:[legendCellArray count] columns:0]; /* This is needed on Mac to resize the matrix before inserting the new column */
  [legendMatrix addColumnWithCells:legendCellArray]; 
  [legendMatrix sizeToCells];
  [legendMatrix sizeToFit];
  [legendMatrix setNeedsDisplay];

  NSLog(@"series processed, %u", [batchView seriesCount]);

  [apexClassNames release];
  [colorArray release];

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

- (void)matrixAction:(id)sender
{
  NSInteger selRow;
  NSInteger c;

  selRow = [legendMatrix selectedRow];
  for (c = 0; c < [batchView seriesCount]; c++)
    {
      if (c == selRow)
        [[batchView seriesAtIndex:c] setHighlighted:YES];
      else
        [[batchView seriesAtIndex:c] setHighlighted:NO];
    }
  [batchView setNeedsDisplay:YES];
}

- (void) awakeFromNib
{
  OKChart *tempChart;
  NSView *superView;
  
  superView = [batchView superview];
  tempChart = [[OKLineChart alloc] initWithFrame: [batchView frame]];
  [tempChart setAutoresizingMask:[batchView autoresizingMask]];
  [batchView removeFromSuperview];
  batchView = tempChart;
  [superView addSubview: batchView];

  [batchView setMarginLeft:15];
  [batchView setYAxisLabelStyle:OKAllLabels];
  [batchView setYAxisGridSizing:OKGridKiloMega];

  [updateProgress setDoubleValue:0.0];
  
  [legendMatrix setAction:@selector(matrixAction:)];
  [legendMatrix setTarget:self];
  [legendMatrix setMode:NSListModeMatrix];
}


@end
