/*
   Project: SFCompanion

   Copyright (C) 2014-2021 Riccardo Mottola

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#import <OresmeKit/OresmeKit.h>

#import <DataBasinKit/DBSoap.h>
#import <DataBasinKit/DBSObject.h>

#import "UserExecTracker.h"

@implementation UserExecTracker

- (id) init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"UserExecTracker" owner:self];
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

- (void) awakeFromNib
{
  OKChart *tempChart;
  NSView *superView;
  
  superView = [usersView superview];
  tempChart = [[OKLineChart alloc] initWithFrame: [usersView frame]];
  [tempChart setAutoresizingMask:[usersView autoresizingMask]];
  [usersView removeFromSuperview];
  usersView = tempChart;
  [superView addSubview: usersView];

  [usersView setMarginLeft:15];
  [usersView setYAxisLabelStyle:OKAllLabels];
  [usersView setYAxisGridSizing:OKGridKiloMega];
  [usersView setYLabelNumberFormatting:OKNumFmtKiloMega];

  [updateProgress setDoubleValue:0.0];
  
  [legendMatrix setAction:@selector(matrixAction:)];
  [legendMatrix setTarget:self];
  [legendMatrix setMode:NSListModeMatrix];
}

- (void)updateCompleted:(id)arg
{
  [usersView setNeedsDisplay: YES];
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
  NSMutableArray *groupsArr;
  NSArray *colorArray;
  NSMutableArray *arrayUsersCount;
  NSMutableArray *legendCellArray;
  NSNumber *absoluteMax;
  unsigned colorIndex;
  NSNumber *usersToDisplay;
  NSString *groupByString;
  NSString *groupByField;
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
  
  usersToDisplay = [NSNumber numberWithInt:20];
  
  /* first let's gather all User Names in the whole execution interval which is twice a day */
  resArray = [[NSMutableArray alloc] initWithCapacity:1];
  upperLimitDate = [[NSDate alloc] initWithTimeInterval:0 sinceDate:now];
  NSLog(@"upper limit date: %@", upperLimitDate);
  lowerLimitDate = [[NSDate alloc] initWithTimeInterval:-(2*day) sinceDate:upperLimitDate];
  NSLog(@"lower limit date: %@", lowerLimitDate);
  lowerQueryDate = [lowerLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
  upperQueryDate = [upperLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
  [upperLimitDate release];
  [lowerLimitDate release];
      

  groupByString = nil;
  groupByField = nil;
  switch ([popupGroupBy indexOfSelectedItem])
    {
    case 0:
      groupByString = @"CreatedBy.UserName";
      groupByField = @"Username";
      break;
    case 1:
      groupByString = @"CreatedBy.Profile.Name";
      groupByField = @"Name";
      break;      
    default:
      [logger log: LogStandard :@"[UserExecTracker update] Unknown Group By selectd\n"];
    }
  
  query = @"select ";
  query = [query stringByAppendingString:groupByString];
  switch ([popupJobType indexOfSelectedItem])
    {
    case 0:
      query = [[query stringByAppendingString:@" from AsyncApexJob where JobType ='Future' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
      break;
    case 1:
      query = [[query stringByAppendingString:@" from AsyncApexJob where JobType ='BatchApex' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
      break;
    case 2:
      query = [[query stringByAppendingString:@" from AsyncApexJob where JobType ='Queueable' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
      break;
    case 3:
      query = [[query stringByAppendingString:@" from AsyncApexJob where JobType ='Schedulable' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
      break;
    default:
      [logger log: LogStandard :@"[UserExecTracker update] Unknown Job Type selectd\n"];
    }
  query = [query stringByAppendingString:@" and CreatedDate <= "];
  query = [query stringByAppendingString:upperQueryDate];
  query = [query stringByAppendingString: @" group by "];
  query = [query stringByAppendingString:groupByString];
  query = [query stringByAppendingString: @" order by count(Id) desc limit "];
  query = [query stringByAppendingString:[usersToDisplay stringValue]];

  NS_DURING
    [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
  NS_HANDLER
    {
      if ([[localException name] hasPrefix:@"DB"])
        {
          [logger log: LogStandard :@"[UserExecTracker update] %@\n", [localException reason]];
        }
      return;
    }
  NS_ENDHANDLER
  
  groupsArr = [[NSMutableArray alloc] initWithCapacity:[resArray count]];
  for (i = 0; i < [resArray count]; i++)
    {
      NSString *groupedBy;
      
      groupedBy = [[resArray objectAtIndex: i] valueForField:groupByField];
      [groupsArr addObject: groupedBy];
    }
  [resArray removeAllObjects];
  NSLog(@"CreatedBy.Aliases: %@", groupsArr);

  /* now we look for each hour the count grouped by users */
  arrayUsersCount = [NSMutableArray arrayWithCapacity:steps];
  absoluteMax = [NSNumber numberWithInt:0];
  [absoluteMax retain];
  for (i = 0; i < steps; i++)
    {
      NSMutableDictionary *dictUsersCount;
      unsigned k;

      resArray = [[NSMutableArray alloc] initWithCapacity:1];
      upperLimitDate = [[NSDate alloc] initWithTimeInterval:-(i*resolution) sinceDate:now];
      lowerLimitDate = [[NSDate alloc] initWithTimeInterval:-day sinceDate:upperLimitDate];
      lowerQueryDate = [lowerLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      upperQueryDate = [upperLimitDate descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z" timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"] locale:nil];
      [upperLimitDate release];
      [lowerLimitDate release];
      
      switch ([popupJobType indexOfSelectedItem])
        {
        case 0:
          query = @"select count(Id), ";
          query = [query stringByAppendingString:groupByString];
          query = [[query stringByAppendingString:@" from AsyncApexJob where JobType='Future' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
          break;
        case 1:
          query = @"select sum(JobItemsProcessed), ";
          query = [query stringByAppendingString:groupByString];
          query = [[query stringByAppendingString: @" from AsyncApexJob where JobType='BatchApex' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
          break;
        case 2:
          query = @"select count(Id), ";
          query = [query stringByAppendingString:groupByString];
          query = [[query stringByAppendingString:@" from AsyncApexJob where JobType='Queueable' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
          break;
        case 3:
          query = @"select count(Id), ";
          query = [query stringByAppendingString:groupByString];
          query = [[query stringByAppendingString:@" from AsyncApexJob where JobType='Schedulable' and CreatedDate >= "] stringByAppendingString: lowerQueryDate];
          break;
        default:
          [logger log: LogStandard :@"[UserExecTracker update] Unknown Job Type selectd\n"];
        }

      query = [query stringByAppendingString:@" and CreatedDate <= "];
      query = [query stringByAppendingString:upperQueryDate];
      query = [query stringByAppendingString: @" and "];
      query = [query stringByAppendingString:groupByString];
      query = [query stringByAppendingString: @" in ("];
      for (k = 0; k < [groupsArr count]; k++)
        {
          query = [query stringByAppendingFormat:@"'%@'", [groupsArr objectAtIndex:k]];
          if (k < [groupsArr count]-1)
            query = [query stringByAppendingString:@","];
        }
      query = [query stringByAppendingFormat: @")"];
      query = [query stringByAppendingFormat: @ " group by "];
      query = [query stringByAppendingString:groupByString];

      NS_DURING
        {
          [dbs query :query queryAll:NO toArray:resArray progressMonitor:nil];
        }
      NS_HANDLER
        {
          if ([[localException name] hasPrefix:@"DB"])
            {
              [logger log: LogStandard :@"[UserExecTracker update] %@\n", [localException reason]];
            }
        }
      NS_ENDHANDLER

      /* we create anyway an empty object */
      dictUsersCount = [NSMutableDictionary dictionary];
      [arrayUsersCount addObject:dictUsersCount];
      /* now we populate it */
      if ([resArray count] > 0 )
        {
          NSInteger j;          

          for (j = 0; j < [resArray count]; j++)
            {
              DBSObject *sO;
              NSNumber *count;
              NSString *groupedBy;

              sO = [resArray objectAtIndex:j];
                  
              groupedBy = [sO valueForField:groupByField];
              count = [sO valueForField:@"expr0"];
	      /* certain aggregate expressions may return an empty string instead of a number */
	      if (count == nil || [count isEqualTo:@""])
		count = [NSNumber numberWithInt:0];

              [dictUsersCount setObject: count forKey:groupedBy];

              if ([count compare:absoluteMax] == NSOrderedDescending)
                {
                  [absoluteMax release];
                  absoluteMax = [count retain];
                }
            }
        }
      else
        {
          NSLog(@"unexpected result size: %d", [resArray count]);
        }
      [resArray removeAllObjects];
      [self performSelectorOnMainThread:@selector(_updateProgress:) withObject:[NSNumber numberWithInt:i] waitUntilDone:NO];
    }
  [resArray release];

  NSLog(@"users names array count: %@", arrayUsersCount);
  NSLog(@"the absolute maximum is: %@", absoluteMax);
  legendCellArray = [NSMutableArray arrayWithCapacity:[groupsArr count]];
  [usersView removeAllSeries];
  [legendMatrix removeColumn:0];

  colorIndex = 0;
  for (i = 0; i < [groupsArr count]; i++)
    {
      OKSeries *s;
      NSUInteger j;
      NSTextFieldCell *cell;
      NSColor *color;

      s = [[OKSeries alloc] init];
      [s setTitle:[groupsArr objectAtIndex:i]];

      [logger log: LogDebug :@"[UserExecTracker update] processing series %@\n", [groupsArr objectAtIndex:i]];
 
      for (j = steps; j > 0; j--)
        {
          NSNumber *n;

          n = [[arrayUsersCount objectAtIndex:j-1] objectForKey:[groupsArr objectAtIndex:i]];
          if (n == nil)
            n = [NSNumber numberWithFloat:0.0];
          [s addObject:n];
        }
      
      color = [colorArray objectAtIndex: colorIndex % [colorArray count]];
      colorIndex++;
      NSLog(@"Adding series: %@ with color %@", [s title], color);
      [s setColor: color];
      [usersView addSeries: s];
      
      cell = [[NSTextFieldCell alloc] init];
      [cell setTextColor: [s color]];
      [cell setStringValue: [s title]];
      [cell setTag:i];
      [legendCellArray addObject:cell];
      [cell release];
          
      [s release];
    }
  [legendMatrix renewRows:[legendCellArray count] columns:0]; /* This is needed on Mac to resize the matrix before inserting the new column */
  [legendMatrix addColumnWithCells:legendCellArray];
  [legendMatrix sizeToCells];
  [legendMatrix sizeToFit];
  [legendMatrix setNeedsDisplay];
  [logger log: LogDebug :@"[UserExecTracker update] series processed %u\n", (unsigned int)[usersView seriesCount]];

  [peakField setObjectValue:absoluteMax];
  [groupsArr release];
  [colorArray release];
  [absoluteMax release];

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
  for (c = 0; c < [usersView seriesCount]; c++)
    {
      if (c == selRow)
        [[usersView seriesAtIndex:c] setHighlighted:YES];
      else
        [[usersView seriesAtIndex:c] setHighlighted:NO];
    }
  [usersView setNeedsDisplay:YES];
}

@end
