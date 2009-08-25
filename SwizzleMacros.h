#import "JRSwizzle.h"
#import <objc/runtime.h>

#define _CONCAT(A, B) A ## B

#define COPY_METHOD(FROM_CLASS, TO_CLASS, SEL) do { \
    Method _m = class_getInstanceMethod(FROM_CLASS, @selector(SEL)); \
    class_addMethod(TO_CLASS, @selector(SEL), method_getImplementation(_m), method_getTypeEncoding(_m)); \
  } while (NO)

#define EXCHANGE(CLASS, PREFIX, SEL) do { \
    [CLASS jr_swizzleMethod:@selector(SEL) withMethod:@selector(_CONCAT(PREFIX, SEL)) error:NULL]; \
    /*if (_err) NSLog(@"Unable to swizzle method %@; this may cause major problems with Safari!", NSStringFromSelector(@selector(SEL))); */\
  } while (NO)

#define COPY_AND_EXCHANGE(FROM_CLASS, TO_CLASS, PREFIX, SEL) do { \
    COPY_METHOD(FROM_CLASS, TO_CLASS, _CONCAT(PREFIX, SEL)); \
    EXCHANGE(TO_CLASS, PREFIX, SEL); \
  } while (NO)
