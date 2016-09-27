//
//  ZZClassInfo.m
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import "ZZClassInfo.h"
#import <objc/runtime.h>
#import <CoreData/CoreData.h>

@implementation ZZClassInfo{
    BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls{
    if (!cls) return nil;
    self = [super init];
    _cls = cls;
    
    [self update];
    
    return self;
    
}

- (void)update{
    
    self->_propertyInfos = [NSMutableDictionary dictionary];
    unsigned int outCount = 0, i = 0;
    objc_property_t *properties = class_copyPropertyList(self->_cls, &outCount);
    
    while (i < outCount) {
        
        ZZPropertyInfo *Info = [[ZZPropertyInfo alloc] initWithProperty:properties[i]];
        
        self->_propertyInfos[Info->_name] = Info;
        
        i++;
    }
    free(properties);
    
    _needUpdate = NO;
}


+ (instancetype)classInfoWithClass:(Class)cls {
    
    if (!cls) return nil;
    static CFMutableDictionaryRef classCache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        classCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    ZZClassInfo *info = CFDictionaryGetValue(classCache, (__bridge const void *)(cls));
    if (info && info->_needUpdate) {
        [info update];
    }
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[ZZClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(classCache, (__bridge const void *)(cls), (__bridge const void *)(info));
            dispatch_semaphore_signal(lock);
        }
    }
    
    return info;
}

static NSSet *foundationClasses_;
+ (NSSet *)foundationClasses
{
    if (foundationClasses_ == nil) {
        // 集合中没有NSObject，因为几乎所有的类都是继承自NSObject，具体是不是NSObject需要特殊判断
        foundationClasses_ = [NSSet setWithObjects:
                              [NSURL class],
                              [NSDate class],
                              [NSValue class],
                              [NSData class],
                              [NSError class],
                              [NSArray class],
                              [NSDictionary class],
                              [NSString class],
                              [NSAttributedString class], nil];
    }
    return foundationClasses_;
}

BOOL isClassFromFoundation(Class c)
{
    if (c == [NSObject class] || c == [NSManagedObject class]) return YES;
    
    __block BOOL result = NO;
    [[ZZClassInfo foundationClasses] enumerateObjectsUsingBlock:^(Class foundationClass, BOOL *stop) {
        if ([c isSubclassOfClass:foundationClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

+ (BOOL)memberIsClassTypeWithMemberName:(const char *)keyPath{
    
    objc_property_t p = class_getProperty(self, keyPath);
    objc_property_attribute_t *attrbutes = property_copyAttributeList(p, NULL);
    objc_property_attribute_t attribute = attrbutes[0];
    if (attribute.name[0] == 'T' && attribute.value[0] == '@') {
        return YES;
    }else{
        return NO;
    }
    
}


@end

@implementation ZZPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property{
    if (self == [super init]) {
        
        _isNonatomic = NO;
        _modifyProperty = ZZ_ModifypropertyAssign;
        _class = NULL;
        _isCoutomGetter = NO;
        _isCoutomSetter = NO;
        
        unsigned int count = 0;
        objc_property_attribute_t *attrbutes = property_copyAttributeList(property, &count);
        
        for (unsigned int i = 0; i < count; ++i) {
            objc_property_attribute_t attribute = attrbutes[i];
            const char *name  = attribute.name;
            const char *value = attribute.value;
            
            switch (name[0]) {
                case 'T':{
                    _encode = value[0];
                    _type   = getTypeWithEncodeValue(&_encode);
                    size_t lenth = strlen(value);
                    
                    if (_type == ZZ_TypeId && lenth >= 3) {
                        char modifyValue[lenth];
                        for (int i = 0; i < lenth-3 ; i++) {
                            modifyValue[i] = value[i+2];
                        }
                        modifyValue[lenth - 3] = '\0';
                        
                        _class = objc_getClass(modifyValue);
                        
                        if (isClassFromFoundation(_class)) {
                            _isArray = [_class isSubclassOfClass:[NSArray class]];
                        }else{
                            _isCustomClass = YES;
                        }
                    }else if (lenth == 2 && value[1] == '?') {
                        _encode = ZZ_TypeEncodeBlock;
                        _type   = ZZ_TypeBlock;
                    }
                    break;
                }
                case 'V':
                    _ivarName       = value;
                    break;
                case 'R':
                    _isReadOnly     = YES;
                    break;
                case 'N':
                    _isNonatomic    = YES;
                    break;
                case 'C':
                    _modifyProperty = ZZ_ModifypropertyCopy;
                    break;
                case '&':
                    _modifyProperty = ZZ_ModifypropertyStrong;
                    break;
                case 'W':
                    _modifyProperty = ZZ_ModifypropertyWeak;
                    break;
                case 'D': {
                    _isDynamic      = YES;
                    break;
                }
                case 'G':{
                    _getSelector    = NSSelectorFromString([NSString stringWithUTF8String:value]);
                    break;
                }
                case 'S':{
                    _setSelector    = NSSelectorFromString([NSString stringWithUTF8String:value]);
                    break;
                }
                default:
                    break;
            }
            
        }
        
        const char *_nameC = property_getName(property);
        _name = [NSString stringWithUTF8String:_nameC];
        
        if (!_setSelector) {
            
            size_t clenth = strlen(_nameC);
            char cStr[clenth];
            strcpy(cStr,_nameC);
            if (_nameC[0] >='a' && _nameC[0] <= 'z') {
                cStr[0]-=32;//将第一个字母大写
            }
            
            _setSelector = NSSelectorFromString([NSString stringWithFormat:@"set%s:",cStr]);
            
        }
        
        if (!_getSelector) {
            _getSelector = NSSelectorFromString(_name);
        }
        
        free(attrbutes);
    }
    
    return self;
}

ZZ_Type getTypeWithEncodeValue(const char *value){
    ZZ_Type type;
    
    switch (*value) {
        case ZZ_TypeEncodeObject:
            type = ZZ_TypeId;
            break;
        case ZZ_TypeEncodeChar:
            type = ZZ_TypeChar;
            break;
        case ZZ_TypeEncodeInt:
            type = ZZ_TypeInt;
            break;
        case ZZ_TypeEncodeShort:
            type = ZZ_TypeShort;
            break;
        case ZZ_TypeEncodeLongLong:
            type = ZZ_TypeLongLong;
            break;
        case ZZ_TypeEncodeUnsignedChar:
            type = ZZ_TypeUnsignedChar;
            break;
        case ZZ_TypeEncodeUnsignedInt:
            type = ZZ_TypeUnsignedInt;
            break;
        case ZZ_TypeEncodeUnsignedLong:
            type = ZZ_TypeUnsignedLong;
            break;
        case ZZ_TypeEncodeUnsignedLongLong:
            type = ZZ_TypeUnsignedLongLong;
            break;
        case ZZ_TypeEncodeFloat:
            type = ZZ_TypeFloat;
            break;
        case ZZ_TypeEncodeDouble:
            type = ZZ_TypeDouble;
            break;
        case ZZ_TypeEncodeBool:
            type = ZZ_TypeBool;;
            break;
        case ZZ_TypeEncodeVoid:
            type = ZZ_TypeVoid;
            break;
        case ZZ_TypeEncodeCString:
            type = ZZ_TypeCString;
            break;
        case ZZ_TypeEncodeClass:
            type = ZZ_TypeClass;
            break;
        case ZZ_TypeEncodeSelector:
            type = ZZ_TypeSelector;
            break;
            
        case ZZ_TypeEncodeCArray:
            type = ZZ_TypeCArray;
            break;
        case ZZ_TypeEncodeStructure:
            type = ZZ_TypeStructure;
            break;
        case ZZ_TypeEncodeUnion:
            type = ZZ_TypeUnion;
            break;
        case ZZ_TypeEncodeBnum:
            type = ZZ_TypeBnum;
            break;
        case ZZ_TypeEncodePointer:
            type = ZZ_TypePointer;
            break;
        case ZZ_TypeEncodeUnknown:
            type = ZZ_TypeUnknown;
            break;
        default:
            break;
    }
    
    return type;
}

@end
