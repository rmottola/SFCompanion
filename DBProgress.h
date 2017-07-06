/*
   Project: DataBasin

   Copyright (C) 2012-2015 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2012-10-19 09:34:49 +0000 by multix

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

#import <DataBasinKit/DBProgressProtocol.h>

@class NSProgressIndicator;
@class NSTextField;

@class DBLogger;

@interface DBProgress : NSObject <DBProgressProtocol>
{
  DBLogger       *logger;
  NSString       *currentDescription;
  unsigned long  currVal;
  unsigned long  maxVal;
  float          percent;
  NSDate         *startDate;
  BOOL           shouldStop;

  NSProgressIndicator *progInd;
  NSTextField *fieldRemainingTime;
}

+ (NSString *)timeFormat:(NSTimeInterval)timeInterval;

- (void)setLogger:(DBLogger *)l;

- (void)setProgressIndicator:(NSProgressIndicator *)indicator;
- (void)setRemainingTimeField:(NSTextField *)field;

- (BOOL)shouldStop;
- (void)setShouldStop:(BOOL)flag;

@end


