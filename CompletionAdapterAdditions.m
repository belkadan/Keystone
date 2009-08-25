#import "CompletionAdapterAdditions.h"

#import "CompletionControllers.h"
#import "CompletionHandler.h"
#import "FakeCompletionItem.h"

#import "SortedArray.h"

#import "SwizzleMacros.h"

#define KEYSTONE_PREFIX ComBelkadanKeystone_


@implementation ComBelkadanKeystone_CompletionControllerObjCAdapter
+ (void)initialize {
  if (![CompletionControllerObjCAdapter instancesRespondToSelector:@selector(_CONCAT(KEYSTONE_PREFIX, numberOfRowsInTableView:))]) {
    Class fromClass = [self class];
    Class toClass = [CompletionControllerObjCAdapter class];
		
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:objectValueForTableColumn:row:);
		COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, completionListTableView:rowIsChecked:);
	}
}

#pragma mark -

- (id)ComBelkadanKeystone_tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
  ComBelkadanKeystone_FakeCompletionItem *item = [[_completionControllerObjC currentListItems] objectAtIndex:rowIndex];
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    return [_completionControllerObjC displayedStringForListItem:item column:[[tableView tableColumns] indexOfObject:tableColumn] row:rowIndex];
  } else {
    return [self ComBelkadanKeystone_tableView:tableView objectValueForTableColumn:tableColumn row:rowIndex];
  }
}

- (BOOL)ComBelkadanKeystone_completionListTableView:(NSTableView *)tableView rowIsChecked:(NSInteger)rowIndex {
  ComBelkadanKeystone_FakeCompletionItem *item = [[_completionControllerObjC currentListItems] objectAtIndex:rowIndex];
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
		return NO; // no check marks on Keystone completion items
	} else {
		return [self ComBelkadanKeystone_completionListTableView:tableView rowIsChecked:rowIndex];
	}
}
@end
