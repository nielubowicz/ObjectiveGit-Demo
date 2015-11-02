//
//  GitHistoryManager.m
//  ObjectiveGit-Demo
//
//  Created by Chris Nielubowicz on 10/31/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

#import "GitHistoryManager.h"

@import ObjectiveGit;

@interface GitHistoryManager ()

@property (nonatomic, strong, readwrite) GTRepository *repo;

@end

@implementation GitHistoryManager

static NSString *const gitHistoryFileName = @"emptyfile";

+ (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    return [basePath stringByAppendingPathComponent:@"GitHistoryManager"];
}

+ (instancetype)sharedInstance {
    static GitHistoryManager *sharedHistoryManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *repoURL = [NSURL fileURLWithPath:[GitHistoryManager applicationDocumentsDirectory]];
        sharedHistoryManager = [[GitHistoryManager alloc] initWithRepoURL:repoURL];
    });
    
    return sharedHistoryManager;
}

- (instancetype)initWithRepoURL:(NSURL *)repoURL {
    if (self = [super init]) {
        NSError *repoCreationError = nil;
        _repo = [GTRepository repositoryWithURL:repoURL error:&repoCreationError];
        if (repoCreationError) {
            NSLog(@"Error: '%@' creating git repo at %@.", repoCreationError.localizedDescription, [repoURL absoluteString]);
            repoCreationError = nil;
            
            _repo = [GTRepository initializeEmptyRepositoryAtFileURL:repoURL options:nil error:&repoCreationError];
            if (repoCreationError) {
                NSLog(@"Error: '%@' creating git repo at %@.", repoCreationError.localizedDescription, [repoURL absoluteString]);
                self = nil;
            }
        }
    }
    return self;
}

- (void)saveDataToBareRepo:(NSString *)data {

    NSError *saveDataError;
    
    GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:nil repository:self.repo error:&saveDataError];
    if (saveDataError) {
        NSLog(@"Error creating treeBuilder: %@", saveDataError.localizedDescription);
        saveDataError = nil;
    }

    GTTreeEntry *treeEntry = [treeBuilder addEntryWithData:[data dataUsingEncoding:NSUTF8StringEncoding] fileName:gitHistoryFileName fileMode:GTFileModeBlob error:&saveDataError];
    if (saveDataError) {
        NSLog(@"Error creating tree entry from string:%@, %@", data, saveDataError.localizedDescription);
        saveDataError = nil;
    }

    GTTree *tree = [[GTTree alloc] initWithTreeEntry:treeEntry error:&saveDataError];
    if (saveDataError) {
        NSLog(@"Error creating tree: %@", saveDataError.localizedDescription);
        saveDataError = nil;
    }
    
    GTSignature *committer = [[GTSignature alloc] initWithName:@"Chris Nielubowicz"
                                                          email:@"cnielubowicz@mobiquityinc.com"
                                                           time:[NSDate date]];
    GTSignature *author = committer;
    
    GTCommit *commit = [self.repo createCommitWithTree:tree
                                               message:@"Initial Commit"
                                                author:author
                                             committer:committer
                                               parents:nil
                                updatingReferenceNamed:@"refs/head/master"
                                                 error:&saveDataError];
    if (saveDataError) {
        NSLog(@"Error creating initial commit: %@", saveDataError.localizedDescription);
        saveDataError = nil;
    }

//    // Create a blob from the content stream
//    byte[] contentBytes = System.Text.Encoding.UTF8.GetBytes(content);
//    MemoryStream ms = new MemoryStream(contentBytes);
//    Blob newBlob = repo.ObjectDatabase.CreateBlob(ms);
//    
//    // Put the blob in a tree
//    TreeDefinition td = new TreeDefinition();
//    td.Add("filePath.txt", newBlob, Mode.NonExecutableFile);
//    Tree tree = repo.ObjectDatabase.CreateTree(td);
//    
//    // Committer and author
//    Signature committer = new Signature("James", "@jugglingnutcase", DateTime.Now);
//    Signature author = committer;
//    
//    // Create binary stream from the text
//    Commit commit = repo.ObjectDatabase.CreateCommit(
//                                                     "i'm a commit message :)",
//                                                     author,
//                                                     committer,
//                                                     tree,
//                                                     repo.Commits);
//    
//    // Update the HEAD reference to point to the latest commit
//    repo.Refs.UpdateTarget(repo.Refs.Head, commit.Id);
}

- (GTCommit *)saveData:(NSString *)data {
    GTReference *head = [self.repo headReferenceWithError:NULL];
    GTCommit *headCommit = [self.repo lookUpObjectByOID:head.targetOID error:NULL];
    
    GTSignature *committer = [[GTSignature alloc] initWithName:@"Chris Nielubowicz"
                                                         email:@"cnielubowicz@mobiquityinc.com"
                                                          time:[NSDate date]];
    GTSignature *author = committer;
    
    
    GTBlob *blob = [GTBlob blobWithString:data inRepository:self.repo error:NULL];
    GTIndex *index = [self.repo indexWithError:NULL];
    [index addData:blob.data withPath:gitHistoryFileName error:NULL];

    GTCommit *newCommit = [self.repo createCommitWithTree:[index writeTreeToRepository:self.repo error:NULL]
                                                  message:@"Saving Data"
                                                   author:author
                                                committer:committer
                                                  parents:@[headCommit]
                                   updatingReferenceNamed:@"HEAD" error:NULL];
    return newCommit;
}

- (NSString *)loadDataFromCommit:(GTCommit *)commit {
    GTTreeEntry *treeEntry = [commit.tree entryWithName:gitHistoryFileName];
    NSString *blobSHA = [treeEntry SHA];
    
    GTBlob *blob = [self.repo lookUpObjectBySHA:blobSHA error:NULL];
    NSString *dataTarget = blob.content;
    return dataTarget;
}

- (NSString *)loadCurrentData {
    GTReference *head = [self.repo headReferenceWithError:NULL];
    GTCommit *commit = [self.repo lookUpObjectByOID:head.targetOID error:NULL];
    NSString *currentDataTarget = [self loadDataFromCommit:commit];
    return currentDataTarget;
}

- (NSArray<GTCommit *> *)commitHistory {
    NSError *enumeratorError;
    GTEnumerator *enumerator = [[GTEnumerator alloc] initWithRepository:self.repo error:&enumeratorError];
    if (enumeratorError) {
        NSLog(@"Error creating enumerator for repo: %@", enumeratorError.localizedDescription);
        enumeratorError = nil;
    }

    GTReference *headRef = [self.repo headReferenceWithError:&enumeratorError];
    if (enumeratorError) {
        NSLog(@"Error getting head reference for repo: %@", enumeratorError.localizedDescription);
        enumeratorError = nil;
    }
    
    [enumerator pushSHA:headRef.targetOID.SHA error:&enumeratorError];
    if (enumeratorError) {
        NSLog(@"Error moving to headRef in repo: %@", enumeratorError.localizedDescription);
        enumeratorError = nil;
    }

    NSArray<GTCommit *> *commits = [enumerator allObjectsWithError:&enumeratorError];
    if (enumeratorError) {
        NSLog(@"Error getting commits for repo: %@", enumeratorError.localizedDescription);
        enumeratorError = nil;
    }
    
    return commits;
}

@end
