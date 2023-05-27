//
//  TSSSaver.m
//  nitoTV4
//
//  Created by Kevin Bradley on 1/9/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "TSSSaver.h"
#import "IOKit/IOKitLib.h"
#include <sys/utsname.h>
#import <libkbtask/KBTaskManager.h>
#import "NSURLRequest+cURL.h"
#import "NSURLRequest+IgnoreSSL.h"

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

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

+ (NSString *)returnForProcess:(NSString *)call
{
    if (call==nil)
        return 0;
    char line[200];
    //NSLog(@"running process: %@", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp)
    {
        while (fgets(line, sizeof line, fp))
        {
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return [lines componentsJoinedByString:@"\n"];
}

+ (NSMutableURLRequest *)postRequest
{
    NSString *unamePath = @"uname";
    NSString *device = [KBTaskManager kb_task_returnForProcess:[NSString stringWithFormat:@"%@ -m", unamePath]];
    NSString *boardConfig = [KBTaskManager kb_task_returnForProcess:[NSString stringWithFormat:@"%@ -i", unamePath]];
    NSString *ecid = HexToDec([CYDHex((NSData *) CYDIOGetValue("IODeviceTree:/chosen", @"unique-chip-id"), true) uppercaseString]);
    DLog(@"device: %@", device);
    DLog(@"boardConfig: %@", boardConfig);
    DLog(@"ecid: %@", ecid);
    if (device == nil) device = @"AppleTV5,3";
    if (boardConfig == nil) boardConfig = @"j42dap";
    
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *theString = [[NSString stringWithFormat:@"ecid=%@&boardConfig=%@&deviceID=%@", ecid, boardConfig, device] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
    //DLog(@"sending string: %@", theString);
    
    NSDictionary *submitDict = @{@"boardConfig": boardConfig,
                                 @"ecid": ecid,
                                 @"deviceIdentifier": device};
    
    
    //NSData *postData = [theString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]; //convert string to NSData that can be used as the HTTPBody of the POST
    NSData *postData = [NSJSONSerialization dataWithJSONObject:submitDict options:0 error:nil];
    //NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    //[request setURL:[NSURL URLWithString:@"https://tsssaver.1conan.com/app.php"]];
    [request setURL:[NSURL URLWithString:@"https://tsssaver.1conan.com/v2/api/save.php"]];
    [request setHTTPMethod:@"POST"];
    //[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    //[request setValue:@"InetURL/1.0" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"TSSSaver-app/2.0" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPBody:postData];
    return request;
}

@end


int main(int argc, char* argv[]) 
{
    DLog(@"\nTSSAgent: Automatically save your SHSH2 APTicket blob's to 1conans server\n\n");
    NSMutableURLRequest *request = [TSSSaver postRequest];
    NSHTTPURLResponse *theResponse = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
#pragma clang diagnostic pop
    //NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    if ([theResponse respondsToSelector:@selector(statusCode)]) {
        DLog(@"returned with status code: %lu", [theResponse statusCode]);
    }
    if (returnData) {
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData  options:NSJSONReadingAllowFragments error:nil];
        DLog(@"%@", jsonDict);
        return 0;
    } else {
        DLog(@"No data returned from the server!\n");
    }
    return -1;
}



