//
//  ViewController.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "ViewController.h"
#import "PLFTPClient.h"

@interface ViewController () <PLFTPClientDelegate>
@property (nonatomic, strong) PLFTPClient * ftpclient;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.ftpclient = [[PLFTPClient alloc] initWithUsername:@"user" password:@"12345"];
    self.ftpclient.delegate = self;
    
    NSError * error;
    [self.ftpclient connectToHost:@"127.0.0.1" port:2121 error:&error];
    NSLog(@"%@", error);
}

// MARK: - PLFTPClientDelegate
- (void)ftpclientDisconnect:(PLFTPClient *)client withError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)ftpclient:(PLFTPClient *)client didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%s", _cmd);
}

- (void)ftpclient:(PLFTPClient *)client loginIsSucceed:(BOOL)isSucceed statusCode:(NSUInteger)statusCode {
    NSLog(@"login: %d: %d", isSucceed, statusCode);
}



@end
