//
//  NSDictionary+OAuth.h
//  OAuth
//
//  Created by Markus Gage on 2017-11-14.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (OAuth)

+ (NSDictionary *)dictionaryFromQueryString:(NSString *)string;

@end
