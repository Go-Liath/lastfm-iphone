/* ArtworkCell.h - A table cell that can fetch its image in the background
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

#import <UIKit/UIKit.h>

@interface UIViewController (DynamicContent)
- (void)loadContentForCells:(NSArray *)cells;
@end

@interface ArtworkCell : UITableViewCell {
	UIImageView *_artwork;
	UILabel *title;
	UILabel *subtitle;
	UIView *_bar;
	double _maxCacheAge;
	float barWidth;
	NSString *imageURL;
	BOOL _imageLoaded;
	BOOL shouldCacheArtwork;
}
@property (nonatomic, retain) UILabel *title;
@property (nonatomic, retain) UILabel *subtitle;
@property (nonatomic, retain) NSString *imageURL;
@property float barWidth;
@property BOOL shouldCacheArtwork;
-(void)fetchImage;
-(void)addStreamIcon;
-(void)hideArtwork:(BOOL)hidden;
@end
