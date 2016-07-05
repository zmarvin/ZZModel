//
//  ZZStudent.h
//  ZZModel
//
//  Created by zmarvin on 15/1/5.
//  Copyright (c) 2015年 zmarvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZZBag.h"

@interface ZZStudent : NSObject
{
    float _privateName;
    float _privateAttribute;
}

@property (copy, atomic) NSString *ID;
@property (strong, nonatomic) NSString *otherName;
@property (copy, nonatomic) NSString *nowName;
@property (copy, nonatomic) NSString *oldName;
@property (copy, nonatomic) NSString *nameChangedTime;
@property (copy, nonatomic) NSString *desc;
@property (strong, nonatomic) ZZBag *bag;
@property (strong, nonatomic) NSArray *books;

@property (nonatomic,strong) NSLock *blocl;
@property (assign, nonatomic) double weight;
@property (assign, nonatomic) int size;
@property (assign, nonatomic) BOOL isFat;
@property (assign, nonatomic) Class classType;


@property (nonatomic, copy  ) NSString *title;
@property (nonatomic, strong) NSArray *names;
@property (nonatomic, assign) int count;
@property (nonatomic, weak  ) id delegate;
@property (atomic, strong   ) NSNumber *atomicProperty;


@property (nonatomic, strong) NSMutableDictionary *videoListDictByYear;
@end
