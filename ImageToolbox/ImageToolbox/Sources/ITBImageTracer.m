#import "ITBImageTracer.h"
#import <Accelerate/Accelerate.h>

NSErrorDomain const ITBImageTracerErrorDomain = @"ITBImageTracerErrorDomain";

typedef struct {
    uint8_t r, g, b, a;
} ITBPixel;

typedef struct {
    CGFloat x, y;
} ITBPoint;

@interface ITBColorBucket : NSObject
@property (nonatomic, strong) NSMutableArray<NSValue *> *pixels;
@property (nonatomic, assign) NSInteger rMin, rMax, gMin, gMax, bMin, bMax;
- (NSColor *)averageColor;
- (NSInteger)largestRange;
@end

@implementation ITBColorBucket

- (instancetype)init {
    self = [super init];
    if (self) {
        _pixels = [NSMutableArray array];
        _rMin = _gMin = _bMin = 255;
        _rMax = _gMax = _bMax = 0;
    }
    return self;
}

- (void)addPixelR:(uint8_t)r g:(uint8_t)g b:(uint8_t)b {
    [_pixels addObject:[NSValue valueWithBytes:&(ITBPixel){r, g, b, 255} objCType:@encode(ITBPixel)]];
    _rMin = MIN(_rMin, r); _rMax = MAX(_rMax, r);
    _gMin = MIN(_gMin, g); _gMax = MAX(_gMax, g);
    _bMin = MIN(_bMin, b); _bMax = MAX(_bMax, b);
}

- (NSColor *)averageColor {
    if (_pixels.count == 0) return [NSColor blackColor];

    NSInteger rSum = 0, gSum = 0, bSum = 0;
    for (NSValue *val in _pixels) {
        ITBPixel p;
        [val getValue:&p];
        rSum += p.r;
        gSum += p.g;
        bSum += p.b;
    }

    CGFloat count = _pixels.count;
    return [NSColor colorWithRed:rSum/count/255.0
                           green:gSum/count/255.0
                            blue:bSum/count/255.0
                           alpha:1.0];
}

- (NSInteger)largestRange {
    NSInteger rRange = _rMax - _rMin;
    NSInteger gRange = _gMax - _gMin;
    NSInteger bRange = _bMax - _bMin;
    return MAX(rRange, MAX(gRange, bRange));
}

- (NSInteger)dominantChannel {
    NSInteger rRange = _rMax - _rMin;
    NSInteger gRange = _gMax - _gMin;
    NSInteger bRange = _bMax - _bMin;

    if (rRange >= gRange && rRange >= bRange) return 0;
    if (gRange >= rRange && gRange >= bRange) return 1;
    return 2;
}

@end

@implementation ITBImageTracer

- (instancetype)init {
    self = [super init];
    if (self) {
        _colorCount = 8;
        _tolerance = 1.0;
        _minArea = 4.0;
    }
    return self;
}

#pragma mark - Public Methods

- (nullable ITBVectorDocument *)traceImage:(NSImage *)image error:(NSError **)error {
    return [self traceImage:image outputSize:image.size error:error];
}

- (nullable ITBVectorDocument *)traceImage:(NSImage *)image
                                outputSize:(CGSize)outputSize
                                     error:(NSError **)error {
    if (!image) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageTracerErrorDomain
                                         code:ITBImageTracerErrorInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: @"Image is nil"}];
        }
        return nil;
    }

    // Get bitmap data
    NSBitmapImageRep *bitmap = [self bitmapFromImage:image];
    if (!bitmap) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageTracerErrorDomain
                                         code:ITBImageTracerErrorInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create bitmap"}];
        }
        return nil;
    }

    NSInteger width = bitmap.pixelsWide;
    NSInteger height = bitmap.pixelsHigh;

    // Step 1: Quantize colors
    NSArray<NSColor *> *palette = [self quantizeColorsFromBitmap:bitmap count:self.colorCount];
    if (palette.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageTracerErrorDomain
                                         code:ITBImageTracerErrorQuantizationFailed
                                     userInfo:@{NSLocalizedDescriptionKey: @"Color quantization failed"}];
        }
        return nil;
    }

    // Create document
    ITBVectorDocument *document = [[ITBVectorDocument alloc] init];
    document.viewportSize = CGSizeMake(width, height);
    document.outputSize = outputSize;

    // Step 2-4: For each color, create mask, trace, and simplify
    for (NSColor *color in palette) {
        // Create binary mask for this color
        uint8_t *mask = [self createMaskFromBitmap:bitmap forColor:color palette:palette];
        if (!mask) continue;

        // Trace contours
        NSArray<NSArray<NSValue *> *> *contours = [self traceContoursInMask:mask width:width height:height];

        free(mask);

        // Convert contours to paths
        for (NSArray<NSValue *> *contour in contours) {
            if (contour.count < 3) continue;

            // Calculate area
            CGFloat area = [self areaOfContour:contour];
            if (fabs(area) < self.minArea) continue;

            // Simplify path
            NSArray<NSValue *> *simplified = [self simplifyContour:contour tolerance:self.tolerance];
            if (simplified.count < 3) continue;

            // Create path
            NSString *pathData = [self pathDataFromContour:simplified];
            ITBVectorPath *path = [[ITBVectorPath alloc] initWithPathData:pathData];
            path.fillColor = color;

            [document.paths addObject:path];
        }
    }

    // Sort paths by area (largest first for proper layering)
    [document.paths sortUsingComparator:^NSComparisonResult(ITBVectorPath *p1, ITBVectorPath *p2) {
        CGFloat a1 = [self estimatePathArea:p1.pathData];
        CGFloat a2 = [self estimatePathArea:p2.pathData];
        return a2 > a1 ? NSOrderedDescending : (a2 < a1 ? NSOrderedAscending : NSOrderedSame);
    }];

    return document;
}

- (nullable NSArray<NSColor *> *)quantizeColors:(NSImage *)image
                                     colorCount:(NSInteger)count
                                          error:(NSError **)error {
    NSBitmapImageRep *bitmap = [self bitmapFromImage:image];
    if (!bitmap) {
        if (error) {
            *error = [NSError errorWithDomain:ITBImageTracerErrorDomain
                                         code:ITBImageTracerErrorInvalidImage
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create bitmap"}];
        }
        return nil;
    }

    return [self quantizeColorsFromBitmap:bitmap count:count];
}

#pragma mark - Bitmap Handling

- (nullable NSBitmapImageRep *)bitmapFromImage:(NSImage *)image {
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (!cgImage) return nil;

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    return bitmap;
}

#pragma mark - Color Quantization (Median Cut)

- (NSArray<NSColor *> *)quantizeColorsFromBitmap:(NSBitmapImageRep *)bitmap count:(NSInteger)count {
    NSInteger width = bitmap.pixelsWide;
    NSInteger height = bitmap.pixelsHigh;
    unsigned char *data = bitmap.bitmapData;
    NSInteger bytesPerRow = bitmap.bytesPerRow;
    NSInteger samplesPerPixel = bitmap.samplesPerPixel;

    // Create initial bucket with all pixels
    ITBColorBucket *initialBucket = [[ITBColorBucket alloc] init];

    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger offset = y * bytesPerRow + x * samplesPerPixel;
            uint8_t r = data[offset];
            uint8_t g = data[offset + 1];
            uint8_t b = data[offset + 2];
            uint8_t a = samplesPerPixel > 3 ? data[offset + 3] : 255;

            // Skip transparent pixels
            if (a < 128) continue;

            [initialBucket addPixelR:r g:g b:b];
        }
    }

    if (initialBucket.pixels.count == 0) {
        return @[[NSColor clearColor]];
    }

    // Median cut algorithm
    NSMutableArray<ITBColorBucket *> *buckets = [NSMutableArray arrayWithObject:initialBucket];

    while (buckets.count < count) {
        // Find bucket with largest range
        ITBColorBucket *largest = nil;
        NSInteger largestRange = 0;

        for (ITBColorBucket *bucket in buckets) {
            if (bucket.pixels.count > 1) {
                NSInteger range = [bucket largestRange];
                if (range > largestRange) {
                    largestRange = range;
                    largest = bucket;
                }
            }
        }

        if (!largest || largest.pixels.count < 2) break;

        // Split bucket along dominant channel
        NSInteger channel = [largest dominantChannel];
        NSArray *sorted = [largest.pixels sortedArrayUsingComparator:^NSComparisonResult(NSValue *v1, NSValue *v2) {
            ITBPixel p1, p2;
            [v1 getValue:&p1];
            [v2 getValue:&p2];

            NSInteger val1 = (channel == 0) ? p1.r : (channel == 1) ? p1.g : p1.b;
            NSInteger val2 = (channel == 0) ? p2.r : (channel == 1) ? p2.g : p2.b;

            return val1 > val2 ? NSOrderedDescending : (val1 < val2 ? NSOrderedAscending : NSOrderedSame);
        }];

        NSInteger median = sorted.count / 2;

        ITBColorBucket *bucket1 = [[ITBColorBucket alloc] init];
        ITBColorBucket *bucket2 = [[ITBColorBucket alloc] init];

        for (NSInteger i = 0; i < sorted.count; i++) {
            ITBPixel p;
            [sorted[i] getValue:&p];

            if (i < median) {
                [bucket1 addPixelR:p.r g:p.g b:p.b];
            } else {
                [bucket2 addPixelR:p.r g:p.g b:p.b];
            }
        }

        [buckets removeObject:largest];
        if (bucket1.pixels.count > 0) [buckets addObject:bucket1];
        if (bucket2.pixels.count > 0) [buckets addObject:bucket2];
    }

    // Get average color from each bucket
    NSMutableArray<NSColor *> *palette = [NSMutableArray array];
    for (ITBColorBucket *bucket in buckets) {
        [palette addObject:[bucket averageColor]];
    }

    return palette;
}

#pragma mark - Mask Creation

- (uint8_t *)createMaskFromBitmap:(NSBitmapImageRep *)bitmap
                         forColor:(NSColor *)targetColor
                          palette:(NSArray<NSColor *> *)palette {
    NSInteger width = bitmap.pixelsWide;
    NSInteger height = bitmap.pixelsHigh;
    unsigned char *data = bitmap.bitmapData;
    NSInteger bytesPerRow = bitmap.bytesPerRow;
    NSInteger samplesPerPixel = bitmap.samplesPerPixel;

    uint8_t *mask = calloc(width * height, sizeof(uint8_t));
    if (!mask) return NULL;

    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            NSInteger offset = y * bytesPerRow + x * samplesPerPixel;
            CGFloat r = data[offset] / 255.0;
            CGFloat g = data[offset + 1] / 255.0;
            CGFloat b = data[offset + 2] / 255.0;
            uint8_t a = samplesPerPixel > 3 ? data[offset + 3] : 255;

            if (a < 128) continue;

            // Find closest palette color
            NSColor *closest = [self closestColorTo:r g:g b:b inPalette:palette];

            // Check if it matches target
            if ([self colorDistance:closest to:targetColor] < 0.001) {
                mask[y * width + x] = 1;
            }
        }
    }

    return mask;
}

- (NSColor *)closestColorTo:(CGFloat)r g:(CGFloat)g b:(CGFloat)b inPalette:(NSArray<NSColor *> *)palette {
    NSColor *closest = palette.firstObject;
    CGFloat minDist = CGFLOAT_MAX;

    for (NSColor *color in palette) {
        NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        CGFloat dr = r - rgb.redComponent;
        CGFloat dg = g - rgb.greenComponent;
        CGFloat db = b - rgb.blueComponent;
        CGFloat dist = dr*dr + dg*dg + db*db;

        if (dist < minDist) {
            minDist = dist;
            closest = color;
        }
    }

    return closest;
}

- (CGFloat)colorDistance:(NSColor *)c1 to:(NSColor *)c2 {
    NSColor *rgb1 = [c1 colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSColor *rgb2 = [c2 colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];

    CGFloat dr = rgb1.redComponent - rgb2.redComponent;
    CGFloat dg = rgb1.greenComponent - rgb2.greenComponent;
    CGFloat db = rgb1.blueComponent - rgb2.blueComponent;

    return dr*dr + dg*dg + db*db;
}

#pragma mark - Contour Tracing (Marching Squares)

- (NSArray<NSArray<NSValue *> *> *)traceContoursInMask:(uint8_t *)mask
                                                 width:(NSInteger)width
                                                height:(NSInteger)height {
    NSMutableArray<NSArray<NSValue *> *> *contours = [NSMutableArray array];

    // Track visited edges
    uint8_t *visited = calloc((width + 1) * (height + 1), sizeof(uint8_t));
    if (!visited) return contours;

    // Scan for contour start points
    for (NSInteger y = 0; y < height; y++) {
        for (NSInteger x = 0; x < width; x++) {
            if (mask[y * width + x] && !visited[y * (width + 1) + x]) {
                // Check if this is a boundary pixel
                BOOL isBoundary = (x == 0 || y == 0 ||
                                   x == width - 1 || y == height - 1 ||
                                   !mask[y * width + (x - 1)] ||
                                   !mask[(y - 1) * width + x]);

                if (isBoundary) {
                    NSArray<NSValue *> *contour = [self traceContourFrom:x y:y
                                                                    mask:mask
                                                                   width:width
                                                                  height:height
                                                                 visited:visited];
                    if (contour.count >= 3) {
                        [contours addObject:contour];
                    }
                }
            }
        }
    }

    free(visited);
    return contours;
}

- (NSArray<NSValue *> *)traceContourFrom:(NSInteger)startX y:(NSInteger)startY
                                     mask:(uint8_t *)mask
                                    width:(NSInteger)width
                                   height:(NSInteger)height
                                  visited:(uint8_t *)visited {
    NSMutableArray<NSValue *> *points = [NSMutableArray array];

    // Direction vectors (right, down, left, up)
    static const NSInteger dx[] = {1, 0, -1, 0};
    static const NSInteger dy[] = {0, 1, 0, -1};

    NSInteger x = startX, y = startY;
    NSInteger dir = 0;  // Start going right
    NSInteger steps = 0;
    NSInteger maxSteps = width * height * 4;

    do {
        // Add point if on boundary
        [points addObject:[NSValue valueWithPoint:NSMakePoint(x, y)]];
        visited[y * (width + 1) + x] = 1;

        // Find next boundary pixel (Moore neighborhood tracing)
        BOOL found = NO;
        for (NSInteger i = 0; i < 4; i++) {
            NSInteger newDir = (dir + 3 + i) % 4;  // Turn left first
            NSInteger nx = x + dx[newDir];
            NSInteger ny = y + dy[newDir];

            if (nx >= 0 && nx < width && ny >= 0 && ny < height && mask[ny * width + nx]) {
                // Check if this is still on the boundary
                BOOL stillOnBoundary = NO;
                for (NSInteger j = 0; j < 4; j++) {
                    NSInteger checkX = nx + dx[j];
                    NSInteger checkY = ny + dy[j];
                    if (checkX < 0 || checkX >= width || checkY < 0 || checkY >= height ||
                        !mask[checkY * width + checkX]) {
                        stillOnBoundary = YES;
                        break;
                    }
                }

                if (stillOnBoundary) {
                    x = nx;
                    y = ny;
                    dir = newDir;
                    found = YES;
                    break;
                }
            }
        }

        if (!found) break;
        steps++;

    } while ((x != startX || y != startY) && steps < maxSteps);

    return points;
}

#pragma mark - Path Simplification (Douglas-Peucker)

- (NSArray<NSValue *> *)simplifyContour:(NSArray<NSValue *> *)contour tolerance:(CGFloat)tolerance {
    if (contour.count <= 2) return contour;

    // Find the point with maximum distance from line between first and last
    NSPoint first = [contour.firstObject pointValue];
    NSPoint last = [contour.lastObject pointValue];

    CGFloat maxDist = 0;
    NSInteger maxIndex = 0;

    for (NSInteger i = 1; i < contour.count - 1; i++) {
        NSPoint p = [contour[i] pointValue];
        CGFloat dist = [self perpendicularDistance:p from:first to:last];

        if (dist > maxDist) {
            maxDist = dist;
            maxIndex = i;
        }
    }

    // If max distance > tolerance, recursively simplify
    if (maxDist > tolerance) {
        NSArray *left = [self simplifyContour:[contour subarrayWithRange:NSMakeRange(0, maxIndex + 1)]
                                    tolerance:tolerance];
        NSArray *right = [self simplifyContour:[contour subarrayWithRange:NSMakeRange(maxIndex, contour.count - maxIndex)]
                                     tolerance:tolerance];

        // Combine results (excluding duplicate middle point)
        NSMutableArray *result = [NSMutableArray arrayWithArray:left];
        [result addObjectsFromArray:[right subarrayWithRange:NSMakeRange(1, right.count - 1)]];
        return result;
    }

    // Simplify to just endpoints
    return @[contour.firstObject, contour.lastObject];
}

- (CGFloat)perpendicularDistance:(NSPoint)p from:(NSPoint)lineStart to:(NSPoint)lineEnd {
    CGFloat dx = lineEnd.x - lineStart.x;
    CGFloat dy = lineEnd.y - lineStart.y;

    CGFloat lineLengthSq = dx * dx + dy * dy;

    if (lineLengthSq < 0.0001) {
        // Line is a point
        dx = p.x - lineStart.x;
        dy = p.y - lineStart.y;
        return sqrt(dx * dx + dy * dy);
    }

    // Calculate perpendicular distance
    CGFloat t = ((p.x - lineStart.x) * dx + (p.y - lineStart.y) * dy) / lineLengthSq;
    t = MAX(0, MIN(1, t));

    CGFloat nearestX = lineStart.x + t * dx;
    CGFloat nearestY = lineStart.y + t * dy;

    dx = p.x - nearestX;
    dy = p.y - nearestY;

    return sqrt(dx * dx + dy * dy);
}

#pragma mark - Path Data Generation

- (NSString *)pathDataFromContour:(NSArray<NSValue *> *)contour {
    if (contour.count < 2) return @"";

    NSMutableString *pathData = [NSMutableString string];

    NSPoint first = [contour.firstObject pointValue];
    [pathData appendFormat:@"M%.1f,%.1f", first.x, first.y];

    for (NSInteger i = 1; i < contour.count; i++) {
        NSPoint p = [contour[i] pointValue];
        [pathData appendFormat:@"L%.1f,%.1f", p.x, p.y];
    }

    [pathData appendString:@"Z"];

    return pathData;
}

- (CGFloat)areaOfContour:(NSArray<NSValue *> *)contour {
    if (contour.count < 3) return 0;

    // Shoelace formula
    CGFloat area = 0;
    NSInteger n = contour.count;

    for (NSInteger i = 0; i < n; i++) {
        NSPoint p1 = [contour[i] pointValue];
        NSPoint p2 = [contour[(i + 1) % n] pointValue];
        area += (p1.x * p2.y) - (p2.x * p1.y);
    }

    return area / 2.0;
}

- (CGFloat)estimatePathArea:(NSString *)pathData {
    // Quick estimate based on path string length
    // Real implementation would parse and calculate
    return pathData.length;
}

@end
