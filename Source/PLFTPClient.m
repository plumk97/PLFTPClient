//
//  PLFTPClient.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "PLFTPClient.h"
#import "GCDAsyncSocket.h"
#import "NSData+PLCSTR.h"
#import "PLFTPLog.h"

@interface PLFTPClient () <GCDAsyncSocketDelegate> {
    
    dispatch_queue_t _commSocketQueue;
}
@property (nonatomic, strong) GCDAsyncSocket * commSocket;
@property (nonatomic, strong) GCDAsyncSocket * dataSocket;
@end

@implementation PLFTPClient
@synthesize
username = _username,
password = _password,
isLogined = _isLogined;
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [self init];
    if (self) {
        
        _commSocketQueue = dispatch_queue_create("PLFTPClient_Comm", DISPATCH_QUEUE_SERIAL);
        
        _username = username;
        _password = password;
    }
    return self;
}

// MARK: - Connect
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error {
    self.commSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_commSocketQueue];
    [self.commSocket connectToHost:host onPort:port withTimeout:10 error:error];
}

// MARK: - Comm
- (void)sendCommand:(NSString *)command content:(NSString *)content {
    if (self.commSocket.isConnected) {
        
        NSData * data = nil;
        if (content == nil) {
            data = [[command stringByAppendingString:@" \r\n"] dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            data = [[command stringByAppendingFormat:@" %@\r\n", content] dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [self.commSocket writeData:data withTimeout:10 tag:0];
    }
}

// MARK: - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (sock == self.commSocket) {
        [sock readDataWithTimeout:-1 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock == self.commSocket) {
        PLFTPLog(@"%@", [data string]);
        [self handleCommResponseData:data];
//        if (tag == 0) {
//            [self sendCommand:@"USER" content:self.username];
//        } else {
//
//        }
    }
    [sock readDataWithTimeout:-1 tag:tag + 1];
}

- (void)handleCommResponseData:(NSData *)data {
    NSString * responseStr = [data string];
    if (responseStr.length < 3) {
        return;
    }
    
    NSInteger code = [[responseStr substringToIndex:3] integerValue];
    NSString * content = [responseStr substringFromIndex:4];
    switch (code) {
        case 220:
            [self sendCommand:@"USER" content:self.username];
            break;
        case 227:
            break;
        case 230:
            [self sendCommand:@"PASV" content:nil];
            break;
            
        case 331:
            [self sendCommand:@"PASS" content:self.password];
            break;
            
        default:
            break;
    }
}


@end
