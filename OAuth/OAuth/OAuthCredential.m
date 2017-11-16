//
//  OAuthCredential.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-08.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import "OAuthCredential.h"

@interface OAuthCredential ()
@property (copy, nonatomic) NSString *consumerKey;
@property (copy, nonatomic) NSString *consumerSecret;
@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSString *tokenSecret;
@end

@implementation OAuthCredential

- (instancetype)initWithComsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    self = [super init];
    if (self) {
        self.consumerKey = consumerKey;
        self.consumerSecret = consumerSecret;
    }
    return self;
}

- (void)setRequestToken:(NSString *)requestToken requestTokenSecret:(NSString *)requestTokenSecret {
    self.token = requestToken;
    self.tokenSecret = requestTokenSecret;
}

- (void)setAccessToken:(NSString *)accessToken accessTokenSecret:(NSString *)accessTokenSecret {
    self.token = accessToken;
    self.tokenSecret = accessTokenSecret;
}
- (BOOL)isExpired {
    return [self.expirationDate timeIntervalSinceNow] <= 0.0;
}

@end
