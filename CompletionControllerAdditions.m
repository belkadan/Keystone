#import "CompletionControllerAdditions.h"
#import "FakeCompletionItem.h"
#import "CompletionHandler.h"
#import "SortedArray.h"
#import "JRSwizzle.h"
#import <objc/runtime.h>

#define KEYSTONE_PREFIX ComBelkadanKeystone_


#define _CONCAT(A, B) A ## B

#define COPY_METHOD(FROM_CLASS, TO_CLASS, SEL) do { \
    Method _m = class_getInstanceMethod(FROM_CLASS, @selector(SEL)); \
    class_addMethod(TO_CLASS, @selector(SEL), method_getImplementation(_m), method_getTypeEncoding(_m)); \
  } while (NO)

#define EXCHANGE(CLASS, PREFIX, SEL) do { \
    NSError *_err = NULL; \
    [CLASS jr_swizzleMethod:@selector(SEL) withMethod:@selector(_CONCAT(PREFIX, SEL)) error:&_err]; \
    if (_err) NSLog(@"Unable to swizzle method %@; this may cause major problems with Safari!", NSStringFromSelector(@selector(SEL))); \
  } while (NO)

#define COPY_AND_EXCHANGE(FROM_CLASS, TO_CLASS, PREFIX, SEL) do { \
    COPY_METHOD(FROM_CLASS, TO_CLASS, _CONCAT(PREFIX, SEL)); \
    EXCHANGE(TO_CLASS, PREFIX, SEL); \
  } while (NO)
  
@interface NSObject (ComBelkadanKeystone_StopWarnings)
- (IBAction)goToToolbarLocation:(NSTextField *)sender;
@end


static NSArray <ComBelkadanUtils_OrderedMutableArray> *additionalCompletions = nil; 

@implementation ComBelkadanKeystone_URLCompletionController
+ (void)initialize {
  if (![URLCompletionController respondsToSelector:@selector(ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:)]) {
    additionalCompletions = [[ComBelkadanUtils_SortedArray alloc] initWithPrimarySortKey:@"headerTitle"];
    
    Class fromClass = [self class];
    Class toClass = [URLCompletionController class];
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, initWithSourceField:);
    
    COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_goToToolbarLocation:);
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, computeListItemsAndInitiallySelectedIndex:);
    COPY_METHOD(fromClass, toClass, ComBelkadanKeystone_firstItemForQuery:);
    
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, listItemIsSeparator:);
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, listItemIsSelectable:);
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, reflectSelectedListItem);
    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, activateSelectedListItem);

    COPY_AND_EXCHANGE(fromClass, toClass, KEYSTONE_PREFIX, tableView:objectValueForTableColumn:row:);
  }
}

+ (void)addCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler {
  [additionalCompletions addObject:handler];
}

+ (void)removeCompletionHandler:(id <ComBelkadanKeystone_CompletionHandler>)handler {
  [additionalCompletions removeObject:handler];
}

#pragma mark -

/*!
 * Swizzle-wrapped: if we can safely hijack the location bar's action, do it for
 * better UX. It's only safe, though, if our intermediate action can make a few
 * assumptions.
 *
 * Background: if you enter a query fast enough, the completion system doesn't
 * have time to come up, and you end up with a standard "can't be found" error.
 * This fixes that.
 */
- (id)ComBelkadanKeystone_initWithSourceField:(NSTextField *)field {
  self = [self ComBelkadanKeystone_initWithSourceField:field];
  if (self) {
    if ([field action] == @selector(goToToolbarLocation:) && [field target] == [field delegate]) {
      [field setTarget:self];
      [field setAction:@selector(ComBelkadanKeystone_goToToolbarLocation:)];
    }
  }
  return self;
}

/*! Swizzle-wrapped: add fake completion items from all sources following existing completions */
- (NSArray *)ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:(NSUInteger *)indexRef {
  NSMutableArray *results = [[self ComBelkadanKeystone_computeListItemsAndInitiallySelectedIndex:indexRef] mutableCopy];
  
  NSString *query = [self queryString];
  for (id <ComBelkadanKeystone_CompletionHandler> nextHandler in additionalCompletions) {
    NSArray *customCompletions = [nextHandler completionsForQueryString:query];
    
    if ([customCompletions count] > 0) {
      if ([results count] > 0) {
        [results addObject:[ComBelkadanKeystone_FakeCompletionItem separatorItem]];
        
      } else if ([self startsWithFirstItemSelected]) {
        NSUInteger index = [self completionListActsLikeMenu] ? 1 : 0;
        
        if (indexRef) {
          for (ComBelkadanKeystone_FakeCompletionItem *item in customCompletions) {
            if ([item canBeFirstSelectedForQueryString:query]) {
              *indexRef = index;
              break;
            }
            index += 1;
          }
        }
      }

      if ([self completionListActsLikeMenu]) {
        NSString *title = [nextHandler headerTitle];
        if (title) {
          ComBelkadanKeystone_FakeCompletionItem *headerItem = [[ComBelkadanKeystone_SimpleCompletionItem alloc] initWithName:title URLString:nil];
          [results addObject:headerItem];
          [headerItem release];
        }
      }

      [results addObjectsFromArray:customCompletions];
    }
  }

  return [results autorelease];
}

/*! Added: returns the first item available for query completion. */
- (ComBelkadanKeystone_FakeCompletionItem *)ComBelkadanKeystone_firstItemForQuery:(NSString *)queryString {
  ComBelkadanKeystone_FakeCompletionItem *supplied;
  for (id <ComBelkadanKeystone_CompletionHandler> nextHandler in additionalCompletions) {
    supplied = [nextHandler firstCompletionForQueryString:queryString];
    if (supplied) return supplied;
  }
  
  return nil;
}

/*! Swizzle-wrapped to handle fake completion items (item.isSeparator) */
- (BOOL)ComBelkadanKeystone_listItemIsSeparator:(ComBelkadanKeystone_FakeCompletionItem *)item {
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    return item.isSeparator;
    
  } else {
    return [self ComBelkadanKeystone_listItemIsSeparator:item];
  }
}

/*!
 * Swizzle-wrapped to handle fake completion items. Items are selectable if they
 * are not headers or separators.
 */
- (BOOL)ComBelkadanKeystone_listItemIsSelectable:(ComBelkadanKeystone_FakeCompletionItem *)item {
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    return !(item.isHeader || item.isSeparator);
    
  } else {
    return [self ComBelkadanKeystone_listItemIsSelectable:item];
  }
}

/*!
 * Swizzle-wrapped to handle fake completion items. Updates the location bar to
 * show the currently highlighted completion item.
 */
- (void)ComBelkadanKeystone_reflectSelectedListItem {
  ComBelkadanKeystone_FakeCompletionItem *item = [self selectedListItem];
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    NSInteger selectIndex = -1;
    NSString *replacement = [item reflectedStringForQueryString:[self queryString] withSelectionFrom:&selectIndex];
    [self replaceSourceFieldCharactersInRange:NSMakeRange(0, [[self sourceFieldString] length]) withString:replacement selectingFromIndex:selectIndex];
 
  } else {
    [self ComBelkadanKeystone_reflectSelectedListItem];
  }
}

/*!
 * Swizzle-wrapped to handle fake completion items. Updates the location bar to
 * the final destination, then invokes its action.
 */
- (BOOL)ComBelkadanKeystone_activateSelectedListItem {
  ComBelkadanKeystone_FakeCompletionItem *item = [self selectedListItem];
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    [self setSourceFieldString:[item urlStringForQueryString:[self queryString]]];
    [self performSourceFieldAction];
    return YES;
 
  } else {
    return [self ComBelkadanKeystone_activateSelectedListItem];
  }
}

/*!
 * Swizzle-wrapped to handle fake completion items. Returns the selected item's
 * name or preview URL.
 */
- (id)ComBelkadanKeystone_tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)rowIndex {
  ComBelkadanKeystone_FakeCompletionItem *item = [[self currentListItems] objectAtIndex:rowIndex];
  if ([item isKindOfClass:[ComBelkadanKeystone_FakeCompletionItem class]]) {
    if (![self completionListActsLikeMenu] || [@"1" isEqual:[column identifier]]) {
      return [item previewURLStringForQueryString:[self queryString]] ?: @"";
    } else {
      return [item nameForQueryString:[self queryString]];
    }
  } else {
    return [self ComBelkadanKeystone_tableView:tableView objectValueForTableColumn:column row:rowIndex];
  }
}

/*!
 * Action method for the location bar. Intercepts the action message and checks
 * to see if the user would have wanted a completion (seeing if the "query"
 * contains a space). If so, updates the location bar before sending the action
 * message to the /real/ target.
 *
 * This method assumes that the real target is the field's delegate, and that the
 * original action message was goToToolbarLocation:. If it's not, the controller
 * is set up to err on the side of caution and not replace the action method at all.
 */
- (IBAction)ComBelkadanKeystone_goToToolbarLocation:(NSTextField *)sender {
  if ([[self sourceFieldString] rangeOfString:@" "].location != NSNotFound) {
    NSString *query = [sender stringValue];
    ComBelkadanKeystone_FakeCompletionItem *item = [self ComBelkadanKeystone_firstItemForQuery:query];
    if (item) [sender setStringValue:[item urlStringForQueryString:query]];
  }

  [[sender delegate] goToToolbarLocation:sender];
}

@end


