//
//  PLFTPClient.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "PLFTPClient.h"
#import "PLFTPClientDataTransfer.h"
#import "PLFTPLog.h"

#import "GCDAsyncSocket.h"
#import "NSData+PLCSTR.h"

@interface PLFTPClient () <GCDAsyncSocketDelegate> {
    dispatch_queue_t _commSocketQueue;
}

@property (nonatomic, strong) GCDAsyncSocket * commSocket;

@property (nonatomic, assign) BOOL isWaitResponse;
@property (nonatomic, strong) NSMutableArray <NSString *> * commandQueues;
@property (nonatomic, strong) NSMutableArray <PLFTPClientDataTransfer *> * dataTransfers;
@end

@implementation PLFTPClient
@synthesize
username = _username,
password = _password,
isLogined = _isLogined;

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [self init];
    if (self) {
        
        _commSocketQueue = dispatch_queue_create("PLFTPClient_COMM", DISPATCH_QUEUE_SERIAL);
        
        _username = username;
        _password = password;
        
        _commandQueues = [[NSMutableArray alloc] init];
        _dataTransfers = [[NSMutableArray alloc] init];
    }
    return self;
}

// MARK: - Connect
@synthesize host = _host;
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error {
    _host = [host copy];
    self.commSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_commSocketQueue];
    [self.commSocket connectToHost:host onPort:port withTimeout:10 error:error];
}


// MARK: - Commands
- (void)sendCommand:(NSString *)command content:(NSString *)content {
    if (self.commSocket.isConnected) {
        
        NSString * compleCommand = nil;
        if (content == nil) {
            compleCommand = [command stringByAppendingString:@" \r\n"];
        } else {
            compleCommand = [command stringByAppendingFormat:@" %@\r\n", content];
        }
        
        [self.commandQueues addObject:compleCommand];
        [self executeCommand];
    }
}

- (void)executeCommand {
    if (self.isWaitResponse) return;
    
    NSString * command = [self.commandQueues firstObject];
    if (command) {
        PLFTPLog(@"send: %@", command);
        self.isWaitResponse = YES;
        [self.commSocket writeData:[command dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
    }
}

- (void)nextCommand {
    if (self.commandQueues.count > 0) {
        [self.commandQueues removeObjectAtIndex:0];
    }
    self.isWaitResponse = NO;
    [self executeCommand];
}

// MARK: - GCDAsyncSocketDelegate
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
    if (sock == self.commSocket) {
        PLFTPLog(@"%@", err);
        if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclientDisconnect:withError:)]) {
            [self.delegate ftpclientDisconnect:self withError:err];
        }
        return;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    if (sock == self.commSocket) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:didConnectToHost:port:)]) {
            [self.delegate ftpclient:self didConnectToHost:host port:port];
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    PLFTPLog(@"%@", [data string]);
    if (sock == self.commSocket) {
        [self handleCommResponseData:data];
    }
    [sock readDataWithTimeout:-1 tag:tag + 1];
}

- (void)handleCommResponseData:(NSData *)data {
    NSString * responseStr = [data string];
    if (responseStr.length < 3) {
        return;
    }
    
    [self nextCommand];
    NSString * command = [self.commandQueues firstObject];
    
    NSInteger code = [[responseStr substringToIndex:3] integerValue];
    NSString * content = [responseStr substringFromIndex:4];
    switch (code) {
        case 220:
            [self sendCommand:@"USER" content:self.username];
            break;
        case 226:
            break;
        case 227: {
            NSRange range = [content rangeOfString:@"(?<=\\().*(?=\\))" options:NSRegularExpressionSearch];
            if (range.length > 0) {
                NSString * ipaddr = [content substringWithRange:range];
                NSArray * parts = [ipaddr componentsSeparatedByString:@","];
                
                NSUInteger port = [[parts objectAtIndex:parts.count - 2] integerValue] * 256 + [[parts objectAtIndex:parts.count - 1] integerValue];
                
                PLFTPClientDataTransfer * transfer = [[PLFTPClientDataTransfer alloc] initWithHost:self.host pasvPort:port transferType:PLFTPDataTransferType_MLSD];
                [transfer setCompleteBlock:^(NSError *error, NSData *data) {
                    if (error.code == 7) {
                        // 服务器主动断开 代表数据传输完成
                        PLFTPLog(@"%@", command);
                        PLFTPLog(@"%@", [data string]);
                    } else {
                        PLFTPLog(@"%@", error);
                    }
                }];
                [transfer startTransfer];
                [self.dataTransfers addObject:transfer];
            }
        }
            break;
        case 230: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:loginIsSucceed:statusCode:)]) {
                [self.delegate ftpclient:self loginIsSucceed:YES statusCode:code];
            }
            [self sendCommand:@"PASV" content:nil];
            [self sendCommand:@"MLSD" content:@"/"];
        }
            break;
            
        case 331:
            [self sendCommand:@"PASS" content:self.password];
            break;
            
        case 530: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:loginIsSucceed:statusCode:)]) {
                [self.delegate ftpclient:self loginIsSucceed:NO statusCode:code];
            }
        }
            break;
            
        default:
            break;
    }
}


- (void)handleDataResponseData:(NSData *)data {
    NSLog(@"%@", [self.commandQueues firstObject]);
}


@end
