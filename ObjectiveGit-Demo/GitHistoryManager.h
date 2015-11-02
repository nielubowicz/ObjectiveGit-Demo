//
//  GitHistoryManager.h
//  ObjectiveGit-Demo
//
//  Created by Chris Nielubowicz on 10/31/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTRepository;
@class GTCommit;

@interface GitHistoryManager : NSObject

@property (nonatomic, strong, readonly) GTRepository *repo;

+ (instancetype)sharedInstance;
- (GTCommit *)saveData:(NSString *)data;

- (NSString *)loadCurrentData;
- (NSString *)loadDataFromCommit:(GTCommit *)commit;

- (NSArray<GTCommit *> *)commitHistory;

@end
