/*
   Project: SFCompanion

   Copyright (C) 2012-2014 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2012-12-13 09:56:22 +0100 by multix

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
#import <DataBasinKit/DBLoggerProtocol.h>


@class DBSoap;

@interface DBInteractiveTool : NSObject
{
  DBSoap *dbs;
  id<DBLoggerProtocol> logger;

}

/** sets the Soap handler class, which needs to remain valid througout the inspector existence */
- (void)setSoapHandler:(DBSoap *)db;

/** shows the main interface window or panel of the tool. This method needs to be subclassed */
- (void)show:(id)sender;

@end

