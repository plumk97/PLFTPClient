//
//  NSData+PLCSTR.m
//  PLFTPClient
//
//  Created by 李铁柱 on 2018/9/18.
//  Copyright © 2018年 Plumk. All rights reserved.
//

#import "NSData+PLCSTR.h"

@implementation NSData (PLCSTR)

- (NSString *)string {
//    NSMutableString * mStr = [[NSMutableString alloc] init];
//    
//    const uint8_t * bytes = [self bytes];
//    for (int i = 0; i < self.length; i ++) {
//        [mStr appendFormat:@"%c", bytes[i]];
//    }
//    
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}
@end
