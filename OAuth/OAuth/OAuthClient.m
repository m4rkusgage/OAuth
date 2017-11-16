//
//  OAuthClient.m
//  OAuth
//
//  Created by Markus Gage on 2017-11-08.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonHMAC.h>
#import "OAuthClient.h"
#import "OAuthCredential.h"
#import "OAuthConfiguration.h"
#import "NSDictionary+OAuth.h"
#import "NSString+OAuth.h"

@interface OAuthClient ()
@property (strong, nonatomic) OAuthCredential *credential;
@property (strong, nonatomic) OAuthConfiguration *configuration;
@end

@implementation OAuthClient

 static OAuthClient *_sharedInstance = nil;

+ (OAuthClient *)sharedInstance {
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
    
    [self.configuration setRequestTokenPath:requestTokenPath
                          authorizationPath:userAuthorizationPath
                            accessTokenPath:accessTokenPath];
    self.configuration.callBackURLString = callBackPath;
    
    NSURL *requestTokenURL = [NSURL URLWithString:[self.configuration requestTokenURLString]];
    
    NSDictionary *extraAuthParamaters;
    if (callBackPath) {
        extraAuthParamaters = @{@"oauth_callback" : callBackPath};
    }
    
    
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
        
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *result = [NSDictionary dictionaryFromQueryString:dataString];
        
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
    }];
    [task resume];
    
}

- (void)authorizedRequestPath:(NSString *)requestPath forHTTPMethod:(NSString *)httpMethod extraParameters:(NSDictionary *)extraParameters completion:(Completion)completion {
    
    NSString *requestString = [NSString stringWithFormat:@"%@%@?%@",self.configuration.baseURL,requestPath, [NSString stringFromDictionary:extraParameters]];

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
                                         @"oauth_nonce" : [NSString nonce],
                                         @"oauth_timestamp" : [NSString timestampString],
                                         @"oauth_version" : @"1.0",
                                         @"oauth_signature_method" : @"HMAC-SHA1"} mutableCopy];
    
    if (self.credential.token) {
        authParams[@"oauth_token"] = self.credential.token;
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
        
        NSString *encKey = [NSString stringFromUrlEncodedString:key];
        NSString *encValue = [NSString stringFromUrlEncodedString:[tmpDict objectForKey:key]];
        
        [pairStr appendString:encKey];
        [pairStr appendString:@"=\""];
        [pairStr appendString:encValue];
        [pairStr appendString:@"\""];
        
        [pairs addObject:pairStr];
    }
    
    [tmpStr appendString:[pairs componentsJoinedByString:@", "]];
    
    return [tmpStr copy];
}

- (void)authorize {
    NSString *authorizeURLString = [NSString stringWithFormat:@"%@?oauth_token=%@", [self.configuration authorizationURLString],self.credential.token];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:authorizeURLString]
                                       options:@{}
                             completionHandler:^(BOOL success) {}];
}

- (void)authorizationOpenFromURL:(NSURL *)authURL completion:(Success)completion {
    NSString *callbackScheme = [self.configuration.callBackURLString stringByReplacingOccurrencesOfString:@"//" withString:@"?"];
    NSString *query = [[authURL absoluteString] stringByReplacingOccurrencesOfString:callbackScheme withString:@""];

    NSMutableDictionary *paramaeters = [[NSDictionary dictionaryFromQueryString:query] mutableCopy];
    if (paramaeters) {
        NSURL *accessTokenURL = [NSURL URLWithString:[self.configuration accessTokenURLString]];
        
        NSURLRequest *request = [self authorizationRequestWithURL:accessTokenURL extraAuthParamaters:paramaeters];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error) {
                if (completion) {
                    completion(NO, error);
                }
                NSLog(@"There was an error");
                return;
            }
            
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *responseDictionary = [NSDictionary dictionaryFromQueryString:dataString];
            
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                if ([httpResponse statusCode]!=200) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : dataString};
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
            
            NSString *token = responseDictionary[@"oauth_token"];
            NSString *tokenSecret = responseDictionary[@"oauth_token_secret"];
            
            if (![token length] || ![tokenSecret length]) {
                [self.credential setRequestToken:nil requestTokenSecret:nil];
                
                if (completion) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Missing token info in response"};
                    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:2 userInfo:userInfo];
                    
                    completion(NO, error);
                }
                return;
            }
            
            [self.credential setAccessToken:token accessTokenSecret:tokenSecret];
            completion(YES, nil);
        }];
        
        [task resume];
    }
}

- (NSDictionary *)parametersFromRequest:(NSURLRequest *)request
{
    NSMutableDictionary *extraParams = [NSMutableDictionary dictionary];
    
    NSString *query = [request.URL query];
    
    // parameters in the URL query string need to be considered for the signature
    if ([query length]) {
        [extraParams addEntriesFromDictionary:[NSDictionary dictionaryFromQueryString:query]];
    }
    
    if ([request.HTTPMethod isEqualToString:@"POST"] && [request.HTTPBody length]) {
        NSString *contentType = [request allHTTPHeaderFields][@"Content-Type"];
        
        if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
            NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
            
            [extraParams addEntriesFromDictionary:[NSDictionary dictionaryFromQueryString:bodyString]];
        } else {
            NSLog(@"Content-Type %@ is not what we'd expect for an OAuth-authenticated POST with a body", contentType);
        }
    }
    
    return [extraParams copy];
}

- (NSString *)signatureForMethod:(NSString *)method scheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path signatureParams:(NSDictionary *)signatureParams
{
    NSString *authParamString = [NSString stringFromDictionary:signatureParams];
    NSString *signatureBase = [NSString stringWithFormat:@"%@&%@%%3A%%2F%%2F%@%@&%@",
                               [method uppercaseString],
                               [scheme lowercaseString],
                               [NSString stringFromUrlEncodedString:[host lowercaseString]],
                               [NSString stringFromUrlEncodedString:path],
                               [NSString stringFromUrlEncodedString:authParamString]];
    
    NSString *signatureSecret = [NSString stringWithFormat:@"%@&%@", self.credential.consumerSecret, self.credential.tokenSecret ?: @""];
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
