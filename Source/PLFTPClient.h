//
//  PLFTPClient.h
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PLFTPClientDelegate;
@interface PLFTPClient : NSObject

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) NSString * username;
@property (nonatomic, readonly) NSString * password;
@property (nonatomic, readonly) BOOL isLogined;

@property (nonatomic, weak) id <PLFTPClientDelegate> delegate;

// MARK: - Connect
@property (nonatomic, readonly) NSString * host;
/** 服务器编码 */
@property (nonatomic, readonly) NSString * serverEncoding;
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;

// MARK: - Commands
- (void)sendCommand:(NSString *)command content:(NSString *)content;

@end


@protocol PLFTPClientDelegate <NSObject>
@optional

- (void)ftpclientDisconnect:(PLFTPClient *)client withError:(NSError *)error;
- (void)ftpclient:(PLFTPClient *)client didConnectToHost:(NSString *)host port:(uint16_t)port;

- (void)ftpclient:(PLFTPClient *)client loginIsSucceed:(BOOL)isSucceed statusCode:(NSInteger)statusCode;
@end
