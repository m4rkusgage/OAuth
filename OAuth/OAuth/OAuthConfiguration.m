//
//  OAuthConfiguration.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-11.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import "OAuthConfiguration.h"

@implementation OAuthConfiguration

- (instancetype)initWithBaseURL:(NSString *)baseURL {
    self = [super init];
    if (self) {
        self.baseURL = baseURL;
    }
    return self;
}

- (void)setRequestTokenPath:(NSString *)requestTokenPath authorizationPath:(NSString *)authorizationPath accessTokenPath:(NSString *)accessTokenPath {
    self.requestTokenPath = requestTokenPath;
    self.authorizationPath = authorizationPath;
    self.accessTokenPath = accessTokenPath;
}

- (NSString *)requestTokenURLString {
    return [NSString stringWithFormat:@"%@%@",self.baseURL,_requestTokenPath];
}

- (NSString *)authorizationURLString {
    return [NSString stringWithFormat:@"%@%@",self.baseURL,_authorizationPath];
}

- (NSString *)accessTokenURLString {
    return [NSString stringWithFormat:@"%@%@",self.baseURL,_accessTokenPath];
}
@end
