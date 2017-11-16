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
@property (copy, nonatomic, readonly) NSString *token;
@property (copy, nonatomic, readonly) NSString *tokenSecret;
@property (strong, nonatomic) NSDate *expirationDate;

- (instancetype)initWithComsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;
- (void)setRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret;
- (void)setAccessToken:(NSString *)acessToken accessTokenSecret:(NSString *)accessTokenSecret;
- (BOOL)isExpired;

@end
