#import "SortedArray.h"

@interface NSObject ()
- (id)forwardingTargetForSelector:(SEL)selector; /* why isn't this in the NSObject headers yet? */
@end

static NSComparisonResult compareUsingSortDescriptors (id left, id right, NSArray *descriptors) {
  NSComparisonResult result = NSOrderedSame;
  
  for (NSSortDescriptor *next in descriptors) {
    result = [next compareObject:left toObject:right];
    if (result != NSOrderedSame) return result;
  }
  
  return result;
}

@implementation ComBelkadanUtils_SortedArray
- (id)init {
  return [self initWithPrimarySortKey:@"self"];
}

- (id)initWithPrimarySortKey:(NSString *)sortKey {
  NSSortDescriptor *primaryDescriptor = [[NSSortDescriptor alloc] initWithKey:sortKey ascending:YES];
  NSArray *descriptors = [[NSArray alloc] initWithObjects:primaryDescriptor, nil];
  [primaryDescriptor release];

  self = [self initWithSortDescriptors:descriptors];
  [descriptors release];
  return self;
}

- (id)initWithSortDescriptors:(NSArray *)descriptors {
  if ((self = [super init])) {
    backing = [[NSMutableArray alloc] init];
    sortDescriptors = [descriptors copy];
  }
  
  return self;
}

- (void)dealloc {
  [backing release];
  [sortDescriptors release];
  [super dealloc];
}

- (void)setSortDescriptors:(NSArray *)newDescriptors {
  if (sortDescriptors != newDescriptors) {
    [sortDescriptors release];
    sortDescriptors = [newDescriptors copy];
    [backing sortUsingDescriptors:self.sortDescriptors];
  }
}

#pragma mark -

- (NSUInteger)count {
  return [backing count];
}

- (id)objectAtIndex:(NSUInteger)index {
  return [backing objectAtIndex:index];
}

- (BOOL)containsObject:(id)object {
  return [self indexOfObject:object] != NSNotFound;
}

- (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range {
  return [self indexOfObject:object inRange:range positionOnly:NO];
}

- (NSUInteger)indexOfObjectIdenticalTo:(id)object inRange:(NSRange)range {
  NSUInteger index = [self indexOfObject:object inRange:range];
  return (object == [self objectAtIndex:index]) ? index : NSNotFound;
}

#pragma mark -

// This cannot be put into forwardingTargetForSelector:...NSArray complains if you do.
- (void)addObject:(id)object {
  NSUInteger index = [self indexOfObject:object positionOnly:YES];
  [backing insertObject:object atIndex:index];
}

- (void)addObjectsFromArray:(NSArray *)otherArray {
  [backing addObjectsFromArray:otherArray];
  [backing sortUsingDescriptors:sortDescriptors];
}

- (id)forwardingTargetForSelector:(SEL)sel {
  if (sel == @selector(filterUsingPredicate:)) {
    return backing;
  } else if ([NSStringFromSelector(sel) hasPrefix:@"remove"]) {
    return backing;
  } else {
    return [super forwardingTargetForSelector:sel];
  }
}

#pragma mark -

- (NSUInteger)indexOfObject:(id)object positionOnly:(BOOL)ignoreNotFound {
  return [self indexOfObject:object inRange:NSMakeRange(0, [self count]) positionOnly:ignoreNotFound];
}

- (NSUInteger)indexOfObject:(id)object inRange:(NSRange)range positionOnly:(BOOL)ignoreNotFound {
  // From http://en.wikipedia.org/wiki/Binary_search#Recursive
  NSUInteger probe;
  NSUInteger found = NSNotFound;
  NSComparisonResult compared;
  id testObject;
  
  while (range.length != 0) {
    probe = range.location + ((range.length - 1) / 2);
    testObject = [self objectAtIndex:probe];
    compared = compareUsingSortDescriptors(object, testObject, self.sortDescriptors);
    
    switch (compared) {
    case NSOrderedSame:
      if ([testObject isEqual:object]) found = probe; // either way, continue to find the FIRST one
    case NSOrderedAscending:
      if (ignoreNotFound) found = probe; // closest, anyway
      range.length = probe - range.location;
      break;
    case NSOrderedDescending:
      range.length -= (probe + 1 - range.location);
      range.location = probe + 1;
      break;
    }
  }
  
  return (found == NSNotFound && ignoreNotFound) ? range.location : found;
}

- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue {
  return [self indexOfObjectWithPrimarySortValue:searchValue inRange:NSMakeRange(0, [self count]) positionOnly:NO];
}

- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue positionOnly:(BOOL)ignoreNotFound {
  return [self indexOfObjectWithPrimarySortValue:searchValue inRange:NSMakeRange(0, [self count]) positionOnly:ignoreNotFound];
}

- (NSUInteger)indexOfObjectWithPrimarySortValue:(id)searchValue inRange:(NSRange)range positionOnly:(BOOL)ignoreNotFound {
  // From http://en.wikipedia.org/wiki/Binary_search#Recursive
  NSUInteger probe;
  NSUInteger found = NSNotFound;
  NSComparisonResult compared;
  id testValue;
  
  NSSortDescriptor *firstDesc = [self.sortDescriptors objectAtIndex:0];
  NSString *key = [firstDesc key];
  NSSortDescriptor *selfComparingDesc = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:[firstDesc ascending] selector:[firstDesc selector]];
  
  while (range.length != 0) {
    probe = range.location + ((range.length - 1) / 2);
    testValue = [[self objectAtIndex:probe] valueForKey:key];
    compared = [selfComparingDesc compareObject:searchValue toObject:testValue];
    
    switch (compared) {
    case NSOrderedSame:
      if ([searchValue isEqual:testValue]) found = probe; // either way, continue to find the FIRST one
    case NSOrderedAscending:
      if (ignoreNotFound) found = probe; // closest, anyway
      range.length = probe - range.location;
      break;
    case NSOrderedDescending:
      range.length -= (probe + 1 - range.location);
      range.location = probe + 1;
      break;
    }
  }
  
  [selfComparingDesc release];
  return (found == NSNotFound && ignoreNotFound)  ? range.location : found;
}

#pragma mark -

- (NSUInteger)objectDidChangeAtIndex:(NSUInteger)index {
  id object = [backing objectAtIndex:index];
  
  // Only change if we need to...
  BOOL leftOK = (index == 0);
  if (!leftOK) leftOK = (NSOrderedDescending != compareUsingSortDescriptors([backing objectAtIndex:index-1], object, sortDescriptors));
  
  BOOL rightOK = (index == ([backing count] - 1));
  if (!rightOK) rightOK = (NSOrderedDescending != compareUsingSortDescriptors(object, [backing objectAtIndex:index+1], sortDescriptors));
  
  if (leftOK && rightOK) {
    return index;
  } else {
    [object retain];
    
    [backing removeObjectAtIndex:index];
    NSUInteger newIndex = [self indexOfObject:object positionOnly:YES];
    [backing insertObject:object atIndex:newIndex];
    
    [object release];
    return newIndex;
  }
}

@synthesize sortDescriptors;
@end
