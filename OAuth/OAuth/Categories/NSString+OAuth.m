//
//  NSString+OAuth.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-14.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import "NSString+OAuth.h"

@implementation NSString (OAuth)

+ (NSString *)timestampString {
    NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%u", (int)t];
}

+ (NSString *)nonce {
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}

+ (NSString *)stringFromUrlEncodedString:(NSString *)string {
    NSMutableCharacterSet *chars = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [chars removeCharactersInString:@"!*'();:@&=+$,/?%#[]"];
    
    return     [string stringByAddingPercentEncodingWithAllowedCharacters:chars];
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary {
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *key in sortedKeys) {
        NSString *encKey = [NSString stringFromUrlEncodedString:key];
        NSString *encValue = [NSString stringFromUrlEncodedString:[dictionary objectForKey:key]];
        
        NSString *pair = [NSString stringWithFormat:@"%@=%@", encKey, encValue];
        [keyValuePairs addObject:pair];
    }
    
    return [keyValuePairs componentsJoinedByString:@"&"];
}

@end
