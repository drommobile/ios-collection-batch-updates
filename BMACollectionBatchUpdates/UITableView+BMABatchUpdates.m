/*
 The MIT License (MIT)
 
 Copyright (c) 2015-present Badoo Trading Limited.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "UITableView+BMABatchUpdates.h"
#import "BMACollectionUpdates.h"

@implementation UITableView (BMABatchUpdates)

- (void)bma_performBatchUpdates:(nullable NSArray<BMACollectionUpdate *> *)updates
       applyChangesToModelBlock:(nullable void (^)(void))applyChangesToModelBlock
                reloadCellBlock:(nullable void (^)(UITableViewCell *cell, NSIndexPath *indexPath))reloadCellBlock
                completionBlock:(nullable void (^)(void))completionBlock {
    [self bma_performBatchUpdates:updates
                rowAnimationBlock:nil
         applyChangesToModelBlock:applyChangesToModelBlock
                  reloadCellBlock:reloadCellBlock
                  completionBlock:completionBlock];
}

- (void)bma_performBatchUpdates:(NSArray<BMACollectionUpdate *> *)updates
              rowAnimationBlock:(UITableViewRowAnimation (^)(BMACollectionUpdate *update))rowAnimationBlock
       applyChangesToModelBlock:(void (^)(void))applyChangesToModelBlock
                reloadCellBlock:(void (^)(UITableViewCell *cell, NSIndexPath *indexPath))reloadCellBlock
                completionBlock:(void (^)(void))completionBlock {
    if (!updates) {
        if (applyChangesToModelBlock) {
            applyChangesToModelBlock();
        }
        [self reloadData];
        if (completionBlock) {
            completionBlock();
        }
        return;
    }

    if (completionBlock) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:completionBlock];
    }

    [self beginUpdates];

    if (applyChangesToModelBlock) {
        applyChangesToModelBlock();
    }

    for (BMACollectionUpdate *update in updates) {
        UITableViewRowAnimation animation;
        if (rowAnimationBlock) {
            animation = rowAnimationBlock(update);
        } else {
            animation = UITableViewRowAnimationAutomatic;
        }
        if ([update isItemUpdate]) {
            BMACollectionItemUpdate *itemUpdate = (BMACollectionItemUpdate *)update;
            switch (update.type) {
                case BMACollectionUpdateTypeReload: {
                    if (reloadCellBlock) {
                        UITableViewCell *cell = [self cellForRowAtIndexPath:itemUpdate.indexPath];
                        if (cell) {
                            reloadCellBlock(cell, itemUpdate.indexPath);
                        }
                    }
                    break;
                }
                case BMACollectionUpdateTypeDelete:
                    [self deleteRowsAtIndexPaths:@[ itemUpdate.indexPath ]
                                withRowAnimation:animation];
                    break;
                case BMACollectionUpdateTypeInsert:
                    [self insertRowsAtIndexPaths:@[ itemUpdate.indexPathNew ]
                                withRowAnimation:animation];
                    break;
                case BMACollectionUpdateTypeMove:
                case BMACollectionUpdateTypeMoveAndReload:
                    [self moveRowAtIndexPath:itemUpdate.indexPath
                                 toIndexPath:itemUpdate.indexPathNew];
                    break;
                default:
                    break;
            }
        } else if ([update isSectionUpdate]) {
            BMACollectionSectionUpdate *sectionUpdate = (BMACollectionSectionUpdate *)update;
            switch (update.type) {
                case BMACollectionUpdateTypeReload:
                    [self reloadSections:[NSIndexSet indexSetWithIndex:sectionUpdate.sectionIndex]
                        withRowAnimation:animation];
                    break;
                case BMACollectionUpdateTypeDelete:
                    [self deleteSections:[NSIndexSet indexSetWithIndex:sectionUpdate.sectionIndex]
                        withRowAnimation:animation];
                    break;
                case BMACollectionUpdateTypeInsert:
                    [self insertSections:[NSIndexSet indexSetWithIndex:sectionUpdate.sectionIndexNew]
                        withRowAnimation:animation];
                    break;
                case BMACollectionUpdateTypeMove:
                    [self moveSection:sectionUpdate.sectionIndex
                            toSection:sectionUpdate.sectionIndexNew];
                    break;
                default:
                    break;
            }
        }
    }

    [self endUpdates];

    [self beginUpdates];
    for (BMACollectionUpdate *update in updates) {
        if ([update isItemUpdate]) {
            BMACollectionItemUpdate *itemUpdate = (BMACollectionItemUpdate *)update;
            if (update.type == BMACollectionUpdateTypeMoveAndReload) {
                if (reloadCellBlock) {
                    UITableViewCell *cell = [self cellForRowAtIndexPath:itemUpdate.indexPathNew];
                    if (cell) {
                        reloadCellBlock(cell, itemUpdate.indexPathNew);
                    }
                }
            }
        }
    }
    [self endUpdates];

    if (completionBlock) {
        [CATransaction commit];
    }
}

@end
