//
//  NSObject+ZZModel.h
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZZModel <NSObject>

@optional
// key替换，多级映射
+ (NSDictionary *)zz_replacedKeyFromPropertyName;

// 数组中存放的是什么自定义类型的数组
+ (NSDictionary *)zz_objectClassInArray;

@end


@interface NSObject (ZZModel)

#pragma - 转模型

/**
 *  字典->模型
 */
+ (id)zz_modelWithDictionary:(NSDictionary *)dict;
/**
 *  json字符串->模型
 */
+ (id)zz_modelWithJsonString:(NSString *)jsonString;
/**
 *  字典数组->模型数组
 */
+ (NSMutableArray *)zz_modelsWithArray:(NSArray *)dicts;


#pragma - 转字典
/**
 *  模型->字典
 */
- (NSDictionary *)zz_toDictionary;
/**
 *  模型数组->字典数组
 */
- (NSMutableArray *)zz_dictionarysWithModels:(NSArray *)objects;

/**
 *  json字符串->字典
 */
- (id)zz_JsonObject;

#pragma - 归档

- (void)zz_decode:(NSCoder *)decoder;

- (void)zz_encode:(NSCoder *)encoder;

/**
 归档的实现
 */
#define zz_CodingImplementation \
- (id)initWithCoder:(NSCoder *)decoder \
{ \
if (self = [super init]) { \
[self zz_decode:decoder]; \
} \
return self; \
} \
\
- (void)encodeWithCoder:(NSCoder *)encoder \
{ \
[self zz_encode:encoder]; \
}


@end
