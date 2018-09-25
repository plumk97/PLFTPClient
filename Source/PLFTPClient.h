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
/** 服务器编码 */
//@property (nonatomic, readonly) NSString * serverEncoding;
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;

/** 发送登录命令 */
- (void)login;

// MARK: - Commands
/** 当前目录 */
@property (readonly) NSString * currentDirectory;

/**
 发送FTP 命令

 @param command 命令名
 @param content con
 */
- (void)sendCommand:(NSString *)command content:(NSString *)content;


/**
 列出目录下文件

 @param path 目录路径
 */
- (void)MLSD:(NSString *)path;

/**
 切换目录

 @param path 目录路径
 */
- (void)CWD:(NSString *)path;

/**
 返回上级目录
 */
- (void)CDUP;

/**
 打印当前工作目录
 */
- (void)PWD;


/**
 删除文件

 @param file 文件路径
 */
- (void)DELE:(NSString *)file;

/**
 删除目录

 @param dir 目录路径
 */
- (void)RMD:(NSString *)dir;


/**
 创建目录

 @param name 目录名
 */
- (void)MKD:(NSString *)name;

/**
 上传文件

 @param file 本地文件路径
 */
- (void)STOR:(NSString *)file;

/**
 退出FTP
 */
- (void)QUIT;
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

/**
 数据传输完成

 @param client PLFTPClient
 @param data 响应数据 上传文件为空
 @param transferType 传输类型
 */
- (void)ftpclient:(PLFTPClient *)client transferredData:(NSData *)data transferType:(PLFTPDataTransferType)transferType;
@end
