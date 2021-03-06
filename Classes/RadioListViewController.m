/* RadioListViewController.m - Display a Last.fm radio list
 * 
 * Copyright 2009 Last.fm Ltd.
 *   - Primarily authored by Sam Steele <sam@last.fm>
 *
 * This file is part of MobileLastFM.
 *
 * MobileLastFM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MobileLastFM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MobileLastFM.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "RadioListViewController.h"
#import "SearchViewController.h"
#import "TagRadioViewController.h"
#import "UIViewController+NowPlayingButton.h"
#import "UITableViewCell+ProgressIndicator.h"
#import "MobileLastFMApplicationDelegate.h"
#include "version.h"
#import "NSString+URLEscaped.h"
#import "ArtworkCell.h"
#import </usr/include/objc/objc-class.h>
#import "DebugViewController.h"
#import "MobileLastFMApplicationDelegate.h"

@implementation RadioListViewController
- (id)initWithUsername:(NSString *)username {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		self.title = [username retain];
		_username = [username retain];
	}
	return self;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self showNowPlayingButton:[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate isPlaying]];
	[_playlists release];
	_playlists = [[NSMutableArray alloc] init];
	NSArray *playlists = [[LastFMService sharedInstance] playlistsForUser:_username];
	for(NSDictionary *playlist in playlists) {
		if(![[playlist objectForKey:@"streamable"] isEqualToString:@"0"])
			[_playlists addObject:playlist];
	}
	[_recent release];
	[[LastFMRadio sharedInstance] fetchRecentURLs];
	_recent = [[[LastFMRadio sharedInstance] recentURLs] retain];
	if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username])
		_commonArtists = [[[[LastFMService sharedInstance] compareArtistsOfUser:_username withUser:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"]] objectForKey:@"artists"] retain];
	if(![_commonArtists isKindOfClass:[NSArray class]]) {
		[_commonArtists release];
		_commonArtists = nil;
	}
	[self.tableView reloadData];
	[self loadContentForCells:[self.tableView visibleCells]];
}
- (void)viewDidLoad {
	self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.tableView.sectionHeaderHeight = 0;
	self.tableView.sectionFooterHeight = 0;
	self.tableView.backgroundColor = [UIColor blackColor];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 6;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int count;
	
	switch(section) {
		case 0:
			return 1;
		case 1:
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_subscriber"] intValue])
				count = 5;
			else
				count = 3;
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"showneighborradio"] isEqualToString:@"YES"])
				count++;
			return count;
		case 2:
			return [_commonArtists count]?[_commonArtists count]+1:0;			
		case 3:
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username])
				return [_recent count]?[_recent count]+1:0;
			else
				return 0;
		case 4:
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_subscriber"] intValue])
				return [_playlists count]?[_playlists count]+1:0;
			else
				return 0;
		case 5:
#ifdef DISTRIBUTION	
			return 0;
#else
			return 1;
#endif
	}
	return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if([self tableView:tableView numberOfRowsInSection:section])
		return 10;
	else
		return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return [[[UIView alloc] init] autorelease];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 0)
		return [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username]?46:67;
	else if([indexPath row] > 0 || [indexPath section] == 5)
		return 46;
	else
		return 29;
}
-(void)playRadioStation:(NSString *)url {
	if(![(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate hasNetworkConnection]) {
		[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate displayError:NSLocalizedString(@"ERROR_NONETWORK",@"No network available") withTitle:NSLocalizedString(@"ERROR_NONETWORK_TITLE",@"No network available title")];
	} else {
		[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate playRadioStation:url animated:YES];
	}
}
-(void)_rowSelected:(NSIndexPath *)newIndexPath {
	int row = [newIndexPath row];
	if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"showneighborradio"] isEqualToString:@"YES"] && [newIndexPath section] == 1 && row > 2) {
		row++;
	}
	if([newIndexPath section] > 0 && [newIndexPath section] != 5 && [newIndexPath row] == 0)
		return;
	
	switch([newIndexPath section]) {
		case 0:
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username]) {
				SearchViewController *controller = [[SearchViewController alloc] initWithNibName:@"SearchView" bundle:nil];
				[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate).rootViewController pushViewController:controller animated:YES];
				[controller release];
			}
			break;
		case 1:
			switch(row-1) {
				case 0:
					[self playRadioStation:[NSString stringWithFormat:@"lastfm://user/%@/personal", _username]];
					break;
				case 1:
					[self playRadioStation:[NSString stringWithFormat:@"lastfm://user/%@/recommended", _username]];
					break;
				case 2:
					[self playRadioStation:[NSString stringWithFormat:@"lastfm://user/%@/neighbours", _username]];
					break;
				case 3:
					[self playRadioStation:[NSString stringWithFormat:@"lastfm://user/%@/loved", _username]];
					break;
				case 4:
				{
					TagRadioViewController *tags = [[TagRadioViewController alloc] initWithUsername:_username];
					if(tags) {
						[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate).rootViewController pushViewController:tags animated:YES];
						[tags release];
					}
					break;
				}
			}
			break;
		case 2:
			[self playRadioStation:[NSString stringWithFormat:@"lastfm://artist/%@/similarartists", [[_commonArtists objectAtIndex:[newIndexPath row]-1] URLEscaped]]];
			break;
		case 3:
			[self playRadioStation:[[_recent objectAtIndex:[newIndexPath row]-1] objectForKey:@"url"]];
			break;
		case 4:
			[self playRadioStation:[NSString stringWithFormat:@"lastfm://playlist/%@/shuffle", [[_playlists objectAtIndex:[newIndexPath row]-1] objectForKey:@"id"]]];
			break;
		case 5:
		{
			DebugViewController *controller = [[DebugViewController alloc] initWithNibName:@"DebugView" bundle:nil];
			[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate).rootViewController pushViewController:controller animated:YES];
			[controller release];
		}
			break;
	}
	[self.tableView reloadData];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	[tableView deselectRowAtIndexPath:newIndexPath animated:NO];
	if([newIndexPath row] > 0) {
		[[tableView cellForRowAtIndexPath: newIndexPath] showProgress:YES];
	}
	[self performSelector:@selector(_rowSelected:) withObject:newIndexPath afterDelay:0.1];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
	UIImageView *v;
	UILabel *l;
	UIImageView *img;
	int row = [indexPath row];
	if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"showneighborradio"] isEqualToString:@"YES"] && [indexPath section] == 1 && row > 2) {
		row++;
	}

	[cell showProgress: NO];
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	switch([indexPath section]) {
		case 0:
			if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username] && [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username]) {
				v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rounded_table_cell_button.png"]];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.backgroundView = v;
				[v release];
				l = [[UILabel alloc] initWithFrame:CGRectMake(10,0,280,46)];
				l.textAlignment = UITextAlignmentLeft;
				l.font = [UIFont boldSystemFontOfSize:18];
				l.textColor = [UIColor whiteColor];
				l.shadowColor = [UIColor blackColor];
				l.shadowOffset = CGSizeMake(0,-1);
				l.backgroundColor = [UIColor clearColor];
				l.text = NSLocalizedString(@"Start a New Station", @"Start a New Station button");
				l.textAlignment = UITextAlignmentCenter;
				[cell.contentView addSubview:l];
				[l release];
			} else {
				ArtworkCell *profilecell = (ArtworkCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
				if(profilecell == nil) {
					NSDictionary *profile = [[LastFMService sharedInstance] profileForUser:_username];
					profilecell = [[[ArtworkCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ProfileCell"] autorelease];
					profilecell.selectionStyle = UITableViewCellSelectionStyleNone;
					v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"profile_panel.png"]];
					profilecell.backgroundView = v;
					[v release];
					profilecell.imageURL = [profile objectForKey:@"avatar"];
					UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(70,6,230,18)];
					l.backgroundColor = [UIColor clearColor];
					l.textColor = [UIColor whiteColor];
					if([[profile objectForKey:@"realname"] length])
						l.text = [profile objectForKey:@"realname"];
					else
						l.text = _username;
					l.font = [UIFont boldSystemFontOfSize: 16];
					[profilecell.contentView addSubview: l];
					[l release];
					
					NSMutableString *line2 = [NSMutableString string];
					if([[profile objectForKey:@"age"] length])
						[line2 appendFormat:@"%@, ", [profile objectForKey:@"age"]];
					[line2 appendFormat:@"%@", [profile objectForKey:@"country"]];
					l = [[UILabel alloc] initWithFrame:CGRectMake(70,26,230,16)];
					l.backgroundColor = [UIColor clearColor];
					l.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
					l.text = line2;
					l.font = [UIFont systemFontOfSize: 14];
					[profilecell.contentView addSubview: l];
					[l release];
					
					NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
					[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
					l = [[UILabel alloc] initWithFrame:CGRectMake(70,44,230,16)];
					l.backgroundColor = [UIColor clearColor];
					l.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
					l.text = [NSString stringWithFormat:@"%@ %@ %@",[numberFormatter stringFromNumber:[NSNumber numberWithInteger:[[profile objectForKey:@"playcount"] intValue]]], NSLocalizedString(@"plays since", @"x plays since join date"), [profile objectForKey:@"registered"]];
					l.font = [UIFont systemFontOfSize: 14];
					[profilecell.contentView addSubview: l];
					[l release];
					[numberFormatter release];
				}
				return profilecell;
			}
			break;
		case 1:
			switch(row) {
				case 0:
					v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rounded_table_cell_header.png"]];
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
					cell.backgroundView = v;
					l = [[UILabel alloc] initWithFrame:v.frame];
					l.textAlignment = UITextAlignmentCenter;
					l.font = [UIFont boldSystemFontOfSize:14];
					l.textColor = [UIColor whiteColor];
					l.shadowColor = [UIColor blackColor];
					l.shadowOffset = CGSizeMake(0,-1);
					l.backgroundColor = [UIColor clearColor];
					if([[[NSUserDefaults standardUserDefaults] objectForKey:@"lastfm_user"] isEqualToString:_username])
						l.text = NSLocalizedString(@"My Stations", @"My Stations heading");
					else
						l.text = [NSString stringWithFormat:@"%@'s Stations", _username];
					[cell.contentView addSubview:l];
					[l release];
					[v release];
					break;
				case 1:
					cell.text = NSLocalizedString(@"My Library", @"My Library station");
					break;
				case 2:
					cell.text = NSLocalizedString(@"Recommended by Last.fm", @"Recommended by Last.fm station");
					break;
				case 3:
					cell.text = NSLocalizedString(@"My Neighborhood Radio", @"Neighborhood Radio station");
					break;
				case 4:
					cell.text = NSLocalizedString(@"Loved Tracks", @"Loved Tracks station");
					break;
				case 5:
					cell.text = NSLocalizedString(@"Tag Radio", @"Tag Radio station");
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
			}
			break;
		case 2:
			if([indexPath row] == 0) {
				v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rounded_table_cell_header.png"]];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.backgroundView = v;
				l = [[UILabel alloc] initWithFrame:v.frame];
				l.textAlignment = UITextAlignmentCenter;
				l.font = [UIFont boldSystemFontOfSize:14];
				l.textColor = [UIColor whiteColor];
				l.shadowColor = [UIColor blackColor];
				l.shadowOffset = CGSizeMake(0,-1);
				l.backgroundColor = [UIColor clearColor];
				l.text = NSLocalizedString(@"Common Artists", @"Common Artists heading");
				[cell.contentView addSubview:l];
				[l release];
				[v release];
			} else {
				cell.text = [_commonArtists objectAtIndex:[indexPath row]-1];
			}
			break;			
		case 3:
			if([indexPath row] == 0) {
				v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rounded_table_cell_header.png"]];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.backgroundView = v;
				l = [[UILabel alloc] initWithFrame:v.frame];
				l.textAlignment = UITextAlignmentCenter;
				l.font = [UIFont boldSystemFontOfSize:14];
				l.textColor = [UIColor whiteColor];
				l.shadowColor = [UIColor blackColor];
				l.shadowOffset = CGSizeMake(0,-1);
				l.backgroundColor = [UIColor clearColor];
				l.text = NSLocalizedString(@"Recent Stations", @"Recent Stations heading");
				[cell.contentView addSubview:l];
				[l release];
				[v release];
			} else {
				cell.text = [[_recent objectAtIndex:[indexPath row]-1] objectForKey:@"name"];
			}
			break;
		case 4:
			if([indexPath row] == 0) {
				v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rounded_table_cell_header.png"]];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.backgroundView = v;
				l = [[UILabel alloc] initWithFrame:v.frame];
				l.textAlignment = UITextAlignmentCenter;
				l.font = [UIFont boldSystemFontOfSize:14];
				l.textColor = [UIColor whiteColor];
				l.shadowColor = [UIColor blackColor];
				l.shadowOffset = CGSizeMake(0,-1);
				l.backgroundColor = [UIColor clearColor];
				l.text = NSLocalizedString(@"My Playlists", @"My Playlists heading");
				[cell.contentView addSubview:l];
				[l release];
				[v release];
			} else {
				cell.text = [[_playlists objectAtIndex:[indexPath row]-1] objectForKey:@"title"];
			}
			break;
		case 5:
			cell.text = @"Debug";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			break;
	}
	if([indexPath row] > 0 && cell.accessoryType == UITableViewCellAccessoryNone) {
		img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"streaming.png"]];
		img.opaque = YES;
		cell.accessoryView = img;
		[img release];
	}
	return cell;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)dealloc {
	[super dealloc];
	[_loadingThread cancel];
	[_username release];
	[_playlists release];
	[_recent release];
}
@end
