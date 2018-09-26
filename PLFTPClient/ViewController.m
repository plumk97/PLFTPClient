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
    
    self.ftpclient = [[PLFTPClient alloc] initWithUsername:@"ftpuser" password:@"123456"];
//    self.ftpclient = [[PLFTPClient alloc] initWithUsername:@"user" password:@"12345"];
    self.ftpclient.delegate = self;
    
    NSError * error;
    [self.ftpclient connectToHost:@"192.168.3.3" port:21 error:&error];
//    [self.ftpclient connectToHost:@"127.0.0.1" port:5521 error:&error];
    NSLog(@"%@", error);
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.ftpclient sendCommand:PLFTPClientEnumCommand_MLSD content:nil];
//    [self.ftpclient sendCommand:PLFTPClientEnumCommand_RETR content:@"安安.ipa"];
//    [self.ftpclient sendCommand:PLFTPClientEnumCommand_SIZE content:@"安安.ipa"];
    [self.ftpclient sendCommand:PLFTPClientEnumCommand_STOR content:@"/Users/litiezhu/Downloads/测试.dmg"];
}

// MARK: - PLFTPClientDelegate
- (void)ftpclientDisconnect:(PLFTPClient *)client withError:(NSError *)error {
    NSLog(@"%@", error);
}

- (void)ftpclient:(PLFTPClient *)client didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%s", _cmd);
    [client login];
}

- (void)ftpclient:(PLFTPClient *)client loginIsSucceed:(BOOL)isSucceed statusCode:(NSUInteger)statusCode {
    NSLog(@"login: %d: %d", isSucceed, statusCode);
}

- (void)ftpclient:(PLFTPClient *)client transferingProgress:(float)progress command:(PLFTPClientEnumCommand)command {
    printf("transfering: %f\n", progress);
}

- (void)ftpclient:(PLFTPClient *)client transferredData:(NSData *)data command:(PLFTPClientEnumCommand)command error:(NSError *)error {
    
    if (error) {
        NSLog(@"%@", error);
    }
    switch (command) {
        case PLFTPClientEnumCommand_MLSD: {
            NSString * str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            PLFTPLog(@"%@", str);
        }
            break;
        case PLFTPClientEnumCommand_STOR: {
            PLFTPLog(@"上传完成");
        }
            break;
        default:
            break;
    }
}



@end
