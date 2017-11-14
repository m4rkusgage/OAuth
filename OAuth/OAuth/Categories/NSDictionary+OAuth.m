//
//  NSDictionary+OAuth.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-14.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import "NSDictionary+OAuth.h"

@implementation NSDictionary (OAuth)

+ (NSDictionary *)dictionaryFromQueryString:(NSString *)string {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray *parameters = [string componentsSeparatedByString:@"&"];
    
    for (NSString *parameter in parameters) {
        NSArray *parts = [parameter componentsSeparatedByString:@"="];
        NSString *key = [[parts objectAtIndex:0] stringByRemovingPercentEncoding];
        
        if ([parts count] > 1) {
            id value = [[parts objectAtIndex:1] stringByRemovingPercentEncoding];
            [result setObject:value forKey:key];
        }
    }
    return result;
}

@end
