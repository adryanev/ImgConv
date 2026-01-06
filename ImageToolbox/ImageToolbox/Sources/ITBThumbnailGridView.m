#import "ITBThumbnailGridView.h"

static NSString * const kThumbnailCellIdentifier = @"ThumbnailCell";
static NSString * const kAddButtonCellIdentifier = @"AddButtonCell";
static const CGFloat kCellSize = 100.0;
static const CGFloat kThumbnailSize = 80.0;
static const CGFloat kCellSpacing = 10.0;

#pragma mark - ITBThumbnailCell

@interface ITBThumbnailCell : NSCollectionViewItem

@property (strong, nonatomic) NSImageView *thumbnailImageView;
@property (strong, nonatomic) NSTextField *filenameLabel;
@property (strong, nonatomic) NSButton *removeButton;
@property (strong, nonatomic) ITBSourceItem *sourceItem;
@property (copy, nonatomic, nullable) void (^removeHandler)(ITBSourceItem *item);

@end

@implementation ITBThumbnailCell

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kCellSize, kCellSize)];
    [self setupViews];
}

- (void)setupViews {
    // Thumbnail image view
    _thumbnailImageView = [[NSImageView alloc] initWithFrame:NSZeroRect];
    _thumbnailImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _thumbnailImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _thumbnailImageView.imageAlignment = NSImageAlignCenter;
    _thumbnailImageView.wantsLayer = YES;
    _thumbnailImageView.layer.cornerRadius = 4.0;
    _thumbnailImageView.layer.borderWidth = 1.0;
    _thumbnailImageView.layer.borderColor = [NSColor separatorColor].CGColor;
    _thumbnailImageView.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;
    [self.view addSubview:_thumbnailImageView];

    // Filename label
    _filenameLabel = [NSTextField labelWithString:@""];
    _filenameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _filenameLabel.font = [NSFont systemFontOfSize:9];
    _filenameLabel.textColor = [NSColor secondaryLabelColor];
    _filenameLabel.alignment = NSTextAlignmentCenter;
    _filenameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    _filenameLabel.maximumNumberOfLines = 1;
    [self.view addSubview:_filenameLabel];

    // Remove button (×)
    _removeButton = [NSButton buttonWithTitle:@"×" target:self action:@selector(removeClicked:)];
    _removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    _removeButton.bezelStyle = NSBezelStyleCircular;
    _removeButton.font = [NSFont systemFontOfSize:12 weight:NSFontWeightBold];
    _removeButton.wantsLayer = YES;
    _removeButton.layer.cornerRadius = 8.0;
    [self.view addSubview:_removeButton];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        // Thumbnail centered, 80x80
        [_thumbnailImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:2],
        [_thumbnailImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_thumbnailImageView.widthAnchor constraintEqualToConstant:kThumbnailSize],
        [_thumbnailImageView.heightAnchor constraintEqualToConstant:kThumbnailSize],

        // Filename below thumbnail
        [_filenameLabel.topAnchor constraintEqualToAnchor:_thumbnailImageView.bottomAnchor constant:2],
        [_filenameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:2],
        [_filenameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-2],

        // Remove button top-right corner of thumbnail
        [_removeButton.topAnchor constraintEqualToAnchor:_thumbnailImageView.topAnchor constant:-4],
        [_removeButton.trailingAnchor constraintEqualToAnchor:_thumbnailImageView.trailingAnchor constant:4],
        [_removeButton.widthAnchor constraintEqualToConstant:16],
        [_removeButton.heightAnchor constraintEqualToConstant:16],
    ]];
}

- (void)configureWithItem:(ITBSourceItem *)item {
    self.sourceItem = item;
    self.thumbnailImageView.image = item.thumbnail ?: item.image;
    self.filenameLabel.stringValue = item.filename ?: @"";
}

- (void)removeClicked:(id)sender {
    if (self.removeHandler && self.sourceItem) {
        self.removeHandler(self.sourceItem);
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.thumbnailImageView.layer.borderColor = [NSColor selectedContentBackgroundColor].CGColor;
        self.thumbnailImageView.layer.borderWidth = 2.0;
    } else {
        self.thumbnailImageView.layer.borderColor = [NSColor separatorColor].CGColor;
        self.thumbnailImageView.layer.borderWidth = 1.0;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.thumbnailImageView.image = nil;
    self.filenameLabel.stringValue = @"";
    self.sourceItem = nil;
    self.removeHandler = nil;
}

@end

#pragma mark - ITBAddButtonCell

@interface ITBAddButtonCell : NSCollectionViewItem

@property (strong, nonatomic) NSButton *addButton;
@property (copy, nonatomic, nullable) void (^addHandler)(void);

@end

@implementation ITBAddButtonCell

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kCellSize, kCellSize)];
    [self setupViews];
}

- (void)setupViews {
    _addButton = [[NSButton alloc] initWithFrame:NSZeroRect];
    _addButton.translatesAutoresizingMaskIntoConstraints = NO;
    _addButton.title = @"+";
    _addButton.font = [NSFont systemFontOfSize:32 weight:NSFontWeightLight];
    _addButton.bezelStyle = NSBezelStyleRounded;
    _addButton.target = self;
    _addButton.action = @selector(addClicked:);
    _addButton.wantsLayer = YES;
    _addButton.layer.cornerRadius = 4.0;
    [self.view addSubview:_addButton];

    [NSLayoutConstraint activateConstraints:@[
        [_addButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:2],
        [_addButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_addButton.widthAnchor constraintEqualToConstant:kThumbnailSize],
        [_addButton.heightAnchor constraintEqualToConstant:kThumbnailSize],
    ]];
}

- (void)addClicked:(id)sender {
    if (self.addHandler) {
        self.addHandler();
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.addHandler = nil;
}

@end

#pragma mark - ITBThumbnailGridView

@interface ITBThumbnailGridView () <NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout>

@property (strong, nonatomic, readwrite) NSCollectionView *collectionView;
@property (strong, nonatomic) NSScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray<ITBSourceItem *> *items;
@property (strong, nonatomic, nullable, readwrite) ITBSourceItem *selectedItem;

@end

@implementation ITBThumbnailGridView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _items = [NSMutableArray array];
    [self setupScrollView];
    [self setupCollectionView];
}

- (void)setupScrollView {
    _scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.borderType = NSNoBorder;
    _scrollView.drawsBackground = NO;
    [self addSubview:_scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}

- (void)setupCollectionView {
    NSCollectionViewFlowLayout *layout = [[NSCollectionViewFlowLayout alloc] init];
    layout.itemSize = NSMakeSize(kCellSize, kCellSize);
    layout.minimumInteritemSpacing = kCellSpacing;
    layout.minimumLineSpacing = kCellSpacing;
    layout.sectionInset = NSEdgeInsetsMake(kCellSpacing, kCellSpacing, kCellSpacing, kCellSpacing);

    _collectionView = [[NSCollectionView alloc] initWithFrame:self.bounds];
    _collectionView.collectionViewLayout = layout;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.selectable = YES;
    _collectionView.allowsMultipleSelection = NO;
    _collectionView.backgroundColors = @[[NSColor clearColor]];

    [_collectionView registerClass:[ITBThumbnailCell class] forItemWithIdentifier:kThumbnailCellIdentifier];
    [_collectionView registerClass:[ITBAddButtonCell class] forItemWithIdentifier:kAddButtonCellIdentifier];

    _scrollView.documentView = _collectionView;
}

#pragma mark - Public Methods

- (void)setItems:(NSArray<ITBSourceItem *> *)items {
    [_items removeAllObjects];
    [_items addObjectsFromArray:items];
    [self reloadData];
}

- (void)reloadData {
    [self.collectionView reloadData];
}

- (void)clearSelection {
    self.selectedItem = nil;
    [self.collectionView deselectItemsAtIndexPaths:self.collectionView.selectionIndexPaths];
}

#pragma mark - NSCollectionViewDataSource

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // Items + 1 for the add button
    return self.items.count + 1;
}

- (NSCollectionViewItem *)collectionView:(NSCollectionView *)collectionView
     itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {

    // Last item is the add button
    if (indexPath.item == (NSInteger)self.items.count) {
        ITBAddButtonCell *cell = [collectionView makeItemWithIdentifier:kAddButtonCellIdentifier
                                                           forIndexPath:indexPath];
        __weak typeof(self) weakSelf = self;
        cell.addHandler = ^{
            [weakSelf.delegate thumbnailGridViewDidRequestAddFiles:weakSelf];
        };
        return cell;
    }

    ITBThumbnailCell *cell = [collectionView makeItemWithIdentifier:kThumbnailCellIdentifier
                                                       forIndexPath:indexPath];
    ITBSourceItem *item = self.items[indexPath.item];
    [cell configureWithItem:item];

    __weak typeof(self) weakSelf = self;
    cell.removeHandler = ^(ITBSourceItem *removedItem) {
        [weakSelf.delegate thumbnailGridView:weakSelf didRequestRemoveItem:removedItem];
    };

    return cell;
}

#pragma mark - NSCollectionViewDelegate

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    NSIndexPath *indexPath = indexPaths.anyObject;
    if (!indexPath) return;

    // Don't select the add button
    if (indexPath.item >= (NSInteger)self.items.count) {
        [collectionView deselectItemsAtIndexPaths:indexPaths];
        return;
    }

    self.selectedItem = self.items[indexPath.item];
    [self.delegate thumbnailGridView:self didSelectItem:self.selectedItem];
}

- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    if (collectionView.selectionIndexPaths.count == 0) {
        self.selectedItem = nil;
        [self.delegate thumbnailGridView:self didSelectItem:nil];
    }
}

@end
