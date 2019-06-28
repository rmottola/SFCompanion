/*
   Project: SFCompanion

   Copyright (C) 2012-2019 Riccardo Mottola

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

#import <DataBasinKit/DBSoap.h>

#import "DBInteractiveTool.h"

@implementation DBInteractiveTool

- (void)dealloc
{
  [dbs release];
  [super dealloc];
}

- (void)setSoapHandler:(DBSoap *)db
{
  // FIXME we should do this only if the new has a different session
  /* we clone the soap instance and pass the session, so that the method can run in a separate thread */
  dbs = [[DBSoap alloc] init];

  [dbs setSessionId:[db sessionId]];
  [dbs setServerURL:[db serverURL]];
  
  logger = [db logger];
}

- (void)show:(id)sender
{
  NSLog(@"Subclass me");
}

@end
