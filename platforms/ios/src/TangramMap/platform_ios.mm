#import "TGMapViewController.h"
#import "TGFontConverter.h"
#import "TGHttpHandler.h"
#import "platform_ios.h"
#import "log.h"

#import <cstdarg>
#import <cstdio>
#import <UIKit/UIKit.h>

namespace Tangram {

std::vector<char> loadUIFont(UIFont* _font) {
    if (!_font) {
        return {};
    }

    CGFontRef fontRef = CGFontCreateWithFontName((CFStringRef)_font.fontName);

    if (!fontRef) {
        return {};
    }

    std::vector<char> data = [TGFontConverter fontDataForCGFont:fontRef];

    CGFontRelease(fontRef);

    if (data.empty()) {
        LOG("CoreGraphics font failed to decode");
    }

    return data;
}

void logMsg(const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
}

void setCurrentThreadPriority(int priority) {
    // No-op
}

void initGLExtensions() {
    // No-op
}

iOSPlatform::iOSPlatform(TGMapViewController* _viewController) :
    Platform(),
    m_viewController(_viewController) {}

void iOSPlatform::requestRender() const {
    [m_viewController renderOnce];
}

void iOSPlatform::setContinuousRendering(bool _isContinuous) {
    Platform::setContinuousRendering(_isContinuous);
    [m_viewController setContinuous:_isContinuous];
}

std::vector<FontSourceHandle> iOSPlatform::systemFontFallbacksHandle() const {
    NSArray* fallbacks = [UIFont familyNames];

    std::vector<FontSourceHandle> handles;

    for (id fallback in fallbacks) {

        handles.emplace_back([fallback]() {
            auto data = loadUIFont([UIFont fontWithName:fallback size:1.0]);
            return data;
        });
    }

    return handles;
}

std::vector<char> iOSPlatform::systemFont(const std::string& _name, const std::string& _weight, const std::string& _face) const {
    static std::map<int, CGFloat> weightTraits = {
        {100, UIFontWeightUltraLight},
        {200, UIFontWeightThin},
        {300, UIFontWeightLight},
        {400, UIFontWeightRegular},
        {500, UIFontWeightMedium},
        {600, UIFontWeightSemibold},
        {700, UIFontWeightBold},
        {800, UIFontWeightHeavy},
        {900, UIFontWeightBlack},
    };

    static std::map<std::string, UIFontDescriptorSymbolicTraits> fontTraits = {
        {"italic", UIFontDescriptorTraitItalic},
        {"oblique", UIFontDescriptorTraitItalic},
        {"bold", UIFontDescriptorTraitBold},
        {"expanded", UIFontDescriptorTraitExpanded},
        {"condensed", UIFontDescriptorTraitCondensed},
        {"monospace", UIFontDescriptorTraitMonoSpace},
    };

    UIFont* font = [UIFont fontWithName:[NSString stringWithUTF8String:_name.c_str()] size:1.0];

    if (font == nil) {
        // Get the default system font
        if (_weight.empty()) {
            font = [UIFont systemFontOfSize:1.0];
        } else {
            int weight = std::atoi(_weight.c_str());

            // Default to 400 boldness
            weight = (weight == 0) ? 400 : weight;

            // Map weight value to range [100..900]
            weight = std::min(std::max(100, (int)floor(weight / 100.0 + 0.5) * 100), 900);

            font = [UIFont systemFontOfSize:1.0 weight:weightTraits[weight]];
        }
    }

    if (_face != "normal") {
        UIFontDescriptorSymbolicTraits traits;
        UIFontDescriptor* descriptor = [font fontDescriptor];

        auto it = fontTraits.find(_face);
        if (it != fontTraits.end()) {
            traits = it->second;

            // Create a new descriptor with the symbolic traits
            descriptor = [descriptor fontDescriptorWithSymbolicTraits:traits];

            if (descriptor != nil) {
                font = [UIFont fontWithDescriptor:descriptor size:1.0];
            }
        }
    }

    return loadUIFont(font);
}

UrlRequestHandle iOSPlatform::startUrlRequest(Url _url, UrlCallback _callback) {
    TGHttpHandler* httpHandler = [m_viewController httpHandler];

    if (!httpHandler) {
        return false;
    }

    TGDownloadCompletionHandler handler = ^void (NSData* data, NSURLResponse* response, NSError* error) {

        // Create our response object. The '__block' specifier is to allow mutation in the data-copy block below.
        __block UrlResponse urlResponse;

        // Check for errors from NSURLSession, then check for HTTP errors.
        if (error != nil) {

            urlResponse.error = [error.localizedDescription UTF8String];

        } else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {

            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int statusCode = [httpResponse statusCode];
            if (statusCode >= 400) {
                urlResponse.error = [[NSHTTPURLResponse localizedStringForStatusCode: statusCode] UTF8String];
            }
        }

        // Copy the data from the NSURLResponse into our URLResponse.
        // First we allocate the total data size.
        urlResponse.content.resize([data length]);
        // NSData may be stored in several ranges, so the 'bytes' method may incur extra copy operations.
        // To avoid that we copy the data in ranges provided by the NSData.
        [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
            memcpy(urlResponse.content.data() + byteRange.location, bytes, byteRange.length);
        }];

        // Run the callback from the requester.
        if (_callback) {
            _callback(urlResponse);
        }
    };

    NSString* url = [NSString stringWithUTF8String:_url.string().c_str()];
    NSUInteger taskIdentifier = [httpHandler downloadRequestAsync:url completionHandler:handler];

    return taskIdentifier;
}

void iOSPlatform::cancelUrlRequest(UrlRequestHandle _request) {
    TGHttpHandler* httpHandler = [m_viewController httpHandler];

    if (!httpHandler) { return; }

    [httpHandler cancelDownloadRequestAsync:_request];
}

} // namespace Tangram
