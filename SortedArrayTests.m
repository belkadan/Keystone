#import <SenTestingKit/SenTestingKit.h>
#import "SortedArray.h"

@interface SortedArrayTests : SenTestCase {
	ComBelkadanUtils_SortedArray *evens;
}
@end

@implementation SortedArrayTests
- (void)setUp {
	evens = [[ComBelkadanUtils_SortedArray alloc] init];
	for (int i = 2; i < 100; i += 2) {
		[evens addObject:[NSNumber numberWithInt:i]];
	}
}

- (void)tearDown {
	[evens release];
}

#pragma mark -

- (void)testSimpleInit {
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] init];
	STAssertEqualObjects(array.sortDescriptors, [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES] autorelease]], @"");
	[array release];
}

- (void)testSingleKeyInit {
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] initWithPrimarySortKey:@"identifier"];
	STAssertEqualObjects(array.sortDescriptors, [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES] autorelease]], @"");
	[array release];
}

- (void)testFullInit {
	NSArray *descriptors = [NSArray arrayWithObjects:
		[[[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:@"source" ascending:YES] autorelease],
		nil];
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] initWithSortDescriptors:descriptors];
	STAssertEqualObjects(array.sortDescriptors, descriptors, @"");
	[array release];
}

#pragma mark -

- (void)testSearchForAPresentItem {
	for (NSUInteger i = 2; i < 100; i += 2) {
		STAssertEquals([evens indexOfObject:[NSNumber numberWithInt:i]], (i / 2) - 1, @"%u (not ignoring not found)", i);
	}

	for (NSUInteger i = 2; i < 100; i += 2) {
		STAssertEquals([evens indexOfObject:[NSNumber numberWithInt:i] positionOnly:YES], (i / 2) - 1, @"%u (ignoring not found)", i);
	}
}

- (void)testSearchForAnAbsentItem {
	for (NSUInteger i = 1; i < 100; i += 2) {
		STAssertTrue([evens indexOfObject:[NSNumber numberWithInt:i]] == NSNotFound, @"(not ignoring not found)", i);
	}

	for (NSUInteger i = 1; i < 100; i += 2) {
		STAssertEquals([evens indexOfObject:[NSNumber numberWithInt:i] positionOnly:YES], i / 2, @"%u (ignoring not found)", i);
	}
}

- (void)testSearchForAPresentSortValue {
	for (NSUInteger i = 2; i < 100; i += 2) {
		STAssertEquals([evens indexOfObjectWithPrimarySortValue:[NSNumber numberWithInt:i]], (i / 2) - 1, @"%u (not ignoring not found)", i);
	}

	for (NSUInteger i = 2; i < 100; i += 2) {
		STAssertEquals([evens indexOfObjectWithPrimarySortValue:[NSNumber numberWithInt:i] positionOnly:YES], (i / 2) - 1, @"%u (ignoring not found)", i);
	}
}

- (void)testSearchForAnAbsentSortValue {
	for (NSUInteger i = 1; i < 100; i += 2) {
		STAssertTrue([evens indexOfObjectWithPrimarySortValue:[NSNumber numberWithInt:i]] == NSNotFound, @"(not ignoring not found)", i);
	}

	for (NSUInteger i = 1; i < 100; i += 2) {
		STAssertEquals([evens indexOfObjectWithPrimarySortValue:[NSNumber numberWithInt:i] positionOnly:YES], i / 2, @"%u (ignoring not found)", i);
	}
}

#pragma mark -

- (void)testCopy {
	id copy = [evens copy];
	STAssertEqualObjects(copy, evens, @"immutable copy");
	[copy release];
}

- (void)testAddAnArrayOfObjects {
	NSMutableArray *odds = [[NSMutableArray alloc] init];
	for (int i = 99; i > 0; i -= 2) {
		[odds addObject:[NSNumber numberWithInt:i]];
	}
	
	[evens addObjectsFromArray:odds];
	[odds release];
	
	NSMutableArray *expected = [[NSMutableArray alloc] init];
	for (int i = 1; i < 100; i += 1) {
		[expected addObject:[NSNumber numberWithInt:i]];
	}
	
	STAssertEqualObjects(evens, expected, @"mixed odds and evens now");
	[expected release];
}

- (void)testUpdatingFirstElement {
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] init];
	for (int i = 1; i < 100; i += 1) {
		[array addObject:[NSMutableString stringWithFormat:@"%02d", i]];
	}
		
	NSMutableArray *referenceArray = [[NSMutableArray alloc] initWithArray:array];
	
	[[array objectAtIndex:0] setString:@"01a"];
	[array objectDidChangeAtIndex:0];
	[referenceArray replaceObjectAtIndex:0 withObject:@"01a"];
	STAssertEqualObjects(array, referenceArray, @"no change in position");
	
	[[array objectAtIndex:0] setString:@"25a"];
	[array objectDidChangeAtIndex:0];
	[referenceArray removeObjectAtIndex:0];
	[referenceArray insertObject:@"25a" atIndex:24];
	STAssertEqualObjects(array, referenceArray, @"move to middle");
	
	[[array objectAtIndex:0] setString:@"99a"];
	[array objectDidChangeAtIndex:0];
	[referenceArray removeObjectAtIndex:0];
	[referenceArray addObject:@"99a"];
	STAssertEqualObjects(array, referenceArray, @"move to end");
}

- (void)testUpdatingMiddleElement {
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] init];
	for (int i = 1; i < 100; i += 1) {
		[array addObject:[NSMutableString stringWithFormat:@"%02d", i]];
	}
		
	NSMutableArray *referenceArray = [[NSMutableArray alloc] initWithArray:array];
	
	[[array objectAtIndex:25] setString:@"25a"];
	[array objectDidChangeAtIndex:25];
	[referenceArray replaceObjectAtIndex:25 withObject:@"25a"];
	STAssertEqualObjects(array, referenceArray, @"no change in position");
	
	[[array objectAtIndex:25] setString:@"00"];
	[array objectDidChangeAtIndex:25];
	[referenceArray removeObjectAtIndex:25];
	[referenceArray insertObject:@"00" atIndex:0];
	STAssertEqualObjects(array, referenceArray, @"move to beginning");
	
	[[array objectAtIndex:25] setString:@"01a"];
	[array objectDidChangeAtIndex:25];
	[referenceArray removeObjectAtIndex:25];
	[referenceArray insertObject:@"01a" atIndex:2];
	STAssertEqualObjects(array, referenceArray, @"move left");
	
	[[array objectAtIndex:25] setString:@"97a"];
	[array objectDidChangeAtIndex:25];
	[referenceArray removeObjectAtIndex:25];
	[referenceArray insertObject:@"97a" atIndex:96];
	STAssertEqualObjects(array, referenceArray, @"move right");
	
	[[array objectAtIndex:25] setString:@"99a"];
	[array objectDidChangeAtIndex:25];
	[referenceArray removeObjectAtIndex:25];
	[referenceArray addObject:@"99a"];
	STAssertEqualObjects(array, referenceArray, @"move to end");
}

- (void)testUpdatingLastElement {
	ComBelkadanUtils_SortedArray *array = [[ComBelkadanUtils_SortedArray alloc] init];
	for (int i = 1; i < 100; i += 1) {
		[array addObject:[NSMutableString stringWithFormat:@"%02d", i]];
	}
		
	NSMutableArray *referenceArray = [[NSMutableArray alloc] initWithArray:array];
	
	[[array objectAtIndex:98] setString:@"99a"];
	[array objectDidChangeAtIndex:98];
	[referenceArray replaceObjectAtIndex:98 withObject:@"99a"];
	STAssertEqualObjects(array, referenceArray, @"no change in position");
	
	[[array objectAtIndex:98] setString:@"25a"];
	[array objectDidChangeAtIndex:98];
	[referenceArray removeObjectAtIndex:98];
	[referenceArray insertObject:@"25a" atIndex:25];
	STAssertEqualObjects(array, referenceArray, @"move to middle");
	
	[[array objectAtIndex:98] setString:@"00"];
	[array objectDidChangeAtIndex:98];
	[referenceArray removeObjectAtIndex:98];
	[referenceArray insertObject:@"00" atIndex:0];
	STAssertEqualObjects(array, referenceArray, @"move to beginning");
}

@end
