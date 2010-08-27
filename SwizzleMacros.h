#import "JRSwizzle.h"
#import <objc/runtime.h>

#define _CONCAT(A, B) A ## B

static inline void ComBelkadanKeystone_copyMethod(Class fromClass, Class toClass, SEL sel) {
	Method _m = class_getInstanceMethod(fromClass, sel);
	class_addMethod(toClass, sel, method_getImplementation(_m), method_getTypeEncoding(_m));
}

#define COPY_METHOD(FROM_CLASS, TO_CLASS, SEL) \
		ComBelkadanKeystone_copyMethod(FROM_CLASS, TO_CLASS, @selector(SEL))

#define EXCHANGE(CLASS, PREFIX, SEL) \
		[CLASS jr_swizzleMethod:@selector(SEL) withMethod:@selector(_CONCAT(PREFIX, SEL)) error:NULL]

#define COPY_AND_EXCHANGE(FROM_CLASS, TO_CLASS, PREFIX, SEL) \
		(COPY_METHOD(FROM_CLASS, TO_CLASS, _CONCAT(PREFIX, SEL)), \
		EXCHANGE(TO_CLASS, PREFIX, SEL))
