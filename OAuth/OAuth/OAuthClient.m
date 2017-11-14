//
//  OAuthClient.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-08.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "OAuthClient.h"
#import "Constants.h"
#import "NSMutableURLRequest+OAuth.h"
#import "OAuthCredential.h"
#import "OAuthConfiguration.h"
#import <CommonCrypto/CommonHMAC.h>

@interface OAuthClient ()
@property (strong, nonatomic) OAuthCredential *credential;
@property (strong, nonatomic) OAuthConfiguration *configuration;
@end

@implementation OAuthClient

+ (OAuthClient *)sharedInstance {
    static OAuthClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAuthClient alloc] init];
    });
    
    return _sharedInstance;
}

- (void)setBaseURLString:(NSString *)baseURL consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    self.configuration = [[OAuthConfiguration alloc] initWithBaseURL:baseURL];
    self.credential = [[OAuthCredential alloc] initWithComsumerKey:consumerKey consumerSecret:consumerSecret];
}

- (void)authorizeUsingOAuthWithRequestTokenPath:(NSString *)requestTokenPath userAuthorizationPath:(NSString *)userAuthorizationPath accessTokenPath:(NSString *)accessTokenPath callbackURLPath:(NSString *)callBackPath completion:(Success)completion {
    
    [self.configuration setRequestTokenPath:requestTokenPath authorizationPath:userAuthorizationPath accessTokenPath:accessTokenPath];
    
    NSURL *requestTokenURL = [NSURL URLWithString:[self.configuration requestTokenURLString]];
    NSDictionary *extraAuthParamaters = @{@"oauth_callback" : callBackPath};
    
    NSURLRequest *request = [self authorizationRequestWithURL:requestTokenURL extraAuthParamaters:extraAuthParamaters];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            if (completion) {
                completion(NO, nil);
            }
            NSLog(@"There was an error");
            return;
        }
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if ([httpResponse statusCode]!=200) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : result};
                NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:1 userInfo:userInfo];
                
                if (completion) {
                    completion(NO, error);
                }
                return;
            }
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Didn't receive expected HTTP response."};
            NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3 userInfo:userInfo];
            
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSString *token = result[@"oauth_token"];
        NSString *tokenSecret = result[@"oauth_token_secret"];
        
        if (![token length] || ![tokenSecret length]) {
            [self.credential setRequestToken:nil requestTokenSecret:nil];
            
            if (completion) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Missing token info in response"};
                NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:2 userInfo:userInfo];
             
                completion(NO, error);
            }
            return;
        }
        
        [self.credential setRequestToken:token requestTokenSecret:tokenSecret];
        
        if (completion) {
            completion(YES, nil);
        }
        
        /*NSString *testURL = [NSString stringWithFormat:@"%@%@?oauth_token=%@&oauth_callback=%@",self.baseURL,userAuthorizationPath,self.credential.accessToken,callBackPath];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:testURL]
                                               options:@{}
                                     completionHandler:^(BOOL success) {
                                         [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidOpenFromURL:) name:UIApplicationLaunchOptionsLocalNotificationKey object:nil];
                                         NSLog(@"open url");
                                     }];
        }];*/
        
    }];
    [task resume];
    
}

- (void)authorizedRequestPath:(NSString *)requestPath forHTTPMethod:(NSString *)httpMethod extraParameters:(NSDictionary *)extraParameters completion:(Completion)completion {
    
    NSString *requestString = [NSString stringWithFormat:@"%@%@?%@",self.configuration.baseURL,requestPath, [self stringFromParamDictionary:extraParameters]];

    NSURLRequest *request = [self authorizedRequestWithURL:[NSURL URLWithString:requestString] forHTTPMethod:httpMethod extraAuthParamaters:nil];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (error) {
            if (completion) {
                completion(nil, nil);
            }
            NSLog(@"There was an error");
            return;
        }
        
        id responseJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:NSJSONReadingMutableContainers
                                                                      error:nil];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if ([httpResponse statusCode]!=200) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : responseJSON};
                NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:1 userInfo:userInfo];
                
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Didn't receive expected HTTP response."};
            NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:3 userInfo:userInfo];
            
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        completion(responseJSON, nil);
    }];
    
    [task resume];
}

- (NSURLRequest *)authorizedRequestWithURL:(NSURL *)URL forHTTPMethod:(NSString *)httpMethod extraAuthParamaters:(NSDictionary *)extraAuthParamaters {
    NSDictionary *authParamaters = [self authrizationParamatersWithExtraParameters:extraAuthParamaters];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = httpMethod;
    
    NSString *authHeader = [self authorizationHeaderForRequest:request authParameters:authParamaters];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    return [request copy];
}


- (NSURLRequest *)authorizationRequestWithURL:(NSURL *)URL extraAuthParamaters:(NSDictionary *)extraAuthParamaters {
    NSDictionary *authParamaters = [self authrizationParamatersWithExtraParameters:extraAuthParamaters];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    NSString *authHeader = [self authorizationHeaderForRequest:request authParameters:authParamaters];
    [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    return [request copy];
}

- (NSDictionary *)authrizationParamatersWithExtraParameters:(NSDictionary *)extraParameter {
    NSMutableDictionary *authParams = [@{@"oauth_consumer_key" : [self.credential consumerKey],
                                         @"oauth_nonce" : [self nonce],
                                         @"oauth_timestamp" : [self timestamp],
                                         @"oauth_version" : @"1.0",
                                         @"oauth_signature_method" : @"HMAC-SHA1"} mutableCopy];
    
    if (self.credential.accessToken) {
        authParams[@"oauth_token"] = self.credential.accessToken;
    }
    
    if ([extraParameter count]) {
        [authParams addEntriesFromDictionary:extraParameter];
    }
    
    return [authParams copy];
}

- (NSString *)authorizationHeaderForRequest:(NSURLRequest *)request authParameters:(NSDictionary *)authParameters {
    NSMutableDictionary *signatureParameters = [NSMutableDictionary dictionaryWithDictionary:authParameters];
    
    NSDictionary *requestParams = [self parametersFromRequest:request];
    
    if ([requestParams count]) {
        [signatureParameters addEntriesFromDictionary:requestParams];
    }
    
    // mutable version of the OAuth header contents to add the signature
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:authParameters];
    
    NSString *signature = [self signatureForMethod:[request HTTPMethod]
                                             scheme:[request.URL scheme]
                                               host:[request.URL host]
                                               path:[request.URL path]
                                    signatureParams:signatureParameters];
    
    tmpDict[@"oauth_signature"] = signature;
    
    // build Authorization header
    NSMutableString *tmpStr = [NSMutableString string];
    NSArray *sortedKeys = [[tmpDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [tmpStr appendString:@"OAuth "];
    
    NSMutableArray *pairs = [NSMutableArray array];
    
    for (NSString *key in sortedKeys)
    {
        NSMutableString *pairStr = [NSMutableString string];
        
        NSString *encKey = [self urlEncodedString:key];
        NSString *encValue = [self urlEncodedString:[tmpDict objectForKey:key]];
        
        [pairStr appendString:encKey];
        [pairStr appendString:@"=\""];
        [pairStr appendString:encValue];
        [pairStr appendString:@"\""];
        
        [pairs addObject:pairStr];
    }
    
    [tmpStr appendString:[pairs componentsJoinedByString:@", "]];
    
    return [tmpStr copy];
}

- (NSDictionary *)parametersFromRequest:(NSURLRequest *)request
{
    NSMutableDictionary *extraParams = [NSMutableDictionary dictionary];
    
    NSString *query = [request.URL query];
    
    // parameters in the URL query string need to be considered for the signature
    if ([query length]) {
        [extraParams addEntriesFromDictionary:[self dictionaryFromQueryString:query]];
    }
    
    if ([request.HTTPMethod isEqualToString:@"POST"] && [request.HTTPBody length]) {
        NSString *contentType = [request allHTTPHeaderFields][@"Content-Type"];
        
        if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
            NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
            
            [extraParams addEntriesFromDictionary:[self dictionaryFromQueryString:bodyString]];
        } else {
            NSLog(@"Content-Type %@ is not what we'd expect for an OAuth-authenticated POST with a body", contentType);
        }
    }
    
    return [extraParams copy];
}

- (NSDictionary *)dictionaryFromQueryString:(NSString *)string {
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

- (NSString *)timestamp {
    NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%u", (int)t];
}

- (NSString *)nonce {
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
}

- (NSString *)urlEncodedString:(NSString *)string {
    NSMutableCharacterSet *chars = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [chars removeCharactersInString:@"!*'();:@&=+$,/?%#[]"];
    
    return     [string stringByAddingPercentEncodingWithAllowedCharacters:chars];
}

- (NSString *)stringFromParamDictionary:(NSDictionary *)dictionary {
    NSMutableArray *keyValuePairs = [NSMutableArray array];
    NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    for (NSString *key in sortedKeys) {
        NSString *encKey = [self urlEncodedString:key];
        NSString *encValue = [self urlEncodedString:[dictionary objectForKey:key]];
        
        NSString *pair = [NSString stringWithFormat:@"%@=%@", encKey, encValue];
        [keyValuePairs addObject:pair];
    }
    
    return [keyValuePairs componentsJoinedByString:@"&"];
}

- (NSString *)signatureForMethod:(NSString *)method scheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path signatureParams:(NSDictionary *)signatureParams
{
    NSString *authParamString = [self stringFromParamDictionary:signatureParams];
    NSString *signatureBase = [NSString stringWithFormat:@"%@&%@%%3A%%2F%%2F%@%@&%@",
                               [method uppercaseString],
                               [scheme lowercaseString],
                               [self urlEncodedString:[host lowercaseString]],
                               [self urlEncodedString:path],
                               [self urlEncodedString:authParamString]];
    
    NSString *signatureSecret = [NSString stringWithFormat:@"%@&%@", self.credential.consumerSecret, self.credential.accessTokenSecret ?: @""];
    NSData *sigbase = [signatureBase dataUsingEncoding:NSUTF8StringEncoding];
    NSData *secret = [signatureSecret dataUsingEncoding:NSUTF8StringEncoding];
    
    // use CommonCrypto to create a SHA1 digest
    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, secret.bytes, secret.length);
    CCHmacUpdate(&cx, sigbase.bytes, sigbase.length);
    CCHmacFinal(&cx, digest);
    
    // convert to NSData and return base64-string
    NSData *digestData = [NSData dataWithBytes:&digest length:CC_SHA1_DIGEST_LENGTH];
    return [digestData base64EncodedStringWithOptions:0];
}

@end
