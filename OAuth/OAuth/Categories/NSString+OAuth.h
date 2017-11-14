//
//  NSString+OAuth.h
//  OAuth
//
//  Created by Markus Gage on 2017-11-14.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OAuth)

+ (NSString *)timestampString;
+ (NSString *)nonce;
+ (NSString *)stringFromUrlEncodedString:(NSString *)string;
+ (NSString *)stringFromDictionary:(NSDictionary *)dictionary;

@end
