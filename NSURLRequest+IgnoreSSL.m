
#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host {
    return true;
}

@end
