#import <Cocoa/Cocoa.h>
#import "ITBSourceItem.h"

NS_ASSUME_NONNULL_BEGIN

@class ITBThumbnailGridView;

/// Delegate protocol for ITBThumbnailGridView
@protocol ITBThumbnailGridViewDelegate <NSObject>

@optional

/// Called when the user clicks the remove button on an item
/// @param view The thumbnail grid view
/// @param item The item to remove
- (void)thumbnailGridView:(ITBThumbnailGridView *)view didRequestRemoveItem:(ITBSourceItem *)item;

/// Called when the user clicks the add button or drops files
/// @param view The thumbnail grid view
- (void)thumbnailGridViewDidRequestAddFiles:(ITBThumbnailGridView *)view;

/// Called when the user selects an item
/// @param view The thumbnail grid view
/// @param item The selected item (nil if selection cleared)
- (void)thumbnailGridView:(ITBThumbnailGridView *)view didSelectItem:(nullable ITBSourceItem *)item;

@end

/// A grid view for displaying thumbnail images with remove buttons
@interface ITBThumbnailGridView : NSView

/// Delegate for grid events
@property (weak, nonatomic, nullable) id<ITBThumbnailGridViewDelegate> delegate;

/// The collection view displaying the thumbnails
@property (strong, nonatomic, readonly) NSCollectionView *collectionView;

/// The currently selected item
@property (strong, nonatomic, nullable, readonly) ITBSourceItem *selectedItem;

/// Set the items to display
/// @param items Array of source items to display
- (void)setItems:(NSArray<ITBSourceItem *> *)items;

/// Reload the grid data
- (void)reloadData;

/// Clear selection
- (void)clearSelection;

@end

NS_ASSUME_NONNULL_END
