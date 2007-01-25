/*
 
 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation 
 the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software 
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in 
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 Please send fixes to
	<ghulands@framedphotographics.com>
	<ben@scriptsoftware.com>
 */

#import "iMBSafariBookmarkParser.h"
#import "iMediaBrowser.h"
#import "iMBLibraryNode.h"
#import <WebKit/WebKit.h>
#import "iMedia.h"
#import "WebIconDatabase.h"

@implementation iMBSafariBookmarkParser

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[iMediaBrowser registerParser:[self class] forMediaType:@"links"];
	
	[pool release];
}

- (id)init
{
	if (self = [super initWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Safari/Bookmarks.plist", NSHomeDirectory()]])
	{
		mySafariFaviconCache = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void)dealloc
{
	[mySafariFaviconCache release];
	[super dealloc];
}

- (iMBLibraryNode *)recursivelyParseItem:(NSDictionary *)item
{
	iMBLibraryNode *parsed = [[iMBLibraryNode alloc] init];
	
	if ([[item objectForKey:@"Title"] isEqualToString:@"BookmarksBar"])
	{
		[parsed setName:LocalizedStringInThisBundle(@"Bookmarks Bar", @"Bookmarks Bar as titled in Safari")];
		[parsed setIconName:@"SafariBookmarksBar"];
	}
	else if ([[item objectForKey:@"Title"] isEqualToString:@"BookmarksMenu"])
	{
		[parsed setName:LocalizedStringInThisBundle(@"Bookmarks Menu", @"Bookmarks Menu as titled in Safari")];
		[parsed setIconName:@"SafariBookmarksMenu"];
	}
	else if ([[item objectForKey:@"Title"] isEqualToString:@"Address Book"] ||
			 [[item objectForKey:@"Title"] isEqualToString:@"Bonjour"] ||
			 [[item objectForKey:@"Title"] isEqualToString:@"History"] ||
			 [[item objectForKey:@"Title"] isEqualToString:@"All RSS Feeds"])
	{
		[parsed release];
		return nil;
	}
	else
	{
		[parsed setName:[item objectForKey:@"Title"]];
		[parsed setIconName:@"folder"];
	}
	
	NSMutableArray *links = [NSMutableArray array];
	NSEnumerator *e = [[item objectForKey:@"Children"] objectEnumerator];
	NSDictionary *cur;
	[[NSUserDefaults standardUserDefaults] setObject:@"~/Library/Safari/Icons" forKey:WebIconDatabaseDirectoryDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	while (cur = [e nextObject])
	{
		if ([[cur objectForKey:@"WebBookmarkType"] isEqualToString:@"WebBookmarkTypeList"])
		{
			iMBLibraryNode *child = [self recursivelyParseItem:cur];
			if (child)
			{
				[parsed addItem:child];
			}
		}
		else 
		{
			NSMutableDictionary *link = [NSMutableDictionary dictionary];
			[link setObject:[[cur objectForKey:@"URIDictionary"] objectForKey:@"title"]
					 forKey:@"Name"];
			[link setObject:[cur objectForKey:@"URLString"] forKey:@"URL"];
			
			NSImage *icon = [[WebIconDatabase sharedIconDatabase] iconForURL:[item objectForKey:@"URLString"]
																	withSize:NSMakeSize(16,16)
																	   cache:YES];
			
			if (icon)
			{
				[link setObject:icon forKey:@"Icon"];
			}
			id nameWithIcon = [self name:[[cur objectForKey:@"URIDictionary"] objectForKey:@"title"]
							   withImage:icon];
			[link setObject:nameWithIcon forKey:@"NameWithIcon"];
			[links addObject:link];
		}
	}
	[parsed setAttribute:links forKey:@"Links"];
	
	return parsed;
}

- (iMBLibraryNode *)parseDatabase
{
	NSString *path = [self databasePath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return nil;
	
	iMBLibraryNode *library = [[[iMBLibraryNode alloc] init] autorelease];
	NSDictionary *xml = [NSDictionary dictionaryWithContentsOfFile:path];
	
	[library setName:LocalizedStringInThisBundle(@"Safari", @"Safari")];
	[library setIconName:@"com.apple.Safari"];
	
	NSEnumerator *groupEnum = [[xml objectForKey:@"Children"] objectEnumerator];
	NSDictionary *cur;
	
	while (cur = [groupEnum nextObject])
	{
		
		iMBLibraryNode *child = [self recursivelyParseItem:cur];
		if (child)
		{
			[library addItem:child];
		}
	}
	return library;
}


@end
