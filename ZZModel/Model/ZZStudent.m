//
//  ZZStudent.m
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import "ZZStudent.h"

@implementation ZZStudent

+ (NSDictionary *)zz_replacedKeyFromPropertyName
{
    return @{
             @"videoListDictByYear":@"ceshi",
             @"ID" : @"id",
             @"desc" : @"desciption",
             @"oldName" : @"name.oldName",
             @"nowName" : @"name.newName",
             @"nameChangedTime" : @"name.info[1].nameChangedTime",
             @"bag" : @"other.bag"
             };
}

@end
