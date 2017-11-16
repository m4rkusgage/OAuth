//
//  ViewController.m
//  Example-500px
//
//  Created by Markus Gage on 2017-11-14.
//  Copyright © 2017 Mark Gage. All rights reserved.
//

#import "ViewController.h"
#import "OAuth.h"

@interface ViewController ()
@property (strong, nonatomic) OAuthClient *client;
@end

@implementation ViewController

- (OAuthClient *)client {
    if (!_client) {
        _client = [OAuthClient sharedInstance];
    }
    return _client;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *parameters = @{@"feature" : @"popular",
                                 @"sort" : @"created_at",
                                 @"image_size" : @"4",
                                 @"rpp" : @"100",
                                 @"include_states" : @"1",
                                 @"page" : @"1"
                                 };
    
    [self.client authorizedRequestPath:@"/photos" forHTTPMethod:@"GET" extraParameters:parameters completion:^(id result, NSError *error) {
        NSDictionary *results = (NSDictionary *)result;
        NSLog(@"%@",results[@"photos"]);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)authorizeButtonPressed:(id)sender {
    [self.client authorize];
}


@end
