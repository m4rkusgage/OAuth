//
//  OAuthClient.h
//  OAuth
//
//  Created by Markus Gage on 2017-11-08.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Success)(BOOL isSuccessful, NSError *error);
typedef void(^Completion)(id result, NSError *error);

@interface OAuthClient : NSObject

+ (OAuthClient *)sharedInstance;

- (void)setBaseURLString:(NSString *)baseURL consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath
                          userAuthorizationPath:(NSString *)userAuthorizationPath
                                accessTokenPath:(NSString *)accessTokenPath
                                callbackURLPath:(NSString *)callBackPath
                                     completion:(Success)completion;


- (void)authorizedRequestPath:(NSString *)requestPath
                forHTTPMethod:(NSString *)httpMethod
              extraParameters:(NSDictionary *)extraParameters
                   completion:(Completion)completion;

- (void)authorize;
- (void)authorizationOpenFromURL:(NSURL *)authURL completion:(Success)completion;
@end
