#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Represents a single vector path with styling
@interface ITBVectorPath : NSObject

@property (nonatomic, copy) NSString *pathData;
@property (nonatomic, strong, nullable) NSColor *fillColor;
@property (nonatomic, strong, nullable) NSColor *strokeColor;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, assign) CGFloat fillAlpha;
@property (nonatomic, assign) CGFloat strokeAlpha;

- (instancetype)initWithPathData:(NSString *)pathData;

@end

/// Represents a group of paths with optional transform
@interface ITBVectorGroup : NSObject

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat pivotX;
@property (nonatomic, assign) CGFloat pivotY;
@property (nonatomic, assign) CGFloat scaleX;
@property (nonatomic, assign) CGFloat scaleY;
@property (nonatomic, assign) CGFloat translateX;
@property (nonatomic, assign) CGFloat translateY;
@property (nonatomic, strong) NSMutableArray<ITBVectorPath *> *paths;
@property (nonatomic, strong) NSMutableArray<ITBVectorGroup *> *groups;

- (instancetype)init;
- (NSAffineTransform *)affineTransform;

@end

/// Represents a complete vector document
@interface ITBVectorDocument : NSObject

@property (nonatomic, assign) CGSize viewportSize;
@property (nonatomic, assign) CGSize outputSize;
@property (nonatomic, strong) NSMutableArray<ITBVectorPath *> *paths;
@property (nonatomic, strong) NSMutableArray<ITBVectorGroup *> *groups;
@property (nonatomic, strong, nullable) NSColor *tintColor;
@property (nonatomic, assign) CGFloat alpha;

- (instancetype)init;

/// Returns all paths including those in nested groups
- (NSArray<ITBVectorPath *> *)allPaths;

@end

NS_ASSUME_NONNULL_END
