//
//  OAuthCredential.h
//  OAuth
//
//  Created by Markus Gage on 2017-11-08.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAuthCredential : NSObject

@property (copy, nonatomic, readonly) NSString *consumerKey;
@property (copy, nonatomic, readonly) NSString *consumerSecret;
@property (copy, nonatomic, readonly) NSString *requestToken;
@property (copy, nonatomic, readonly) NSString *requestTokenSecret;
@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *accessTokenSecret;
@property (strong, nonatomic) NSString *tokenType;
@property (strong, nonatomic) NSString *refreshToken;
@property (strong, nonatomic) NSDate *expirationDate;

- (instancetype)initWithComsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;
- (void)setRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret;

- (BOOL)isExpired;

@end
