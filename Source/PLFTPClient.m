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

@interface PLFTPClientCommand : NSObject
@property (nonatomic, copy) NSString * command;
@property (nonatomic, copy) NSString * content;

- (instancetype)initWithCommand:(NSString *)command content:(NSString *)content;
@end
@implementation PLFTPClientCommand
- (instancetype)initWithCommand:(NSString *)command content:(NSString *)content {
    self = [super init];
    if (self) {
        self.command = command;
        self.content = content;
    }
    return self;
}
@end

@interface PLFTPClient () <GCDAsyncSocketDelegate> {
    dispatch_queue_t _commSocketQueue;
}

@property (nonatomic, strong) GCDAsyncSocket * commSocket;
@property (nonatomic, strong) PLFTPClientDataTransfer * dataTransfer;

@property (nonatomic, assign) BOOL isWaitResponse;
@property (nonatomic, strong) NSMutableArray <PLFTPClientCommand *> * commandQueues;
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

- (void)login {
    [self sendCommand:@"USER" content:self.username];
}


// MARK: - Commands
@synthesize currentDirectory = _currentDirectory;
- (void)sendCommand:(NSString *)command content:(NSString *)content {
    if (self.commSocket.isConnected) {
        
        PLFTPClientCommand * c = [[PLFTPClientCommand alloc] initWithCommand:command content:content];
        [self.commandQueues addObject:c];
        [self executeCommand];
    }
}

- (void)executeCommand {
    if (self.isWaitResponse) return;
    /*
     if (path == nil) {
     path = self.currentDirectory ? self.currentDirectory : @"/";
     }
     */
    
    PLFTPClientCommand * command = [self.commandQueues firstObject];
    if (command) {
        
        NSString * compleCommand = nil;
        NSString * content = command.content;
        
        if (content == nil && [command.command isEqualToString:@"MLSD"]) {
            content = self.currentDirectory ? self.currentDirectory : @"/";
        } else if ([command.command isEqualToString:@"STOR"]) {
            content = [command.content lastPathComponent];
        }
        
        if (content == nil) {
            compleCommand = [command.command stringByAppendingString:@" \r\n"];
        } else {
            compleCommand = [command.command stringByAppendingFormat:@" %@\r\n", content];
        }
        
        PLFTPLog(@"send: %@", compleCommand);
        self.isWaitResponse = YES;
        [self.commSocket writeData:[compleCommand dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
    }
}

- (void)nextCommand {
    if (self.commandQueues.count > 0) {
        [self.commandQueues removeObjectAtIndex:0];
    }
    self.isWaitResponse = NO;
    [self executeCommand];
}

/**
 列出目录下文件
 
 @param path 目录路径
 */
- (void)MLSD:(NSString *)path {
    [self sendCommand:@"PASV" content:nil];
    [self sendCommand:@"MLSD" content:path];
}

/**
 切换目录
 
 @param path 目录路径
 */
- (void)CWD:(NSString *)path {
    [self sendCommand:@"CWD" content:path];
    [self MLSD:nil];
}

/**
 返回上级目录
 */
- (void)CDUP {
    [self sendCommand:@"CDUP" content:nil];
    [self MLSD:nil];
}

/**
 打印当前工作目录
 */
- (void)PWD {
    [self sendCommand:@"PWD" content:nil];
}

/**
 删除文件
 
 @param file 文件路径
 */
- (void)DELE:(NSString *)file {
    if (file == nil) {
        return;
    }
    [self sendCommand:@"DELE" content:file];
}

/**
 删除目录
 
 @param dir 目录路径
 */
- (void)RMD:(NSString *)dir {
    if (dir == nil) {
        return;
    }
    [self sendCommand:@"RMD" content:dir];
}

/**
 创建目录
 
 @param name 目录名
 */
- (void)MKD:(NSString *)name {
    if (name == nil) {
        return;
    }
    [self sendCommand:@"MKD" content:name];
}

/**
 上传文件
 
 @param file 本地文件路径
 */
- (void)STOR:(NSString *)file {
    if (file == nil) {
        return;
    }
    [self sendCommand:@"PASV" content:nil];
    [self sendCommand:@"STOR" content:file];
}

/**
 退出FTP
 */
- (void)QUIT {
    [self sendCommand:@"QUIT" content:nil];
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
        if ([self handleCommResponseData:data] && self.dataTransfer == nil) {
            [self nextCommand];
        }
    }
    [sock readDataWithTimeout:-1 tag:tag + 1];
}

- (BOOL)handleCommResponseData:(NSData *)data {
    NSString * responseStr = [data string];
    if (responseStr.length < 3) {
        return YES;
    }
    
    BOOL isAutoNext = YES;
//    PLFTPClientCommand * command = [self.commandQueues firstObject];
    NSInteger code = [[responseStr substringToIndex:3] integerValue];
    NSString * content = [responseStr substringFromIndex:4];
    switch (code) {
        // - 150 Opening data channel
        case 150:
            break;
        // - 200 CDUP successful.
        case 200:
            _currentDirectory = [self fetchPathWithContent:content];
            break;
        // - 欢迎语句
        case 220:
            break;
        // -- 226 Successfully transferred
        case 226:
            break;
        // - 227 Entering Passive Mode
        case 227: {
            
            NSRange range = [content rangeOfString:@"(?<=\\().*(?=\\))" options:NSRegularExpressionSearch];
            if (range.length > 0) {
                NSString * ipaddr = [content substringWithRange:range];
                NSArray * parts = [ipaddr componentsSeparatedByString:@","];
                
                NSUInteger port = [[parts objectAtIndex:parts.count - 2] integerValue] * 256 + [[parts objectAtIndex:parts.count - 1] integerValue];
                
                if (self.commandQueues.count < 2) {
                    // 只发送了PASV命名 没有后续
                    break;
                }
                
                PLFTPClientCommand * command = [self.commandQueues objectAtIndex:1];
                
                PLFTPDataTransferType transferType = PLFTPDataTransferType_MLSD;
                if ([command.command isEqualToString:@"MLSD"]) {
                } else if ([command.command isEqualToString:@"STOR"]) {
                    transferType = PLFTPDataTransferType_STOR;
                }
                
                PLFTPClientDataTransfer * transfer = [[PLFTPClientDataTransfer alloc] initWithHost:self.host pasvPort:port transferType:transferType];
                
                if (transferType == PLFTPDataTransferType_STOR) {
                    transfer.sendFile = command.content;
                }
                
                __weak __typeof(self) weakSelf = self;
                [transfer setCompleteBlock:^(NSError *error, NSData *data, PLFTPClientDataTransfer * transfer) {
                    __strong __typeof(weakSelf) self = weakSelf;
                    if (error.code == 7 || error == nil) {
                        // 服务器主动断开 代表数据传输完成/自己主动断开 上传文件完成
                        if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:transferredData:transferType:)]) {
                            [self.delegate ftpclient:self transferredData:data transferType:transfer.type];
                        }
                    } else {
                        PLFTPLog(@"%@", error);
                    }
                    self.dataTransfer = nil;
                    [self nextCommand];
                }];
                self.dataTransfer = transfer;
                [transfer startTransfer];
                [self nextCommand];
                isAutoNext = NO;
                
            }
        }
            break;
        // - 230 Logged on
        case 230: {
            [self sendCommand:@"OPTS" content:@"UTF8 ON"];
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:loginIsSucceed:statusCode:)]) {
                [self.delegate ftpclient:self loginIsSucceed:YES statusCode:code];
            }
        }
            break;
            
        // - RMD/CWD/PWD
        case 250:
        case 257: {
            NSString * dir = [self fetchPathWithContent:content];
            if (dir) {
                _currentDirectory = dir;
            }
        }
            break;
        // - 331 Password required
        case 331:
            [self sendCommand:@"PASS" content:self.password];
            break;
            
        // - 421 Connection timed out.
        // - 425 Can't open data connection
        case 421:
        case 425: {
            if (self.dataTransfer) {
                self.dataTransfer = nil;
            }
        }
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
    
    return isAutoNext;
}

- (NSString *)fetchPathWithContent:(NSString *)content {
    
    NSRange range = [content rangeOfString:@"\".*\"" options:NSRegularExpressionSearch];
    if (range.length > 0) {
        range.location += 1;
        range.length -= 2;
        return [content substringWithRange:range];
    }
    
    return nil;
}

@end
