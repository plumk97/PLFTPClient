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
    
    self.ftpclient = [[PLFTPClient alloc] initWithUsername:@"admin" password:nil];
    self.ftpclient.delegate = self;
    
    NSError * error;
    [self.ftpclient connectToHost:@"192.168.3.3" port:21 error:&error];
    NSLog(@"%@", error);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
