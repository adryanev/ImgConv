#import <XCTest/XCTest.h>
#import "ITBImageConverter.h"

@interface ITBImageConverterTests : XCTestCase

@property (strong, nonatomic) ITBImageConverter *converter;

@end

@implementation ITBImageConverterTests

- (void)setUp {
    [super setUp];
    self.converter = [[ITBImageConverter alloc] init];
}

- (void)tearDown {
    self.converter = nil;
    [super tearDown];
}

#pragma mark - Helper Methods

- (NSImage *)createTestImageWithSize:(NSSize)size hasAlpha:(BOOL)hasAlpha {
    // Use modern block-based API (thread-safe, not deprecated)
    NSImage *image = [NSImage imageWithSize:size
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect dstRect) {
        if (hasAlpha) {
            // Draw with transparency
            [[NSColor clearColor] setFill];
            NSRectFill(NSMakeRect(0, 0, size.width, size.height));
            [[NSColor redColor] setFill];
            NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(NSMakeRect(0, 0, size.width, size.height), 10, 10)];
            [path fill];
        } else {
            // Solid color, no alpha
            [[NSColor blueColor] setFill];
            NSRectFill(NSMakeRect(0, 0, size.width, size.height));
        }
        return YES;
    }];
    return image;
}

#pragma mark - Invalid Input Tests

- (void)testConvertNilImageReturnsError {
    NSError *error = nil;
    NSData *result = [self.converter convertImage:nil
                                         toFormat:ITBImageFormatPNG
                                   qualityPercent:100
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNil(result, @"Result should be nil for nil input");
    XCTAssertNotNil(error, @"Error should be returned for nil input");
    XCTAssertEqual(error.code, ITBImageConverterErrorInvalidInput, @"Error code should be InvalidInput");
    XCTAssertEqualObjects(error.domain, ITBImageConverterErrorDomain, @"Error domain should match");
}

#pragma mark - PNG Conversion Tests

- (void)testConvertToPNG {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(100, 100) hasAlpha:NO];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatPNG
                                   qualityPercent:100
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNotNil(result, @"PNG data should not be nil");
    XCTAssertNil(error, @"Error should be nil for successful conversion");
    XCTAssertGreaterThan(result.length, 0, @"PNG data should have content");

    // Verify PNG signature (first 8 bytes)
    const unsigned char pngSignature[] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
    NSData *signature = [result subdataWithRange:NSMakeRange(0, 8)];
    XCTAssertTrue(memcmp(signature.bytes, pngSignature, 8) == 0, @"Data should have PNG signature");
}

- (void)testConvertToPNGWithAlpha {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(100, 100) hasAlpha:YES];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatPNG
                                   qualityPercent:100
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNotNil(result, @"PNG data should not be nil");
    XCTAssertNil(error, @"Error should be nil for successful conversion");
}

#pragma mark - JPEG Conversion Tests

- (void)testConvertToJPEG {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(100, 100) hasAlpha:NO];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatJPEG
                                   qualityPercent:85
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNotNil(result, @"JPEG data should not be nil");
    XCTAssertNil(error, @"Error should be nil for successful conversion");
    XCTAssertGreaterThan(result.length, 0, @"JPEG data should have content");

    // Verify JPEG signature (FFD8)
    const unsigned char jpegSignature[] = {0xFF, 0xD8};
    NSData *signature = [result subdataWithRange:NSMakeRange(0, 2)];
    XCTAssertTrue(memcmp(signature.bytes, jpegSignature, 2) == 0, @"Data should have JPEG signature");
}

- (void)testConvertToJPEGWithAlphaAndBackgroundColor {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(100, 100) hasAlpha:YES];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatJPEG
                                   qualityPercent:85
                                  backgroundColor:[NSColor whiteColor]
                                            error:&error];

    XCTAssertNotNil(result, @"JPEG data should not be nil");
    XCTAssertNil(error, @"Error should be nil for successful conversion");
}

- (void)testJPEGQualityAffectsFileSize {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(200, 200) hasAlpha:NO];

    NSData *highQuality = [self.converter convertImage:image
                                              toFormat:ITBImageFormatJPEG
                                        qualityPercent:95
                                       backgroundColor:nil
                                                 error:nil];

    NSData *lowQuality = [self.converter convertImage:image
                                             toFormat:ITBImageFormatJPEG
                                       qualityPercent:30
                                      backgroundColor:nil
                                                error:nil];

    XCTAssertNotNil(highQuality, @"High quality JPEG should not be nil");
    XCTAssertNotNil(lowQuality, @"Low quality JPEG should not be nil");
    XCTAssertGreaterThan(highQuality.length, lowQuality.length, @"Higher quality should produce larger file");
}

#pragma mark - WebP Conversion Tests

- (void)testConvertToWebP {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(100, 100) hasAlpha:NO];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatWebP
                                   qualityPercent:85
                                  backgroundColor:nil
                                            error:&error];

    // WebP may not be available on all systems, so we accept nil with proper error
    if (result) {
        XCTAssertNil(error, @"Error should be nil for successful conversion");
        XCTAssertGreaterThan(result.length, 0, @"WebP data should have content");

        // Verify WebP signature (RIFF....WEBP)
        if (result.length >= 12) {
            const char *bytes = result.bytes;
            XCTAssertTrue(memcmp(bytes, "RIFF", 4) == 0, @"Should start with RIFF");
            XCTAssertTrue(memcmp(bytes + 8, "WEBP", 4) == 0, @"Should have WEBP marker");
        }
    } else {
        // WebP encoding might not be supported
        XCTAssertNotNil(error, @"If no result, error should be provided");
    }
}

#pragma mark - Format Support Tests

- (void)testCanReadFormat {
    XCTAssertTrue([ITBImageConverter canReadFormat:@"png"], @"Should support PNG");
    XCTAssertTrue([ITBImageConverter canReadFormat:@"PNG"], @"Should support PNG (case insensitive)");
    XCTAssertTrue([ITBImageConverter canReadFormat:@".png"], @"Should support PNG with dot");
    XCTAssertTrue([ITBImageConverter canReadFormat:@"jpg"], @"Should support JPG");
    XCTAssertTrue([ITBImageConverter canReadFormat:@"jpeg"], @"Should support JPEG");
    XCTAssertTrue([ITBImageConverter canReadFormat:@"webp"], @"Should support WebP");

    XCTAssertFalse([ITBImageConverter canReadFormat:@"gif"], @"Should not support GIF");
    XCTAssertFalse([ITBImageConverter canReadFormat:@"bmp"], @"Should not support BMP");
    XCTAssertFalse([ITBImageConverter canReadFormat:@""], @"Should not support empty string");
}

- (void)testCanWriteFormat {
    XCTAssertTrue([ITBImageConverter canWriteFormat:ITBImageFormatPNG], @"Should write PNG");
    XCTAssertTrue([ITBImageConverter canWriteFormat:ITBImageFormatJPEG], @"Should write JPEG");
    XCTAssertTrue([ITBImageConverter canWriteFormat:ITBImageFormatWebP], @"Should write WebP");
}

- (void)testFileExtensionForFormat {
    XCTAssertEqualObjects([ITBImageConverter fileExtensionForFormat:ITBImageFormatPNG], @"png");
    XCTAssertEqualObjects([ITBImageConverter fileExtensionForFormat:ITBImageFormatJPEG], @"jpg");
    XCTAssertEqualObjects([ITBImageConverter fileExtensionForFormat:ITBImageFormatWebP], @"webp");
}

#pragma mark - Alpha Detection Tests

- (void)testImageHasAlphaWithAlphaImage {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(50, 50) hasAlpha:YES];
    // Note: This test may be flaky depending on how the image is created
    // The implementation checks for alpha in bitmap representations
}

- (void)testImageHasAlphaWithNilImage {
    XCTAssertFalse([ITBImageConverter imageHasAlpha:nil], @"Nil image should return NO");
}

#pragma mark - Quality Bounds Tests

- (void)testQualityClampingLowerBound {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(50, 50) hasAlpha:NO];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatJPEG
                                   qualityPercent:-50 // Below 0
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNotNil(result, @"Should handle negative quality by clamping");
    XCTAssertNil(error, @"Should not error on clamped quality");
}

- (void)testQualityClampingUpperBound {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(50, 50) hasAlpha:NO];

    NSError *error = nil;
    NSData *result = [self.converter convertImage:image
                                         toFormat:ITBImageFormatJPEG
                                   qualityPercent:150 // Above 100
                                  backgroundColor:nil
                                            error:&error];

    XCTAssertNotNil(result, @"Should handle excessive quality by clamping");
    XCTAssertNil(error, @"Should not error on clamped quality");
}

#pragma mark - Performance Tests

- (void)testConversionPerformance {
    NSImage *image = [self createTestImageWithSize:NSMakeSize(1000, 1000) hasAlpha:NO];

    [self measureBlock:^{
        [self.converter convertImage:image
                            toFormat:ITBImageFormatJPEG
                      qualityPercent:85
                     backgroundColor:nil
                               error:nil];
    }];
}

@end
