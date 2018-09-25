//
//  PLFTPClientDataTransfer.h
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/23.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PLFTPDataTransferType) {
    PLFTPDataTransferType_MLSD,
    PLFTPDataTransferType_STOR
};

@interface PLFTPClientDataTransfer : NSObject

@property (nonatomic, readonly) NSString * host;
@property (nonatomic, readonly) NSUInteger port;
@property (nonatomic, readonly) PLFTPDataTransferType type;
@property (nonatomic, copy) void (^completeBlock) (NSError * error, NSData * data, PLFTPClientDataTransfer * transfer);
    
- (instancetype)initWithHost:(NSString *)host pasvPort:(NSUInteger)pasvPort transferType:(PLFTPDataTransferType)transferType;
    
- (void)startTransfer;
- (void)stopTransfer;

@property (nonatomic, copy) NSString * sendFile;
@end
