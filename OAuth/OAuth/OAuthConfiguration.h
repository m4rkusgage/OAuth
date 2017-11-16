//
//  OAuthConfiguration.h
//  OAuth
//
//  Created by Markus Gage on 2017-11-11.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAuthConfiguration : NSObject
@property (copy, nonatomic) NSString *baseURL;
@property (copy, nonatomic, getter=requestTokenURLString) NSString *requestTokenPath;
@property (copy, nonatomic, getter=authorizationURLString) NSString *authorizationPath;
@property (copy, nonatomic, getter=accessTokenURLString) NSString *accessTokenPath;
@property (copy, nonatomic) NSString *callBackURLString;

- (instancetype)initWithBaseURL:(NSString *)baseURL;
- (void)setRequestTokenPath:(NSString *)requestTokenPath authorizationPath:(NSString *)authorizationPath accessTokenPath:(NSString *)accessTokenPath;

@end
