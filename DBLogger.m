/*
   Project: DataBasin

   Copyright (C) 2012 Riccardo Mottola

   Author: Riccardo Mottola

   Created: 2012-04-24 10:50:19 +0000 by multix

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

#import "DBLogger.h"

@implementation DBLogger

- (id)init
{
  if ((self = [super init]))
    {
      [NSBundle loadNibNamed:@"Log" owner:self];
      logLevel = LogStandard;
    }
  return self;
}

-(void)dealloc
{
  [super dealloc];
}

-(void)setLogLevel: (DBLogLevel)l
{
  logLevel = l;
}


- (IBAction)show:(id)sender
{
  [logWin makeKeyAndOrderFront:self];
}

-(IBAction)clean:(id)sender
{
  [logView setString:@""];
}


-(void)log: (DBLogLevel)level :(NSString* )format, ...
{
  va_list ap;
  NSString *formattedString;

  if (logLevel >= level)
    {
      NSAttributedString *attrStr;
      NSMutableDictionary *textAttributes;

      va_start (ap, format);
      formattedString = [[NSString alloc] initWithFormat:format arguments: ap];
      va_end(ap);

      textAttributes = [NSMutableDictionary dictionaryWithObject:[NSFont userFixedPitchFontOfSize: 0] forKey:NSFontAttributeName];
      if (level == LogStandard)
	[textAttributes  setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
      else if (level == LogInformative)
	[textAttributes  setObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName];
      else if (level == LogDebug)
	[textAttributes  setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
      else
	{
	  NSLog(@"Unexpected log level");
	  NSLog(@"level: %d | %@", level, formattedString);
	}

      attrStr = [[NSAttributedString alloc] initWithString: formattedString
						attributes: textAttributes];
      [self performSelectorOnMainThread:@selector(_appendStringToViewAndScroll:) withObject:attrStr waitUntilDone:YES];
    
      [attrStr release];
      [formattedString release];
    }
}

- (void)_appendStringToViewAndScroll:(NSAttributedString *)str
{
  [str retain];
  
  [[logView textStorage] appendAttributedString: str];
  
  /* we scroll in the next run of the event loop */
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantPast]];
  [logView scrollRangeToVisible:NSMakeRange([[logView string] length], 0)];
  
  [str release];
}

@end
