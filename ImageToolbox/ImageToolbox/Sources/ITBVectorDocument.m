#import "ITBVectorDocument.h"

@implementation ITBVectorPath

- (BOOL)isValidPathData:(NSString *)pathData {
    if (!pathData || pathData.length == 0) return NO;
    // Basic SVG path command validation
    NSCharacterSet *validChars = [NSCharacterSet characterSetWithCharactersInString:
        @"MmZzLlHhVvCcSsQqTtAa0123456789 \t\n\r.,+-eE"];
    NSCharacterSet *pathChars = [NSCharacterSet characterSetWithCharactersInString:pathData];
    return [validChars isSupersetOfSet:pathChars];
}

- (instancetype)initWithPathData:(NSString *)pathData {
    self = [super init];
    if (self) {
        // Validate path data before storing
        if ([self isValidPathData:pathData]) {
            _pathData = [pathData copy];
        } else {
            _pathData = @"";
        }
        _fillAlpha = 1.0;
        _strokeAlpha = 1.0;
        _strokeWidth = 0.0;
    }
    return self;
}

- (instancetype)init {
    return [self initWithPathData:@""];
}

@end

@implementation ITBVectorGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        _scaleX = 1.0;
        _scaleY = 1.0;
        _paths = [NSMutableArray array];
        _groups = [NSMutableArray array];
    }
    return self;
}

- (NSAffineTransform *)affineTransform {
    NSAffineTransform *transform = [NSAffineTransform transform];

    // Apply transforms in Android VectorDrawable order:
    // translate -> rotate around pivot -> scale
    [transform translateXBy:_translateX yBy:_translateY];
    [transform translateXBy:_pivotX yBy:_pivotY];
    [transform rotateByDegrees:_rotation];
    [transform scaleXBy:_scaleX yBy:_scaleY];
    [transform translateXBy:-_pivotX yBy:-_pivotY];

    return transform;
}

@end

@implementation ITBVectorDocument

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewportSize = CGSizeMake(24, 24);
        _outputSize = CGSizeMake(24, 24);
        _paths = [NSMutableArray array];
        _groups = [NSMutableArray array];
        _alpha = 1.0;
    }
    return self;
}

- (NSArray<ITBVectorPath *> *)allPaths {
    NSMutableArray<ITBVectorPath *> *result = [NSMutableArray arrayWithArray:self.paths];
    [self collectPathsFromGroups:self.groups into:result];
    return result;
}

- (void)collectPathsFromGroups:(NSArray<ITBVectorGroup *> *)groups into:(NSMutableArray<ITBVectorPath *> *)result {
    for (ITBVectorGroup *group in groups) {
        [result addObjectsFromArray:group.paths];
        [self collectPathsFromGroups:group.groups into:result];
    }
}

@end
