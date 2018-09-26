//
//  PLFTPClient.h
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLFTPClientDataTransfer.h"
#import "PLFTPLog.h"

/**
 commands
 REF: https://zh.wikipedia.org/wiki/FTP%E5%91%BD%E4%BB%A4%E5%88%97%E8%A1%A8
 - PLFTPClientEnumCommand_MLSD:
 - PLFTPClientEnumCommand_CWD:
 - PLFTPClientEnumCommand_CDUP:
 - PLFTPClientEnumCommand_PWD:
 - PLFTPClientEnumCommand_DELE:
 - PLFTPClientEnumCommand_RMD:
 - PLFTPClientEnumCommand_MKD:
 - PLFTPClientEnumCommand_STOR:
 - PLFTPClientEnumCommand_SIZE:
 - PLFTPClientEnumCommand_QUIT:
 */
typedef NS_ENUM(NSInteger, PLFTPClientEnumCommand) {
    PLFTPClientEnumCommand_TYPE,
    PLFTPClientEnumCommand_PASS,
    PLFTPClientEnumCommand_PASV,
    PLFTPClientEnumCommand_USER,
    PLFTPClientEnumCommand_OPTS,
    PLFTPClientEnumCommand_MLSD,
    PLFTPClientEnumCommand_CWD,
    PLFTPClientEnumCommand_CDUP,
    PLFTPClientEnumCommand_PWD,
    PLFTPClientEnumCommand_DELE,
    PLFTPClientEnumCommand_RMD,
    PLFTPClientEnumCommand_MKD,
    PLFTPClientEnumCommand_STOR,
    PLFTPClientEnumCommand_SIZE,
    PLFTPClientEnumCommand_QUIT
};

@interface PLFTPClientCommand : NSObject
@property (nonatomic, assign, readonly) PLFTPClientEnumCommand command;
@property (nonatomic, copy, readonly) NSString * content;

@property (nonatomic, copy, readonly) NSString * responseContent;

- (instancetype)initWithCommand:(PLFTPClientEnumCommand)command content:(NSString *)content;
@end


@protocol PLFTPClientDelegate;
@interface PLFTPClient : NSObject

/**
 初始化

 @param username 用户名
 @param password 密码
 @return PLFTPClient
 */
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password;

@property (nonatomic, readonly) NSString * username;
@property (nonatomic, readonly) NSString * password;
@property (nonatomic, readonly) BOOL isLogined;

@property (nonatomic, weak) id <PLFTPClientDelegate> delegate;

// MARK: - Connect
@property (nonatomic, readonly) NSString * host;
@property (nonatomic, assign) NSUInteger port;
/** 服务器编码 */
//@property (nonatomic, readonly) NSString * serverEncoding;
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;

/** 发送登录命令 */
- (void)login;

// MARK: - Commands
/** 当前目录 */
@property (readonly) NSString * currentDirectory;
/** 记录最后一次文件大小 */
@property (readonly) NSUInteger fileSize;

/**
 发送FTP 命令

 @param command PLFTPClientEnumCommand
 @param content NSString
 */
- (void)sendCommand:(PLFTPClientEnumCommand)command content:(NSString *)content;
@end


@protocol PLFTPClientDelegate <NSObject>
@optional

/**
 服务器连接断开

 @param client PLFTPClient
 @param error NSError
 */
- (void)ftpclientDisconnect:(PLFTPClient *)client withError:(NSError *)error;

/**
 服务器连接成功

 @param client PLFTPClient
 @param host host
 @param port port
 */
- (void)ftpclient:(PLFTPClient *)client didConnectToHost:(NSString *)host port:(uint16_t)port;

/**
 登录代理

 @param client PLFTPClient
 @param isSucceed 是否登录成功
 @param statusCode 状态码
 */
- (void)ftpclient:(PLFTPClient *)client loginIsSucceed:(BOOL)isSucceed statusCode:(NSInteger)statusCode;

- (void)ftpclient:(PLFTPClient *)client completeCommand:(PLFTPClientCommand *)command;

/**
 数据传输进度

 @param client PLFTPClient
 @param progress 0 ..< 1
 @param transferType 传输类型
 */
- (void)ftpclient:(PLFTPClient *)client transferingProgress:(float)progress transferType:(PLFTPDataTransferType)transferType;

/**
 数据传输完成

 @param client PLFTPClient
 @param data 响应数据 上传文件为空
 @param transferType 传输类型
 @param error NSError
 */
- (void)ftpclient:(PLFTPClient *)client transferredData:(NSData *)data transferType:(PLFTPDataTransferType)transferType error:(NSError *)error;
@end
