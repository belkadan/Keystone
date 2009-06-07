#import <Cocoa/Cocoa.h>

/*!
 * A mutable "array" that keeps its elements in sorted order (but allows duplicates).
 * Algorithms that would require linear search have been replaced with binary search.
 * No real performance testing has been done...hopefully it will be in the future.
 *
 * Also, not KVO-compliant.
 */
@interface ComBelkadanUtils_SortedArray : NSArray {
  NSArray *sortDescriptors;
  NSMutableArray *backing;
}
/*! Create a new array with the sort key "self". */
- (id)init;
/*! Create a new array with the given sort key. */
- (id)initWithPrimarySortKey:(NSString *)sortKey;
/*! Create a new array with the given sort descriptors. This is the designated initializer. */
- (id)initWithSortDescriptors:(NSArray *)descriptors;

/*! Calls -indexOfObject:inRange:positionOnly:, with the entire array as the range. */
- (NSUInteger)indexOfObject:(id)object positionOnly:(BOOL)ignoreNotFound;

/*!
 * Returns the index of the given object, if it is within the provided range.
 * If there is no such object in the array and ignoreNotFound is NO, returns NSNotFound.
 * If ignoreNotFound is YES, returns the index where the object would be inserted.
 */
- (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range positionOnly:(BOOL)ignoreNotFound;

/*!
 * Calls -indexOfObjectWithPrimarySortValue:inRange:positionOnly: with the entire array
 * as the range, and requiring that such an object actually be found.
 */
- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue;

/*!
 * Calls -indexOfObjectWithPrimarySortValue:inRange:positionOnly: with the entire array
 * as the range.
 */
- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue positionOnly:(BOOL)ignoreNotFound;

/*!
 * Returns the index of the first object with the given search value as its primary sort value
 * in the provided range.
 * If there is no such object in the array and ignoreNotFound is NO, returns NSNotFound. 
 * If ignoreNotFound is YES, returns the index where an object with that sort value would be inserted.
 */
- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue inRange:(NSRange)range positionOnly:(BOOL)ignoreNotFound;

/*!
 * Used to notify the array that a given object changed its sort values. Resorts
 * the array as necessary and returns the object's new index.
 */
- (NSUInteger)objectDidChangeAtIndex:(NSUInteger)index;

/*! The array's sort descriptors. If changed, the array is resorted. */
@property(readwrite,copy) NSArray *sortDescriptors;
@end

#pragma mark -

/*! General operations of mutable arrays with potentially enforced ordering. */
@protocol ComBelkadanUtils_OrderedMutableArray <NSObject>
- (void)addObject:(id)object;
- (void)addObjectsFromArray:(NSArray *)otherArray;

- (void)removeAllObjects;
- (void)removeLastObject;
- (void)removeObject:(id)object;
- (void)removeObject:(id)anObject inRange:(NSRange)aRange;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes;
- (void)removeObjectIdenticalTo:(id)anObject;
- (void)removeObjectIdenticalTo:(id)anObject inRange:(NSRange)aRange;
- (void)removeObjectsInArray:(NSArray *)otherArray;
- (void)removeObjectsInRange:(NSRange)aRange;

- (void)filterUsingPredicate:(NSPredicate *)predicate;
@end

/*! These sorted arrays can handle all of these operations. */
@interface ComBelkadanUtils_SortedArray (BorrowedFromNSMutableArray) <ComBelkadanUtils_OrderedMutableArray>
@end

/*! As can normal mutable arrays */
@interface NSMutableArray (ComBelkadanUtils_OrderedArray) <ComBelkadanUtils_OrderedMutableArray>
@end
