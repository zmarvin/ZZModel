//
//  ZZClassInfo.h
//  ZZModel
//
//  Created by zmarvin on 16/4/11.
//  Copyright © 2016年 zmarvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/// Foundation Class Type
typedef NS_ENUM (NSUInteger, ZZ_NeedConvertType) {
    ZZ_TypeNSUnknown = 0,
    ZZ_TypeNSString,
    ZZ_TypeNSMutableString,
    ZZ_TypeNSValue,
    ZZ_TypeNSNumber,
    ZZ_TypeNSDecimalNumber,
    ZZ_TypeNSDate,
    ZZ_TypeNSURL,
};

typedef enum : NSUInteger {
    
    ZZ_ModifypropertyAssign     = 0,
    ZZ_ModifypropertyStrong     = 1,
    ZZ_ModifypropertyWeak       = 2,
    ZZ_ModifypropertyCopy       = 3,
    
} ZZ_ModifyProperty;

typedef enum : NSUInteger {
    ZZ_TypeChar,
    ZZ_TypeInt,
    ZZ_TypeShort,
    ZZ_TypeLong,
    ZZ_TypeLongLong,
    ZZ_TypeUnsignedChar,
    ZZ_TypeUnsignedInt,
    ZZ_TypeUnsignedShort,
    ZZ_TypeUnsignedLong,
    ZZ_TypeUnsignedLongLong,
    
    ZZ_TypeFloat,
    ZZ_TypeDouble,
    ZZ_TypeBool,
    ZZ_TypeVoid,
    ZZ_TypeCString,
    ZZ_TypeId,
    ZZ_TypeBlock,
    ZZ_TypeClass,
    ZZ_TypeSelector,
    
    ZZ_TypeCArray,
    ZZ_TypeStructure,
    ZZ_TypeUnion,
    ZZ_TypeBnum,
    ZZ_TypePointer,
    ZZ_TypeUnknown,
    
} ZZ_Type;

typedef NS_ENUM(char,ZZ_TypeEncode) {
    ZZ_TypeEncodeChar               = 'c',
    ZZ_TypeEncodeInt                = 'i',
    ZZ_TypeEncodeShort              = 's',
    ZZ_TypeEncodeLong               = 'l',
    ZZ_TypeEncodeLongLong           = 'q',
    ZZ_TypeEncodeUnsignedChar       = 'C',
    ZZ_TypeEncodeUnsignedInt        = 'I',
    ZZ_TypeEncodeUnsignedShort      = 'S',
    ZZ_TypeEncodeUnsignedLong       = 'L',
    ZZ_TypeEncodeUnsignedLongLong   = 'Q',
    
    ZZ_TypeEncodeFloat      = 'f',
    ZZ_TypeEncodeDouble     = 'd',
    ZZ_TypeEncodeBool       = 'B',
    ZZ_TypeEncodeVoid       = 'v',
    ZZ_TypeEncodeCString    = '*',
    
    ZZ_TypeEncodeObject     = '@',
    ZZ_TypeEncodeBlock,
    
    ZZ_TypeEncodeClass      = '#',
    ZZ_TypeEncodeSelector   = ':',
    
    ZZ_TypeEncodeCArray     = '[',
    ZZ_TypeEncodeStructure  = '{',
    ZZ_TypeEncodeUnion      = '(',
    ZZ_TypeEncodeBnum       = 'b',
    ZZ_TypeEncodePointer    = '^',
    ZZ_TypeEncodeUnknown    = '?',
    
};

@interface ZZClassInfo : NSObject{
    @package
    NSMutableDictionary *_propertyInfos;
    Class _cls;
}
+ (instancetype)classInfoWithClass:(Class)cls;

extern BOOL isClassFromFoundation(Class c);

@end

@interface ZZPropertyInfo : NSObject{
    
    @package
    NSString    *_name;
    const char  *_ivarName;
    
    Class       _class;
    BOOL        _isCustomClass;
    BOOL        _isArray;
    
    BOOL        _isHaveCustomPropertyNameReflect; // 是否自定义映射路径
    
    Class       _classInArray;
    
    BOOL        _isNonatomic;
    BOOL        _isReadOnly;
    BOOL        _isDynamic;
    ZZ_ModifyProperty _modifyProperty;
    ZZ_TypeEncode     _encode;
    ZZ_Type           _type;
    
    ZZ_NeedConvertType              _NSType;
    
    ZZ_NeedConvertType              _NSDictType;
    
    BOOL                _isDictNSNumberOrNSValue;
    BOOL                _isNeedConvertType;
    SEL   _setSelector;
    SEL   _getSelector;
    
    BOOL _isCoutomGetter;
    BOOL _isCoutomSetter;
}

- (instancetype)initWithProperty:(objc_property_t)property;

@end
