#import "ITBVectorConverter.h"

NSErrorDomain const ITBVectorConverterErrorDomain = @"ITBVectorConverterErrorDomain";

static NSString *const kAndroidNamespace = @"http://schemas.android.com/apk/res/android";

@interface ITBVectorConverter () <NSXMLParserDelegate>

@property (nonatomic, strong) ITBVectorDocument *currentDocument;
@property (nonatomic, strong) NSMutableArray<ITBVectorGroup *> *groupStack;
@property (nonatomic, strong) NSError *parseError;

@end

@implementation ITBVectorConverter

#pragma mark - Parsing

- (nullable ITBVectorDocument *)parseVectorDrawable:(NSData *)xmlData error:(NSError **)error {
    self.currentDocument = nil;
    self.groupStack = [NSMutableArray array];
    self.parseError = nil;

    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    parser.delegate = self;
    parser.shouldProcessNamespaces = YES;
    parser.shouldResolveExternalEntities = NO;

    if (![parser parse] || self.parseError) {
        if (error) {
            *error = self.parseError ?: [NSError errorWithDomain:ITBVectorConverterErrorDomain
                                                            code:ITBVectorConverterErrorInvalidXML
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse XML"}];
        }
        return nil;
    }

    return self.currentDocument;
}

- (nullable ITBVectorDocument *)parseVectorDrawableAtURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) {
        return nil;
    }
    return [self parseVectorDrawable:data error:error];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {

    if ([elementName isEqualToString:@"vector"]) {
        [self parseVectorElement:attributeDict];
    } else if ([elementName isEqualToString:@"group"]) {
        [self parseGroupElement:attributeDict];
    } else if ([elementName isEqualToString:@"path"]) {
        [self parsePathElement:attributeDict];
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {

    if ([elementName isEqualToString:@"group"] && self.groupStack.count > 0) {
        [self.groupStack removeLastObject];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.parseError = [NSError errorWithDomain:ITBVectorConverterErrorDomain
                                          code:ITBVectorConverterErrorInvalidXML
                                      userInfo:@{NSLocalizedDescriptionKey: parseError.localizedDescription,
                                                 NSUnderlyingErrorKey: parseError}];
}

#pragma mark - Element Parsing

- (void)parseVectorElement:(NSDictionary<NSString *,NSString *> *)attrs {
    self.currentDocument = [[ITBVectorDocument alloc] init];

    CGFloat width = [self parseDP:attrs[@"android:width"] defaultValue:24];
    CGFloat height = [self parseDP:attrs[@"android:height"] defaultValue:24];
    self.currentDocument.outputSize = CGSizeMake(width, height);

    CGFloat viewportWidth = [attrs[@"android:viewportWidth"] floatValue] ?: 24;
    CGFloat viewportHeight = [attrs[@"android:viewportHeight"] floatValue] ?: 24;
    self.currentDocument.viewportSize = CGSizeMake(viewportWidth, viewportHeight);

    if (attrs[@"android:tint"]) {
        self.currentDocument.tintColor = [self parseColor:attrs[@"android:tint"]];
    }

    if (attrs[@"android:alpha"]) {
        self.currentDocument.alpha = [attrs[@"android:alpha"] floatValue];
    }
}

- (void)parseGroupElement:(NSDictionary<NSString *,NSString *> *)attrs {
    ITBVectorGroup *group = [[ITBVectorGroup alloc] init];

    group.name = attrs[@"android:name"];
    group.rotation = [attrs[@"android:rotation"] floatValue];
    group.pivotX = [attrs[@"android:pivotX"] floatValue];
    group.pivotY = [attrs[@"android:pivotY"] floatValue];

    NSString *scaleX = attrs[@"android:scaleX"];
    group.scaleX = scaleX ? [scaleX floatValue] : 1.0;

    NSString *scaleY = attrs[@"android:scaleY"];
    group.scaleY = scaleY ? [scaleY floatValue] : 1.0;

    group.translateX = [attrs[@"android:translateX"] floatValue];
    group.translateY = [attrs[@"android:translateY"] floatValue];

    if (self.groupStack.count > 0) {
        [self.groupStack.lastObject.groups addObject:group];
    } else {
        [self.currentDocument.groups addObject:group];
    }

    [self.groupStack addObject:group];
}

- (void)parsePathElement:(NSDictionary<NSString *,NSString *> *)attrs {
    NSString *pathData = attrs[@"android:pathData"];
    if (!pathData) return;

    ITBVectorPath *path = [[ITBVectorPath alloc] initWithPathData:pathData];

    if (attrs[@"android:fillColor"]) {
        path.fillColor = [self parseColor:attrs[@"android:fillColor"]];
    }

    if (attrs[@"android:strokeColor"]) {
        path.strokeColor = [self parseColor:attrs[@"android:strokeColor"]];
    }

    if (attrs[@"android:strokeWidth"]) {
        path.strokeWidth = [attrs[@"android:strokeWidth"] floatValue];
    }

    if (attrs[@"android:fillAlpha"]) {
        path.fillAlpha = [attrs[@"android:fillAlpha"] floatValue];
    }

    if (attrs[@"android:strokeAlpha"]) {
        path.strokeAlpha = [attrs[@"android:strokeAlpha"] floatValue];
    }

    if (self.groupStack.count > 0) {
        [self.groupStack.lastObject.paths addObject:path];
    } else {
        [self.currentDocument.paths addObject:path];
    }
}

#pragma mark - Value Parsing

- (CGFloat)parseDP:(NSString *)value defaultValue:(CGFloat)defaultValue {
    if (!value) return defaultValue;

    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([trimmed hasSuffix:@"dp"] || [trimmed hasSuffix:@"dip"]) {
        trimmed = [trimmed stringByReplacingOccurrencesOfString:@"dip" withString:@""];
        trimmed = [trimmed stringByReplacingOccurrencesOfString:@"dp" withString:@""];
    }

    return [trimmed floatValue] ?: defaultValue;
}

- (nullable NSColor *)parseColor:(NSString *)colorString {
    if (!colorString || colorString.length == 0) return nil;

    if ([colorString hasPrefix:@"#"]) {
        NSString *hex = [colorString substringFromIndex:1];
        unsigned int colorValue = 0;
        [[NSScanner scannerWithString:hex] scanHexInt:&colorValue];

        CGFloat alpha = 1.0;
        CGFloat red, green, blue;

        if (hex.length == 8) {
            // #AARRGGBB format (Android)
            alpha = ((colorValue >> 24) & 0xFF) / 255.0;
            red = ((colorValue >> 16) & 0xFF) / 255.0;
            green = ((colorValue >> 8) & 0xFF) / 255.0;
            blue = (colorValue & 0xFF) / 255.0;
        } else if (hex.length == 6) {
            // #RRGGBB format
            red = ((colorValue >> 16) & 0xFF) / 255.0;
            green = ((colorValue >> 8) & 0xFF) / 255.0;
            blue = (colorValue & 0xFF) / 255.0;
        } else if (hex.length == 3) {
            // #RGB format
            red = ((colorValue >> 8) & 0xF) / 15.0;
            green = ((colorValue >> 4) & 0xF) / 15.0;
            blue = (colorValue & 0xF) / 15.0;
        } else {
            return nil;
        }

        return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
    }

    return nil;
}

#pragma mark - SVG Export

- (nullable NSString *)convertToSVG:(ITBVectorDocument *)document error:(NSError **)error {
    if (!document) {
        if (error) {
            *error = [NSError errorWithDomain:ITBVectorConverterErrorDomain
                                         code:ITBVectorConverterErrorInvalidDocument
                                     userInfo:@{NSLocalizedDescriptionKey: @"Document is nil"}];
        }
        return nil;
    }

    NSMutableString *svg = [NSMutableString string];

    [svg appendFormat:@"<svg xmlns=\"http://www.w3.org/2000/svg\" "
                      @"width=\"%.0f\" height=\"%.0f\" "
                      @"viewBox=\"0 0 %.0f %.0f\">\n",
                      document.outputSize.width, document.outputSize.height,
                      document.viewportSize.width, document.viewportSize.height];

    // Render paths
    for (ITBVectorPath *path in document.paths) {
        [svg appendString:[self svgPathElement:path]];
    }

    // Render groups
    for (ITBVectorGroup *group in document.groups) {
        [svg appendString:[self svgGroupElement:group]];
    }

    [svg appendString:@"</svg>\n"];

    return svg;
}

- (nullable NSData *)convertToSVGData:(ITBVectorDocument *)document error:(NSError **)error {
    NSString *svg = [self convertToSVG:document error:error];
    if (!svg) return nil;
    return [svg dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)svgPathElement:(ITBVectorPath *)path {
    NSMutableString *element = [NSMutableString stringWithString:@"  <path"];

    if (path.fillColor) {
        [element appendFormat:@" fill=\"%@\"", [self svgColorString:path.fillColor]];
        if (path.fillAlpha < 1.0) {
            [element appendFormat:@" fill-opacity=\"%.2f\"", path.fillAlpha];
        }
    } else {
        [element appendString:@" fill=\"none\""];
    }

    if (path.strokeColor) {
        [element appendFormat:@" stroke=\"%@\"", [self svgColorString:path.strokeColor]];
        if (path.strokeWidth > 0) {
            [element appendFormat:@" stroke-width=\"%.1f\"", path.strokeWidth];
        }
        if (path.strokeAlpha < 1.0) {
            [element appendFormat:@" stroke-opacity=\"%.2f\"", path.strokeAlpha];
        }
    }

    [element appendFormat:@" d=\"%@\"/>\n", path.pathData];

    return element;
}

- (NSString *)svgGroupElement:(ITBVectorGroup *)group {
    NSMutableString *element = [NSMutableString stringWithString:@"  <g"];

    // Build transform string if any transforms are applied
    NSMutableArray *transforms = [NSMutableArray array];

    if (group.translateX != 0 || group.translateY != 0) {
        [transforms addObject:[NSString stringWithFormat:@"translate(%.1f, %.1f)",
                               group.translateX, group.translateY]];
    }

    if (group.rotation != 0) {
        [transforms addObject:[NSString stringWithFormat:@"rotate(%.1f, %.1f, %.1f)",
                               group.rotation, group.pivotX, group.pivotY]];
    }

    if (group.scaleX != 1.0 || group.scaleY != 1.0) {
        [transforms addObject:[NSString stringWithFormat:@"scale(%.2f, %.2f)",
                               group.scaleX, group.scaleY]];
    }

    if (transforms.count > 0) {
        [element appendFormat:@" transform=\"%@\"", [transforms componentsJoinedByString:@" "]];
    }

    [element appendString:@">\n"];

    for (ITBVectorPath *path in group.paths) {
        [element appendString:[self svgPathElement:path]];
    }

    for (ITBVectorGroup *subgroup in group.groups) {
        [element appendString:[self svgGroupElement:subgroup]];
    }

    [element appendString:@"  </g>\n"];

    return element;
}

- (NSString *)svgColorString:(NSColor *)color {
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!rgbColor) rgbColor = color;

    int r = (int)(rgbColor.redComponent * 255);
    int g = (int)(rgbColor.greenComponent * 255);
    int b = (int)(rgbColor.blueComponent * 255);

    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

#pragma mark - PNG Rendering

- (nullable NSImage *)renderToImage:(ITBVectorDocument *)document
                               size:(CGSize)size
                              scale:(CGFloat)scale
                              error:(NSError **)error {
    if (!document) {
        if (error) {
            *error = [NSError errorWithDomain:ITBVectorConverterErrorDomain
                                         code:ITBVectorConverterErrorInvalidDocument
                                     userInfo:@{NSLocalizedDescriptionKey: @"Document is nil"}];
        }
        return nil;
    }

    CGSize pixelSize = CGSizeMake(size.width * scale, size.height * scale);

    // Use modern block-based API (thread-safe, not deprecated)
    // Capture self weakly to avoid retain cycles, though in practice this is fine
    // since the block is executed synchronously when the image is drawn
    __weak typeof(self) weakSelf = self;

    NSImage *image = [NSImage imageWithSize:pixelSize
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect dstRect) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return NO;

        // Scale from viewport to output size
        CGFloat scaleX = pixelSize.width / document.viewportSize.width;
        CGFloat scaleY = pixelSize.height / document.viewportSize.height;

        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform scaleXBy:scaleX yBy:scaleY];
        [transform concat];

        // Render paths
        for (ITBVectorPath *path in document.paths) {
            [strongSelf renderPath:path];
        }

        // Render groups
        for (ITBVectorGroup *group in document.groups) {
            [strongSelf renderGroup:group];
        }

        return YES;
    }];

    return image;
}

- (nullable NSData *)renderToPNG:(ITBVectorDocument *)document
                            size:(CGSize)size
                           scale:(CGFloat)scale
                           error:(NSError **)error {
    NSImage *image = [self renderToImage:document size:size scale:scale error:error];
    if (!image) return nil;

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:NULL
                             pixelsWide:(NSInteger)(size.width * scale)
                             pixelsHigh:(NSInteger)(size.height * scale)
                             bitsPerSample:8
                             samplesPerPixel:4
                             hasAlpha:YES
                             isPlanar:NO
                             colorSpaceName:NSCalibratedRGBColorSpace
                             bytesPerRow:0
                             bitsPerPixel:0];

    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [NSGraphicsContext setCurrentContext:ctx];

    [image drawInRect:NSMakeRect(0, 0, size.width * scale, size.height * scale)
             fromRect:NSZeroRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0];

    [NSGraphicsContext restoreGraphicsState];

    return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

- (void)renderPath:(ITBVectorPath *)path {
    NSBezierPath *bezierPath = [self bezierPathFromPathData:path.pathData];
    if (!bezierPath) return;

    if (path.fillColor) {
        NSColor *fillColor = [path.fillColor colorWithAlphaComponent:path.fillAlpha];
        [fillColor setFill];
        [bezierPath fill];
    }

    if (path.strokeColor && path.strokeWidth > 0) {
        NSColor *strokeColor = [path.strokeColor colorWithAlphaComponent:path.strokeAlpha];
        [strokeColor setStroke];
        bezierPath.lineWidth = path.strokeWidth;
        [bezierPath stroke];
    }
}

- (void)renderGroup:(ITBVectorGroup *)group {
    [NSGraphicsContext saveGraphicsState];

    NSAffineTransform *transform = [group affineTransform];
    [transform concat];

    for (ITBVectorPath *path in group.paths) {
        [self renderPath:path];
    }

    for (ITBVectorGroup *subgroup in group.groups) {
        [self renderGroup:subgroup];
    }

    [NSGraphicsContext restoreGraphicsState];
}

#pragma mark - Path Parsing

- (nullable NSBezierPath *)bezierPathFromPathData:(NSString *)pathData {
    NSBezierPath *path = [NSBezierPath bezierPath];

    NSCharacterSet *commandSet = [NSCharacterSet characterSetWithCharactersInString:@"MmLlHhVvCcSsQqTtAaZz"];

    NSScanner *scanner = [NSScanner scannerWithString:pathData];
    scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *command = nil;
    NSPoint currentPoint = NSZeroPoint;
    NSPoint startPoint = NSZeroPoint;
    NSPoint lastControlPoint = NSZeroPoint;

    while (!scanner.isAtEnd) {
        NSString *newCommand;
        if ([scanner scanCharactersFromSet:commandSet intoString:&newCommand]) {
            command = newCommand;
        }

        if (!command) break;

        unichar cmd = [command characterAtIndex:0];
        BOOL relative = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:cmd];
        cmd = toupper(cmd);

        switch (cmd) {
            case 'M': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:2];
                if (coords.count >= 2) {
                    CGFloat x = [coords[0] floatValue];
                    CGFloat y = [coords[1] floatValue];
                    if (relative) {
                        x += currentPoint.x;
                        y += currentPoint.y;
                    }
                    [path moveToPoint:NSMakePoint(x, y)];
                    currentPoint = NSMakePoint(x, y);
                    startPoint = currentPoint;
                }
                break;
            }
            case 'L': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:2];
                if (coords.count >= 2) {
                    CGFloat x = [coords[0] floatValue];
                    CGFloat y = [coords[1] floatValue];
                    if (relative) {
                        x += currentPoint.x;
                        y += currentPoint.y;
                    }
                    [path lineToPoint:NSMakePoint(x, y)];
                    currentPoint = NSMakePoint(x, y);
                }
                break;
            }
            case 'H': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:1];
                if (coords.count >= 1) {
                    CGFloat x = [coords[0] floatValue];
                    if (relative) x += currentPoint.x;
                    [path lineToPoint:NSMakePoint(x, currentPoint.y)];
                    currentPoint.x = x;
                }
                break;
            }
            case 'V': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:1];
                if (coords.count >= 1) {
                    CGFloat y = [coords[0] floatValue];
                    if (relative) y += currentPoint.y;
                    [path lineToPoint:NSMakePoint(currentPoint.x, y)];
                    currentPoint.y = y;
                }
                break;
            }
            case 'C': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:6];
                if (coords.count >= 6) {
                    CGFloat x1 = [coords[0] floatValue];
                    CGFloat y1 = [coords[1] floatValue];
                    CGFloat x2 = [coords[2] floatValue];
                    CGFloat y2 = [coords[3] floatValue];
                    CGFloat x = [coords[4] floatValue];
                    CGFloat y = [coords[5] floatValue];
                    if (relative) {
                        x1 += currentPoint.x; y1 += currentPoint.y;
                        x2 += currentPoint.x; y2 += currentPoint.y;
                        x += currentPoint.x; y += currentPoint.y;
                    }
                    [path curveToPoint:NSMakePoint(x, y)
                         controlPoint1:NSMakePoint(x1, y1)
                         controlPoint2:NSMakePoint(x2, y2)];
                    lastControlPoint = NSMakePoint(x2, y2);
                    currentPoint = NSMakePoint(x, y);
                }
                break;
            }
            case 'S': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:4];
                if (coords.count >= 4) {
                    CGFloat x1 = 2 * currentPoint.x - lastControlPoint.x;
                    CGFloat y1 = 2 * currentPoint.y - lastControlPoint.y;
                    CGFloat x2 = [coords[0] floatValue];
                    CGFloat y2 = [coords[1] floatValue];
                    CGFloat x = [coords[2] floatValue];
                    CGFloat y = [coords[3] floatValue];
                    if (relative) {
                        x2 += currentPoint.x; y2 += currentPoint.y;
                        x += currentPoint.x; y += currentPoint.y;
                    }
                    [path curveToPoint:NSMakePoint(x, y)
                         controlPoint1:NSMakePoint(x1, y1)
                         controlPoint2:NSMakePoint(x2, y2)];
                    lastControlPoint = NSMakePoint(x2, y2);
                    currentPoint = NSMakePoint(x, y);
                }
                break;
            }
            case 'Q': {
                NSArray *coords = [self scanCoordinatesFromScanner:scanner count:4];
                if (coords.count >= 4) {
                    CGFloat qx = [coords[0] floatValue];
                    CGFloat qy = [coords[1] floatValue];
                    CGFloat x = [coords[2] floatValue];
                    CGFloat y = [coords[3] floatValue];
                    if (relative) {
                        qx += currentPoint.x; qy += currentPoint.y;
                        x += currentPoint.x; y += currentPoint.y;
                    }
                    // Convert quadratic to cubic
                    CGFloat x1 = currentPoint.x + 2.0/3.0 * (qx - currentPoint.x);
                    CGFloat y1 = currentPoint.y + 2.0/3.0 * (qy - currentPoint.y);
                    CGFloat x2 = x + 2.0/3.0 * (qx - x);
                    CGFloat y2 = y + 2.0/3.0 * (qy - y);
                    [path curveToPoint:NSMakePoint(x, y)
                         controlPoint1:NSMakePoint(x1, y1)
                         controlPoint2:NSMakePoint(x2, y2)];
                    lastControlPoint = NSMakePoint(qx, qy);
                    currentPoint = NSMakePoint(x, y);
                }
                break;
            }
            case 'Z': {
                [path closePath];
                currentPoint = startPoint;
                break;
            }
            default:
                break;
        }
    }

    return path;
}

- (NSArray<NSNumber *> *)scanCoordinatesFromScanner:(NSScanner *)scanner count:(NSInteger)count {
    NSMutableArray<NSNumber *> *coords = [NSMutableArray array];
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@", \t\n"];

    for (NSInteger i = 0; i < count; i++) {
        [scanner scanCharactersFromSet:separators intoString:NULL];

        double value;
        if ([scanner scanDouble:&value]) {
            [coords addObject:@(value)];
        } else {
            break;
        }
    }

    return coords;
}

#pragma mark - VD Export

- (nullable NSString *)exportToVectorDrawable:(ITBVectorDocument *)document error:(NSError **)error {
    if (!document) {
        if (error) {
            *error = [NSError errorWithDomain:ITBVectorConverterErrorDomain
                                         code:ITBVectorConverterErrorInvalidDocument
                                     userInfo:@{NSLocalizedDescriptionKey: @"Document is nil"}];
        }
        return nil;
    }

    NSMutableString *xml = [NSMutableString string];

    [xml appendString:@"<vector xmlns:android=\"http://schemas.android.com/apk/res/android\"\n"];
    [xml appendFormat:@"    android:width=\"%.0fdp\"\n", document.outputSize.width];
    [xml appendFormat:@"    android:height=\"%.0fdp\"\n", document.outputSize.height];
    [xml appendFormat:@"    android:viewportWidth=\"%.0f\"\n", document.viewportSize.width];
    [xml appendFormat:@"    android:viewportHeight=\"%.0f\">\n", document.viewportSize.height];

    // Export paths
    for (ITBVectorPath *path in document.paths) {
        [xml appendString:[self vdPathElement:path indent:4]];
    }

    // Export groups
    for (ITBVectorGroup *group in document.groups) {
        [xml appendString:[self vdGroupElement:group indent:4]];
    }

    [xml appendString:@"</vector>\n"];

    return xml;
}

- (nullable NSData *)exportToVectorDrawableData:(ITBVectorDocument *)document error:(NSError **)error {
    NSString *xml = [self exportToVectorDrawable:document error:error];
    if (!xml) return nil;
    return [xml dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)vdPathElement:(ITBVectorPath *)path indent:(NSInteger)indent {
    NSString *spaces = [@"" stringByPaddingToLength:indent withString:@" " startingAtIndex:0];
    NSMutableString *element = [NSMutableString stringWithFormat:@"%@<path\n", spaces];

    if (path.fillColor) {
        [element appendFormat:@"%@    android:fillColor=\"%@\"\n", spaces, [self vdColorString:path.fillColor]];
    }

    if (path.strokeColor) {
        [element appendFormat:@"%@    android:strokeColor=\"%@\"\n", spaces, [self vdColorString:path.strokeColor]];
        if (path.strokeWidth > 0) {
            [element appendFormat:@"%@    android:strokeWidth=\"%.1f\"\n", spaces, path.strokeWidth];
        }
    }

    if (path.fillAlpha < 1.0) {
        [element appendFormat:@"%@    android:fillAlpha=\"%.2f\"\n", spaces, path.fillAlpha];
    }

    if (path.strokeAlpha < 1.0) {
        [element appendFormat:@"%@    android:strokeAlpha=\"%.2f\"\n", spaces, path.strokeAlpha];
    }

    [element appendFormat:@"%@    android:pathData=\"%@\"/>\n", spaces, path.pathData];

    return element;
}

- (NSString *)vdGroupElement:(ITBVectorGroup *)group indent:(NSInteger)indent {
    NSString *spaces = [@"" stringByPaddingToLength:indent withString:@" " startingAtIndex:0];
    NSMutableString *element = [NSMutableString stringWithFormat:@"%@<group", spaces];

    if (group.name) {
        [element appendFormat:@"\n%@    android:name=\"%@\"", spaces, group.name];
    }
    if (group.rotation != 0) {
        [element appendFormat:@"\n%@    android:rotation=\"%.1f\"", spaces, group.rotation];
    }
    if (group.pivotX != 0) {
        [element appendFormat:@"\n%@    android:pivotX=\"%.1f\"", spaces, group.pivotX];
    }
    if (group.pivotY != 0) {
        [element appendFormat:@"\n%@    android:pivotY=\"%.1f\"", spaces, group.pivotY];
    }
    if (group.scaleX != 1.0) {
        [element appendFormat:@"\n%@    android:scaleX=\"%.2f\"", spaces, group.scaleX];
    }
    if (group.scaleY != 1.0) {
        [element appendFormat:@"\n%@    android:scaleY=\"%.2f\"", spaces, group.scaleY];
    }
    if (group.translateX != 0) {
        [element appendFormat:@"\n%@    android:translateX=\"%.1f\"", spaces, group.translateX];
    }
    if (group.translateY != 0) {
        [element appendFormat:@"\n%@    android:translateY=\"%.1f\"", spaces, group.translateY];
    }

    [element appendString:@">\n"];

    for (ITBVectorPath *path in group.paths) {
        [element appendString:[self vdPathElement:path indent:indent + 4]];
    }

    for (ITBVectorGroup *subgroup in group.groups) {
        [element appendString:[self vdGroupElement:subgroup indent:indent + 4]];
    }

    [element appendFormat:@"%@</group>\n", spaces];

    return element;
}

- (NSString *)vdColorString:(NSColor *)color {
    NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    if (!rgbColor) rgbColor = color;

    int a = (int)(rgbColor.alphaComponent * 255);
    int r = (int)(rgbColor.redComponent * 255);
    int g = (int)(rgbColor.greenComponent * 255);
    int b = (int)(rgbColor.blueComponent * 255);

    if (a == 255) {
        return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
    } else {
        return [NSString stringWithFormat:@"#%02X%02X%02X%02X", a, r, g, b];
    }
}

#pragma mark - Detection

+ (BOOL)isVectorDrawableData:(NSData *)data {
    if (data.length < 50) return NO;

    NSString *prefix = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, MIN(500, data.length))]
                                             encoding:NSUTF8StringEncoding];
    if (!prefix) return NO;

    return [prefix containsString:@"<vector"] &&
           [prefix containsString:@"android"];
}

+ (BOOL)isVectorDrawableAtURL:(NSURL *)url {
    if (![[url pathExtension] isEqualToString:@"xml"]) return NO;

    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
    return [self isVectorDrawableData:data];
}

@end
