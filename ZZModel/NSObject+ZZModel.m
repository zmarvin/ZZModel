//
//  NSObject+ZZModel.m
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import "NSObject+ZZModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "ZZClassInfo.h"
#import <QuartzCore/QuartzCore.h>

#define ALWAYS_INLINE inline __attribute__((always_inline))
#define NEVER_INLINE inline __attribute__((noinline))

/// Get the Foundation class type from property info.
static ALWAYS_INLINE ZZ_NeedConvertType ZZGetNeedUseModeifyDictNSType(Class cls) {
    if (!cls) return ZZ_TypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return ZZ_TypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return ZZ_TypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return ZZ_TypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]])
        return ZZ_TypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]])
        return ZZ_TypeNSValue;
    if ([cls isSubclassOfClass:[NSDate class]]) return ZZ_TypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return ZZ_TypeNSURL;
    return ZZ_TypeNSUnknown;
}

typedef struct {
    void *modelMeta;  ///< _ZZModelMeta
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} zz_ModelSetContext;

@interface ZZModelMeta : NSObject{
    
    @package
    NSDictionary *_replacedKeyDict;
    NSDictionary *_mapperClassInArrayDict;
    
    ZZClassInfo *_clsInfo;
    
    BOOL _isModeifyTypePropertys;
    
    BOOL _isHaveCustomKeyValues;
    BOOL _isImplementCustomClassInArray;
    
    NSArray *_allPropertyInfoValues;
    
    NSMutableDictionary *_mapperCustomKeyValues;
}

@end

@implementation ZZModelMeta

+ (instancetype)metaWithClass:(Class)cls withDic:(NSDictionary **)dic{
    
    static CFMutableDictionaryRef metaCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    
    dispatch_once(&onceToken, ^{
        metaCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    ZZModelMeta *meta = CFDictionaryGetValue(metaCache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    
    if (meta == nil) {
        meta = [ZZModelMeta new];
        meta->_clsInfo = [ZZClassInfo classInfoWithClass:cls];
        meta->_allPropertyInfoValues = meta->_clsInfo->_propertyInfos.allValues.copy;
        
        dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        CFDictionarySetValue(metaCache, (__bridge const void *)(cls), (__bridge const void *)(meta));
        dispatch_semaphore_signal(lock);
    }
    
    if (!meta->_isHaveCustomKeyValues) {
        
        if ([cls respondsToSelector:@selector(zz_replacedKeyFromPropertyName)]) {
            meta->_replacedKeyDict = [cls performSelector:@selector(zz_replacedKeyFromPropertyName)];
            
            if (meta->_replacedKeyDict.count>0) {
                
                meta->_isHaveCustomKeyValues = YES;
                meta->_mapperCustomKeyValues = [NSMutableDictionary new];
                
                [meta->_replacedKeyDict enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull propertyName, NSString *_Nonnull _orikey, BOOL * _Nonnull stop) {
                    
                    ZZPropertyInfo *info = meta->_clsInfo->_propertyInfos[propertyName];
                    if (!info) return;
                    info->_isHaveCustomPropertyNameReflect = YES;
                    
                    NSString *orikey = _orikey;
                    id value;
                    if ([orikey containsString:@"."]) { // 说明多级映射
                        NSArray *levelKeys = [orikey componentsSeparatedByString:@"."];
                        
                        id levelValue = *dic;
                        for (int i = 0; i < levelKeys.count; i++) {
                            NSString *levelKey = levelKeys[i];
                            if (i == 0)
                                orikey = levelKey;
                            
                            if ([levelKey hasSuffix:@"]"]) { // 说明levelValue是数组
                                
                                NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
                                NSArray *tempArr = [levelKey componentsSeparatedByCharactersInSet:set];
                                
                                // 获取数组中的数字
                                NSInteger num = [tempArr[1] integerValue];
                                // 获取key
                                levelKey = tempArr[0];
                                // 获取value
                                levelValue = (NSArray *)[levelValue objectForKey:levelKey];
                                levelValue = levelValue[num];
                                
                            }else if ([levelValue isKindOfClass:[NSDictionary class]]) { // 说明levelValue是字典
                                levelValue = [levelValue objectForKey:levelKey];
                            }else{
                                levelValue = nil;
                            }
                        }
                        
                        value = levelValue;
                        meta->_mapperCustomKeyValues[propertyName] = value;
                    }
                    else{
                        
                        value = [*dic objectForKey:orikey];
                        [meta->_clsInfo->_propertyInfos removeObjectForKey:propertyName];
                        meta->_clsInfo->_propertyInfos[orikey] = info;
                    }
                    
                }];
                meta->_allPropertyInfoValues = meta->_clsInfo->_propertyInfos.allValues.copy;
            }
            
        }
    }
    
    if (!meta->_isImplementCustomClassInArray) {
        if ([cls respondsToSelector:@selector(zz_objectClassInArray)]) {
            meta->_mapperClassInArrayDict  = [cls performSelector:@selector(zz_objectClassInArray)];
            
            if (meta->_mapperClassInArrayDict.count>0) {
                meta->_isImplementCustomClassInArray = YES;
                
                [meta->_mapperClassInArrayDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull propertyName, NSString * _Nonnull classString, BOOL * _Nonnull stop) {
                    
                    ZZPropertyInfo *info = meta->_clsInfo->_propertyInfos[propertyName];
                    NSString *oriKey = [meta->_replacedKeyDict objectForKey:propertyName];
                    if (oriKey && meta->_clsInfo->_propertyInfos[oriKey]) {
                        info = meta->_clsInfo->_propertyInfos[oriKey];
                    }
                    
                    if([info->_class isSubclassOfClass:[NSArray class]]){
                        info->_classInArray = NSClassFromString(classString);
                    }
                    
                }];
                
                meta->_allPropertyInfoValues = meta->_clsInfo->_propertyInfos.allValues.copy;
            }
            
        }
    }
    
    if (!meta->_isModeifyTypePropertys) {
        
        meta->_isModeifyTypePropertys = YES;
        [meta->_clsInfo->_propertyInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull propertyName, ZZPropertyInfo * _Nonnull pInfo, BOOL * _Nonnull stop) {
            
            if (pInfo->_type == ZZ_TypeId && !pInfo->_isCustomClass) {
                pInfo->_NSType = ZZGetNeedUseModeifyDictNSType(pInfo->_class);
                id value = [*dic objectForKey:propertyName];
                pInfo->_NSDictType = ZZGetNeedUseModeifyDictNSType([value class]);
                
                if (pInfo->_NSDictType == ZZ_TypeNSNumber) {
                    pInfo->_isDictNSNumberOrNSValue = YES;
                }
                
                if (pInfo->_NSType != pInfo->_NSDictType &&
                    !(pInfo->_NSDictType == ZZ_TypeNSMutableString && pInfo->_NSType == ZZ_TypeNSString)
                    ) {
                    
                    pInfo->_isNeedConvertType = YES;
                }
            }
            
        }];
        
    }
    
    
    return meta;
}

@end

@implementation NSObject (ZZModel)

#pragma - 转模型
+ (id)zz_modelWithDictionary:(NSDictionary *)dict{
    if (!dict || dict == (id)kCFNull) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    id model = [self new];
    ZZModelMeta *meta = [ZZModelMeta metaWithClass:self withDic:&dict];
    
    zz_ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(meta);
    context.model = (__bridge_retained void *)model;
    context.model = (__bridge void *)model;
    context.dictionary = (__bridge void *)(dict);
    
    __unsafe_unretained NSArray *arr = meta->_allPropertyInfoValues;
    __unsafe_unretained NSDictionary *dic = dict;
    if (meta->_clsInfo->_propertyInfos.count >= CFDictionaryGetCount((CFDictionaryRef)dic)){
        CFDictionaryApplyFunction((CFDictionaryRef)dic, setValueWithDictionaryFunction, &context);
        
        if (meta->_mapperCustomKeyValues) {
            __unsafe_unretained NSDictionary *rpPropertys = meta->_mapperCustomKeyValues;
            CFDictionaryApplyFunction((CFDictionaryRef)rpPropertys, setValueWithDictionaryFunction, &context);
        }
        
    }else{
        CFArrayApplyFunction((CFArrayRef)arr,
                             CFRangeMake(0, CFArrayGetCount((CFArrayRef)arr)),
                             setValueWithArrayFunction,
                             &context
                             );
    }
    
    return model;
}

static void setValueWithDictionaryFunction(const void *_key, const void *_value, void *_context){
    
    zz_ModelSetContext *context = _context;
    __unsafe_unretained ZZModelMeta *meta = (__bridge ZZModelMeta *)(context->modelMeta);
    __unsafe_unretained id      value = (__bridge id)(_value);
    __unsafe_unretained NSString *key = (__bridge id)(_key);
    __unsafe_unretained ZZPropertyInfo *info = [meta->_clsInfo->_propertyInfos objectForKey:key];
    
    if (!info) return;
    if (!info->_setSelector) return;
    if (value == nil) return;
    
    if (info->_isCustomClass) {
        value = [info->_class zz_modelWithDictionary:(NSDictionary *)value];
    }else if (info->_classInArray) {
        value = [info->_classInArray zz_modelsWithArray:value];
    }
    
    if (value == nil) return;
    
    __unsafe_unretained id model = (__bridge id)(context->model);
    
    setValue(value,info,model);
}

static void setValueWithArrayFunction(const void *_info, void *_context){
    
    zz_ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary   *dict = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained ZZPropertyInfo *info = (__bridge ZZPropertyInfo *)(_info);
    
    if (!info->_setSelector) return;
    
    id value = [dict objectForKey:info->_name];
    
    if (value == nil) return;
    
    if (info->_isCustomClass) {
        value = [info->_class zz_modelWithDictionary:(NSDictionary *)value];
    }else if (info->_classInArray) {
        value = [info->_classInArray zz_modelsWithArray:value];
    }
    
    if (value == nil) return;
    
    __unsafe_unretained id model = (__bridge id)(context->model);
    setValue(value,info,model);
    
}

static void setValue(
                     __unsafe_unretained id value,
                     __unsafe_unretained ZZPropertyInfo *info,
                     __unsafe_unretained id model
                     ){
    
    if (value == nil) return;
    
    NSNumber *tValue =value;
    switch (info->_type) {
            
        case ZZ_TypeId:{
            if (info->_isNeedConvertType) {
                tValue = convertTypeToModeifyNSType(info,tValue);
            }
            if (info->_modifyProperty == ZZ_ModifypropertyCopy) {
                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.copy);
            }else{
                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,info->_setSelector,tValue);
            }
            break;
        }
        case ZZ_TypeChar:
            ((void (*)(id, SEL, char))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.charValue);
            break;
        case ZZ_TypeInt:
            ((void (*)(id, SEL, int))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.intValue);
            break;
        case ZZ_TypeShort:
            ((void (*)(id, SEL, short))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.shortValue);
            break;
        case ZZ_TypeLong:
            ((void (*)(id, SEL, long))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.longValue);
            break;
        case ZZ_TypeLongLong:
            ((void (*)(id, SEL, long long))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.longLongValue);
            break;
        case ZZ_TypeUnsignedChar:
            ((void (*)(id, SEL, unsigned char))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.unsignedCharValue);
            break;
        case ZZ_TypeUnsignedInt:
            ((void (*)(id, SEL, unsigned int))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.unsignedIntValue);
            break;
        case ZZ_TypeUnsignedShort:
            ((void (*)(id, SEL, unsigned short))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.unsignedShortValue);
            break;
        case ZZ_TypeUnsignedLong:
            ((void (*)(id, SEL, unsigned long))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.unsignedLongValue);
            break;
        case ZZ_TypeUnsignedLongLong:
            ((void (*)(id, SEL, unsigned long long))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.unsignedLongLongValue);
            break;
        case ZZ_TypeFloat:
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.floatValue);
            break;
        case ZZ_TypeDouble:
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.doubleValue);
            break;
        case ZZ_TypeBool:
            ((void (*)(id, SEL, BOOL))(void *) objc_msgSend)((id)model,info->_setSelector,tValue.boolValue);
            break;
        case ZZ_TypeVoid:
            ((void (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_setSelector);
            break;
            
        case ZZ_TypeCString:{
            NSString *sValue = (NSString *)tValue;
            if([sValue isKindOfClass:[NSNumber class]]) sValue  = [tValue stringValue];
            ((void (*)(id, SEL, char *))(void *) objc_msgSend)((id)model,info->_setSelector,(char *)sValue.UTF8String);
        }
            break;
            
        case ZZ_TypeBlock:{
            ((void (*)(id, SEL, void(^)()))(void *) objc_msgSend)((id)model,info->_setSelector,(void(^)())tValue);
            break;
        }
        case ZZ_TypeClass:{
            NSString *sValue = (NSString *)tValue;
            if([sValue isKindOfClass:[NSNumber class]]) sValue  = [tValue stringValue];
            ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model,info->_setSelector,NSClassFromString((NSString *)sValue));
        }
            break;
        case ZZ_TypeSelector:{
            NSString *sValue = (NSString *)tValue;
            if([sValue isKindOfClass:[NSNumber class]]) sValue  = [tValue stringValue];
            ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model,info->_setSelector,NSSelectorFromString(sValue));
            break;
        }
        case ZZ_TypeCArray:
        case ZZ_TypeStructure:
        case ZZ_TypeUnion:{
            //            [self setValue:value forKey:[NSString stringWithUTF8String:info->_name]];
            break;
        }
        case ZZ_TypeBnum:{
            NSString *sValue = (NSString *)tValue;
            if([sValue isKindOfClass:[NSNumber class]]) sValue  = [tValue stringValue];
            ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model,info->_setSelector,NSSelectorFromString(sValue));
            break;
        }
        case ZZ_TypePointer:{
            ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, info->_setSelector, tValue.pointerValue);
            break;
        }
        case ZZ_TypeUnknown:
        default:
            break;
    }
}

static ALWAYS_INLINE id convertTypeToModeifyNSType(__unsafe_unretained ZZPropertyInfo *_info ,__unsafe_unretained id _value){
    id value = _value;
    switch (_info->_NSType) {
        case ZZ_TypeNSString:{
            if (_info->_isDictNSNumberOrNSValue) {
                value = [(NSNumber *)_value stringValue];
            }
            break;
        }
        case ZZ_TypeNSMutableString:{
            if (_info->_isDictNSNumberOrNSValue) {
                value = [value stringValue].mutableCopy;
            }else{
                value = [NSMutableString stringWithString:value];
            }
            break;
        }
        case ZZ_TypeNSValue:
            if (!_info->_isDictNSNumberOrNSValue)
                value = nil;
            break;
        case ZZ_TypeNSNumber:
            
            break;
        case ZZ_TypeNSDecimalNumber:
            
            break;
        case ZZ_TypeNSDate:
            
            break;
        case ZZ_TypeNSURL:
            value = [NSURL URLWithString:value];
            break;
        case ZZ_TypeNSUnknown:
            break;
        default:
            break;
    }
    
    return value;
}


+ (id)zz_modelWithJsonString:(NSString *)jsonString{
    
    id value = [jsonString zz_JsonObject];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        value = [self zz_modelWithDictionary:value];
    }else if ([value isKindOfClass:[NSArray class]]){
        value = [self zz_modelsWithArray:value];
    }else{
        value = nil;
    }
    
    return value;
}

typedef struct {
    void *class;        ///< id (self)
    void *modelArr;     ///< NSArray (models)
} zz_convertModelsContext;

+ (NSMutableArray *)zz_modelsWithArray:(NSArray *)dicts{
    
    if (![dicts isKindOfClass:[NSArray class]]) return nil;
    
    zz_convertModelsContext context = {0};
    context.class = (__bridge void *)(self);
    context.modelArr = (__bridge_retained void *)([[NSMutableArray alloc] init]);
    
    CFArrayApplyFunction((CFArrayRef)dicts,
                         CFRangeMake(0, CFArrayGetCount((CFArrayRef)dicts)),
                         convertModelArrayFunction,
                         &context
                         );
    
    return [NSMutableArray arrayWithArray:(__bridge NSMutableArray *)(context.modelArr)];
}

static void convertModelArrayFunction(const void *_value, void *_context){
    zz_convertModelsContext *context = _context;
    
    __unsafe_unretained Class cls = (__bridge Class)(context->class);
    __unsafe_unretained NSMutableArray *models = (__bridge NSMutableArray *)(context->modelArr);
    __unsafe_unretained id value = (__bridge id)(_value);
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        id obj = [cls zz_modelWithDictionary:value];
        [models addObject:obj];
    }else if ([value isKindOfClass:[NSArray class]]) {
        [models addObject:[cls zz_modelsWithArray:(NSArray *)value]];
    }else {
        [models addObject:value];
    }
}

#pragma - 转字典

static ALWAYS_INLINE id getValueWithClassInfo(__unsafe_unretained ZZPropertyInfo *info,
                                              __unsafe_unretained id model
                                              ){
    void *value = NULL;
    NSNumber *NumValue = nil;
    switch (info->_type) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wint-conversion"
            
        case ZZ_TypeId:
            value = (__bridge void *)(((id (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector));
            break;
        case ZZ_TypeChar:{
            value = ((char (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((char)value);
            break;
        }
        case ZZ_TypeInt:
            value = ((int (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((int)value);
            break;
        case ZZ_TypeShort:{
            value = ((short (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((short)value);
            break;
        }
        case ZZ_TypeLong:{
            value =  ((long (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((long)value);
            break;
        }
        case ZZ_TypeLongLong:{
            value = ((long long (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((long long)value);
            break;
        }
        case ZZ_TypeUnsignedChar:{
            value = ((unsigned char (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((unsigned char)value);
            break;
        }
        case ZZ_TypeUnsignedInt:
            value = ((unsigned int (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((unsigned int)value);
            break;
        case ZZ_TypeUnsignedShort:{
            value = ((unsigned short (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((unsigned short)value);
            break;
        }
        case ZZ_TypeUnsignedLong:{
            value = ((unsigned long (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((unsigned long)value);
            break;
        }
        case ZZ_TypeUnsignedLongLong:{
            value = ((unsigned long long (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((unsigned long long)value);
            break;
        }
        case ZZ_TypeFloat:{
            NumValue = @(((float (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector));
            break;
        }
        case ZZ_TypeDouble:
            NumValue = @(((double (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector));
            break;
        case ZZ_TypeBool:{
            value = ((BOOL (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = @((bool)value);
            break;
        }
        case ZZ_TypeCString:{
            value = ((char *(*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            NumValue = [NSNumber numberWithChar:(char *)value];
        }
            break;
        case ZZ_TypeBlock:{
            value = (__bridge void *)(((id (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector));
            break;
        }
        case ZZ_TypeClass:{
            value = (__bridge void *)(((id (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector));
        }
            break;
        case ZZ_TypeSelector:{
            value = ((SEL (*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            break;
        }
        case ZZ_TypeCArray:
        case ZZ_TypeStructure:
        case ZZ_TypeUnion:{
            //            [self setValue:value forKey:[NSString stringWithUTF8String:info->_name]];
            break;
        }
        case ZZ_TypeBnum:{
            
            value = ((char *(*)(id, SEL))(void *) objc_msgSend)((id)model,info->_getSelector);
            break;
        }
        case ZZ_TypePointer:{
            value = ((void *(*)(id, SEL))(void *) objc_msgSend)((id)model, info->_getSelector);
            break;
        }
        case ZZ_TypeUnknown:
        default:
            break;
    }
#pragma clang diagnostic pop
    if (info->_type == ZZ_TypeId) {
        return  (__bridge id)(value);
    }else{
        return NumValue;
    }
}

- (NSDictionary *)zz_toDictionary{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [self.class enumerateClassInfosUsingBlock:^(ZZPropertyInfo *info) {
        
        id value = getValueWithClassInfo(info ,self);
        
        if (info->_class) {// 是对象类型
            if (info->_isCustomClass) { // 说明是自定义的类型
                value = [value zz_toDictionary];
            }else if (info->_isArray) {
                value = [value zz_arraryWithModels:value];
            }
        };
        if (value) {
            NSDictionary *replacedKeyDict = nil;
            if ([[self class] respondsToSelector:@selector(zz_replacedKeyFromPropertyName)]) {
                replacedKeyDict   = [[self class] performSelector:@selector(zz_replacedKeyFromPropertyName)];
            }
            
            NSDictionary *classInArrayDict = nil;
            if ([[self class] respondsToSelector:@selector(zz_objectClassInArray)]) {
                classInArrayDict  = [[self class] performSelector:@selector(zz_objectClassInArray)];
            }
            
            [dict setObject:value forKey:info->_name];
        }
        
    }];
    
    return dict;
}

- (NSMutableArray *)zz_arraryWithModels:(NSArray *)objects{
    
    NSMutableArray *arr = [NSMutableArray array];
    for (id object in objects) {
        
        if ([object isKindOfClass:[NSDictionary class]]) {
            [arr addObject:object];
        }
        
        if (!isClassFromFoundation([object class])) { // 说明是自定义的类型
            [arr addObject:[object zz_toDictionary]];
        }
        
        if ([object isKindOfClass:[NSArray class]]) {
            [arr addObject:[object zz_arraryWithModels:object]];
        }
    }
    
    return arr;
}

- (id)zz_JsonObject
{
    if ([self isKindOfClass:[NSString class]]) {
        return [NSJSONSerialization JSONObjectWithData:[((NSString *)self) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    } else if ([self isKindOfClass:[NSData class]]) {
        return [NSJSONSerialization JSONObjectWithData:(NSData *)self options:kNilOptions error:nil];
    }
    return nil;
}
// 字典->字符串
- (NSString *)jsonString{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:kNilOptions
                                                         error:&error];
    if (jsonData == nil) {
#ifdef DEBUG
        NSLog(@"fail to get JSON from dictionary: %@, error: %@", self, error);
#endif
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
    
}

#pragma - 归档
- (void)zz_decode:(NSCoder *)decoder{
    
    [self.class enumerateClassInfosUsingBlock:^(ZZPropertyInfo *info) {
        id value = [decoder decodeObjectForKey:info->_name];
        setValue(value, info, self);
    }];
    
}

- (void)zz_encode:(NSCoder *)encoder{
    
    [self.class enumerateClassInfosUsingBlock:^(ZZPropertyInfo *info) {
        id value = getValueWithClassInfo(info,self);
        [encoder encodeObject:value forKey:info->_name];
    }];
}

+ (void)enumerateClassInfosUsingBlock:(void(^)(ZZPropertyInfo *info))block{
    
    ZZClassInfo *clsInfo = [ZZClassInfo classInfoWithClass:self];
    
    [clsInfo->_propertyInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull name, ZZPropertyInfo *_Nonnull Info, BOOL * _Nonnull stop) {
        if (block) {
            block(Info);
        }
    }];
    
}

+ (BOOL)memberIsClassTypeWithMemberName:(const char *)name{
    
    objc_property_t p = class_getProperty(self, name);
    objc_property_attribute_t *attrbutes = property_copyAttributeList(p, NULL);
    objc_property_attribute_t attribute = attrbutes[0];
    if (attribute.name[0] == 'T' && attribute.value[0] == '@') {
        return YES;
    }else{
        return NO;
    }
    
}

@end
