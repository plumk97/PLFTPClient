//
//  PLFTPClientConfig.h
//  PLFTPClient
//
//  Created by AQY on 2018/9/26.
//  Copyright © 2018 Plumk. All rights reserved.
//

#ifndef PLFTPClientConfig_h
#define PLFTPClientConfig_h

#import <Foundation/Foundation.h>

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
    PLFTPClientEnumCommand_RETR,
    PLFTPClientEnumCommand_SIZE,
    PLFTPClientEnumCommand_QUIT,
    PLFTPClientEnumCommand_STAT
};

#endif /* PLFTPClientConfig_h */
