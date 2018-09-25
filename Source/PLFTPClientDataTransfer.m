//
//  PLFTPClientDataTransfer.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/23.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "PLFTPClientDataTransfer.h"
#import "GCDAsyncSocket.h"

@interface PLFTPClientDataTransfer () <GCDAsyncSocketDelegate> {
    dispatch_queue_t _socketDelegateQueue;
}

@property (nonatomic, strong) NSMutableData * mData;
@property (nonatomic, strong) GCDAsyncSocket * sockt;

@property (nonatomic, strong) NSFileHandle * fileHandle;
@end

@implementation PLFTPClientDataTransfer
@synthesize host = _host;
@synthesize port = _port;
@synthesize type = _type;
    
- (instancetype)initWithHost:(NSString *)host pasvPort:(NSUInteger)pasvPort transferType:(PLFTPDataTransferType)transferType {
    
    self = [super init];
    if (self) {
        _host = [host copy];
        _port = pasvPort;
        _type = transferType;
        
        _mData = [[NSMutableData alloc] init];
        _socketDelegateQueue = dispatch_queue_create(NULL, NULL);
    }
    return self;
}
    
- (void)startTransfer {
    if (_sockt != nil) {
        return;
    }
    
    _sockt = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketDelegateQueue];
    
    NSError * error = nil;
    [_sockt connectToHost:self.host onPort:self.port error:&error];
    if (error) {
        _sockt = nil;
        if (self.completeBlock) {
            self.completeBlock(error, nil, self);
        }
    }
}

- (void)stopTransfer {
    [_sockt disconnect];
    _sockt = nil;
}


// MARK: - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [sock readDataWithTimeout:-1 tag:0];
    
    if (self.sendFile && self.type == PLFTPDataTransferType_STOR) {
        self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.sendFile];
        NSData * data = [self.fileHandle readDataOfLength:512];
        [sock writeData:data withTimeout:20 tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (self.type == PLFTPDataTransferType_STOR) {
        NSData * data = [self.fileHandle readDataOfLength:512];
        if (data.length <= 0) {
            [sock disconnect];
            return;
        }
        [sock writeData:data withTimeout:20 tag:tag + 1];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    [self.mData appendData:data];
    [sock readDataWithTimeout:-1 tag:tag + 1];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (self.completeBlock) {
        self.completeBlock(err, self.mData, self);
    }
}

@end
