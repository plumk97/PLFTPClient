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
- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;


// MARK: - Comm
- (void)sendCommand:(NSString *)command content:(NSString *)content;

@end


@protocol PLFTPClientDelegate <NSObject>
@optional

- (void)ftpclient:(PLFTPClient *)client;


@end
