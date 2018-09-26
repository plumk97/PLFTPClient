//
//  PLFTPLog.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "PLFTPLog.h"

static NSUInteger logCount = 0;
void PLFTPLog(NSString * format, ...) {
    
    va_list args;
    va_start(args, format);
    NSString * str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    printf("FTPLog (%lu): \n%s\n", logCount ++, [str UTF8String]);
}
