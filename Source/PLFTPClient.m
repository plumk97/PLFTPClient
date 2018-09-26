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

@interface PLFTPClientCommand ()
@property (nonatomic, copy) NSString * workDirectory;
@end
@implementation PLFTPClientCommand
@synthesize command = _command;
@synthesize content = _content;
@synthesize responseContent = _responseContent;
- (instancetype)initWithCommand:(PLFTPClientEnumCommand)command content:(NSString *)content {
    self = [super init];
    if (self) {
        _command = command;
        _content = [content copy];
    }
    return self;
}

- (void)setResponseContent:(NSString *)responseContent {
    _responseContent = [responseContent copy];
}

- (NSString *)commandString {
    switch (self.command) {
        case PLFTPClientEnumCommand_TYPE:
            return @"TYPE";
        case PLFTPClientEnumCommand_PASS:
            return @"PASS";
        case PLFTPClientEnumCommand_PASV:
            return @"PASV";
        case PLFTPClientEnumCommand_USER:
            return @"USER";
        case PLFTPClientEnumCommand_OPTS:
            return @"OPTS";
        case PLFTPClientEnumCommand_MLSD:
            return @"MLSD";
        case PLFTPClientEnumCommand_CWD:
            return @"CWD";
        case PLFTPClientEnumCommand_CDUP:
            return @"CDUP";
        case PLFTPClientEnumCommand_PWD:
            return @"PWD";
        case PLFTPClientEnumCommand_DELE:
            return @"DELE";
        case PLFTPClientEnumCommand_RMD:
            return @"RMD";
        case PLFTPClientEnumCommand_MKD:
            return @"MKD";
        case PLFTPClientEnumCommand_STOR:
            return @"STOR";
        case PLFTPClientEnumCommand_SIZE:
            return @"SIZE";
        case PLFTPClientEnumCommand_QUIT:
            return @"QUIT";
        default:
            break;
    }
    return nil;
}

- (NSString *)makeCompleteCommandString {
    
    NSString * content = self.content;
    switch (self.command) {
        case PLFTPClientEnumCommand_MLSD:
            content = self.workDirectory ? self.workDirectory : @"/";
            break;
        case PLFTPClientEnumCommand_STOR:
            content = [content lastPathComponent];
            break;
        default:
            break;
    }
    
    NSString * string = [self commandString];
    if (content == nil) {
        string = [string stringByAppendingString:@" \r\n"];
    } else {
        string = [string stringByAppendingFormat:@" %@\r\n", content];
    }
    return string;
}

- (NSString *)description {
    
    NSString * desc = [[NSString alloc] initWithFormat:@"<PLFTPClientCommand: %p>\ncommand:\t%@\ncontent:\t%@\nresponseContent:\t%@", self, [self commandString], self.content, self.responseContent];
    return desc;
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
@synthesize port = _port;
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error {
    _host = [host copy];
    _port = port;
    self.commSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_commSocketQueue];
    [self.commSocket connectToHost:host onPort:port withTimeout:10 error:error];
}

- (void)login {
    [self sendCommand:PLFTPClientEnumCommand_USER content:self.username];
}


// MARK: - Commands
@synthesize currentDirectory = _currentDirectory;
@synthesize fileSize = _fileSize;

/**
 发送FTP 命令
 
 @param command PLFTPClientEnumCommand
 @param content NSString
 */
- (void)sendCommand:(PLFTPClientEnumCommand)command content:(NSString *)content {
    if (self.commSocket.isConnected) {
        
        if (command == PLFTPClientEnumCommand_MLSD ||
            command == PLFTPClientEnumCommand_STOR) {
            [self sendCommand:PLFTPClientEnumCommand_PASV content:nil];
        }
        
        PLFTPClientCommand * c = [[PLFTPClientCommand alloc] initWithCommand:command content:content];
        [self.commandQueues addObject:c];
        [self executeCommand];
    }
}

- (void)executeCommand {
    if (self.isWaitResponse) return;
    
    PLFTPClientCommand * command = [self.commandQueues firstObject];
    if (command) {
        command.workDirectory = self.currentDirectory;
        NSString * compleCommand = [command makeCompleteCommandString];
        if (compleCommand) {
            PLFTPLog(@"send: %@", compleCommand);
            self.isWaitResponse = YES;
            [self.commSocket writeData:[compleCommand dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10 tag:0];
        } else {
            [self nextCommand];
        }
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
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    PLFTPLog(@"%@", [data string]);
    [sock readDataWithTimeout:-1 tag:tag + 1];
    if (sock == self.commSocket) {
        if ([self handleCommResponseData:data] && self.dataTransfer == nil && tag > 0) {
            [self nextCommand];
        }
    }
    
}

- (BOOL)handleCommResponseData:(NSData *)data {
    NSString * responseStr = [data string];
    if (responseStr.length < 3) {
        return YES;
    }
    
    BOOL isAutoNext = YES;
    PLFTPClientCommand * command = [self.commandQueues firstObject];
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
        // - 213 89408779 ::文件大小
        case 213: {
            _fileSize = [content integerValue];
            command.responseContent = content;
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:completeCommand:)]) {
                [self.delegate ftpclient:self completeCommand:command];
            }
        }
            break;
        // - 欢迎语句
        case 220: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:didConnectToHost:port:)]) {
                [self.delegate ftpclient:self didConnectToHost:self.host port:self.port];
            }
        }
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
                if (command.command == PLFTPClientEnumCommand_MLSD) {
                } else if (command.command == PLFTPClientEnumCommand_STOR) {
                    transferType = PLFTPDataTransferType_STOR;
                }
                
                PLFTPClientDataTransfer * transfer = [[PLFTPClientDataTransfer alloc] initWithHost:self.host pasvPort:port transferType:transferType];
                
                if (transferType == PLFTPDataTransferType_STOR) {
                    transfer.sendFile = command.content;
                }
                
                __weak __typeof(self) weakSelf = self;
                [transfer setProgressBlock:^(float progress, PLFTPClientDataTransfer *transfer) {
                    __strong __typeof(weakSelf) self = weakSelf;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:transferingProgress:transferType:)]) {
                        [self.delegate ftpclient:self transferingProgress:progress transferType:transfer.type];
                    }
                }];
                
                [transfer setCompleteBlock:^(NSError *error, NSData *data, PLFTPClientDataTransfer * transfer) {
                    __strong __typeof(weakSelf) self = weakSelf;
                    if (error.code == 7 || error == nil) {
                        // 服务器主动断开 代表数据传输完成/自己主动断开 上传文件完成
                        error = nil;
                    } else {
                        PLFTPLog(@"%@", error);
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:transferredData:transferType:error:)]) {
                        [self.delegate ftpclient:self transferredData:data transferType:transfer.type error:error];
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
            [self sendCommand:PLFTPClientEnumCommand_OPTS content:@"UTF8 ON"];
            [self sendCommand:PLFTPClientEnumCommand_TYPE content:@"I"];
            if (self.delegate && [self.delegate respondsToSelector:@selector(ftpclient:loginIsSucceed:statusCode:)]) {
                [self.delegate ftpclient:self loginIsSucceed:YES statusCode:code];
            }
        }
            break;
            
        // - RMD/CWD/PWD/MKD
        case 250:
        case 257: {
            
            if ([content hasSuffix:@"is the current directory.\r\n"]) {
                NSString * dir = [self fetchPathWithContent:content];
                if (dir) {
                    _currentDirectory = dir;
                }
            }
        }
            break;
        // - 331 Password required
        case 331:
            [self sendCommand:PLFTPClientEnumCommand_PASS content:self.password];
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
        case 501:
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
