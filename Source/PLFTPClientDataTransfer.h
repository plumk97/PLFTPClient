//
//  PLFTPClientDataTransfer.h
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/23.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLFTPClientConfig.h"

@interface PLFTPClientDataTransfer : NSObject

@property (nonatomic, readonly) NSString * host;
@property (nonatomic, readonly) NSUInteger port;
@property (nonatomic, readonly) PLFTPClientEnumCommand command;

@property (nonatomic, copy) void (^progressBlock) (float progress, PLFTPClientDataTransfer * transfer);
@property (nonatomic, copy) void (^completeBlock) (NSError * error, NSData * data, PLFTPClientDataTransfer * transfer);
    
- (instancetype)initWithHost:(NSString *)host pasvPort:(NSUInteger)pasvPort command:(PLFTPClientEnumCommand)command;
    
- (void)startTransfer;
- (void)stopTransfer;

@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, copy) NSString * sendFile;
@property (nonatomic, copy) NSString * saveFile;
@end
