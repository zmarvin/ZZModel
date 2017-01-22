//
//  ZZUser.h
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SexMale,
    SexFemale
} Sex;

@interface ZZUser : NSObject
/** 名称 */
@property (copy, nonatomic) NSString *name;
/** 头像 */
@property (copy, nonatomic) NSString *icon;
/** 头像 */
@property (copy, nonatomic) NSString *icon123213;

/** 年龄 */
@property (assign, nonatomic) unsigned int age;
/** 身高 */
@property (strong, nonatomic) NSNumber *height;
/** 财富 */
@property (strong, nonatomic) NSDecimalNumber *money;
/** 性别 */
@property (assign, nonatomic) Sex sex;
/** 同性恋 */
@property (assign, nonatomic, getter=isGay) BOOL gay;
@end
