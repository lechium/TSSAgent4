//
//  TSSSaver.m
//  nitoTV4
//
//  Created by Kevin Bradley on 1/9/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "TSSSaver.h"
#import "IOKit/IOKitLib.h"

static NSString *HexToDec(NSString *hexValue)
{
    if (hexValue == nil)
        return nil;
    
    unsigned long long dec;
    NSScanner *scan = [NSScanner scannerWithString:hexValue];
    if ([scan scanHexLongLong:&dec])
    {
        
        return [NSString stringWithFormat:@"%llu", dec];
        //NSLog(@"chipID binary: %@", finalValue);
    }
    
    return nil;
}

/*
 
 CYDIOGetValue is a carbon copy of CYIOGetValue from Cydia by Jay Freeman
 CYDHex is a carbon copy of CYDHex from Cydia by Jay Freeman
 */

static NSObject *CYDIOGetValue(const char *path, NSString *property) {
    
    io_registry_entry_t entry(IORegistryEntryFromPath(kIOMasterPortDefault, path));
    if (entry == MACH_PORT_NULL)
        return nil;
    
    CFTypeRef value(IORegistryEntryCreateCFProperty(entry, (__bridge CFStringRef) property, kCFAllocatorDefault, 0));
    IOObjectRelease(entry);
    
    if (value == NULL)
        return nil;
    return (__bridge id) value;
}

static NSString *CYDHex(NSData *data, bool reverse) {
    if (data == nil)
        return nil;
    
    size_t length([data length]);
    uint8_t bytes[length];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [data getBytes:bytes];
#pragma clang diagnostic pop
    char string[length * 2 + 1];
    for (size_t i(0); i != length; ++i)
        sprintf(string + i * 2, "%.2x", bytes[reverse ? length - i - 1 : i]);
    
    return [NSString stringWithUTF8String:string];
}

@implementation TSSSaver

+ (NSMutableURLRequest *)postRequest
{
    NSString *ecid = HexToDec([CYDHex((NSData *) CYDIOGetValue("IODeviceTree:/chosen", @"unique-chip-id"), true) uppercaseString]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *theString = [[NSString stringWithFormat:@"ecid=%@&boardConfig=%@&deviceID=%@", ecid, @"j42dap", @"AppleTV5,3"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    NSLog(@"sending string: %@", theString);
    
    NSData *postData = [theString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]; //convert string to NSData that can be used as the HTTPBody of the POST
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://tsssaver.1conan.com/app.php"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"InetURL/1.0" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:postData];
    return request;
}

@end


int main(int argc, char* argv[]) 
{
    
    NSMutableURLRequest *request = [TSSSaver postRequest];
    NSURLResponse *theResponse = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
#pragma clang diagnostic pop
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSLog(@"datstring: %@", datString);
    return 0;
}



