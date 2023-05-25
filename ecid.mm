//
//  TSSSaver.m
//  nitoTV4
//
//  Created by Kevin Bradley on 1/9/18.
//  Copyright © 2018 nito. All rights reserved.
//

#import "IOKit/IOKitLib.h"
#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

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



int main(int argc, char* argv[]) 
{
    //NSString *boardConfig = [self returnForProcess:[NSString stringWithFormat:@"%@ -i", unamePath]];
    NSString *ecid = HexToDec([CYDHex((NSData *) CYDIOGetValue("IODeviceTree:/chosen", @"unique-chip-id"), true) uppercaseString]);
    DLog(@"ecid: %@", ecid);
    
    size_t size;
    char *kHwModel = "hw.model";
    sysctlbyname(kHwModel, NULL, &size, NULL, 0);
    char *answer = (char *)malloc(size);
    sysctlbyname(kHwModel, answer, &size, NULL, 0);
    
    NSString *hwModel = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    DLog(@"model: %@", hwModel);

    size_t size2;
    sysctlbyname("hw.machine", NULL, &size2, NULL, 0);
    char *machine = (char *)malloc(size2);
    sysctlbyname("hw.machine", machine, &size2, NULL, 0);
    NSString *hwMachine =  [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    DLog(@"machine: %@", hwMachine);
    
    DLog(@"tsschecker_macos -d %@ -B %@ -e %@ -s -i ", hwMachine, hwModel, ecid);
    
    return 0;
}



