//
//  MasterViewController.m
//  ObjectiveGit-Demo
//
//  Created by Chris Nielubowicz on 10/31/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "GitHistoryManager.h"

@import ObjectiveGit;

@interface MasterViewController () <UITextViewDelegate>

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UITextView *committedText;
@property (assign, nonatomic) NSInteger commitIndex;
@property NSMutableArray<GTCommit *> *objects;

@end

@implementation MasterViewController

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"commitIndex"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.commitIndex = 0;
    [self addObserver:self forKeyPath:@"commitIndex" options:NSKeyValueObservingOptionNew context:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.objects = [[[GitHistoryManager sharedInstance] commitHistory] mutableCopy];
    [self.committedText setText:[[GitHistoryManager sharedInstance] loadCurrentData]];
    self.tableView.tableHeaderView = self.headerView;
    [self.tableView reloadData];
}

- (UIView *)headerView {
    if (_headerView == nil) {
        CGSize tableViewSize = self.tableView.bounds.size;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableViewSize.width, 132)];
        [_headerView addSubview:self.committedText];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 88, tableViewSize.width, 44)];
        NSArray<UIBarButtonItem *> *items = @[
                                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                                                            target:self action:@selector(moveToPreviousCommit)],
                                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                                            target:self action:@selector(moveToNextCommit)],
                                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                            target:self action:@selector(restoreToHead)]
                                              ];
        [toolbar setItems:items];
        [_headerView addSubview:toolbar];
    }

    return _headerView;
}

- (UITextView *)committedText {
    if (_committedText == nil) {
        CGSize tableViewSize = self.tableView.bounds.size;
        _committedText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableViewSize.width, 88)];
        [_committedText setEditable:YES];
        [_committedText setDelegate:self];
    }

    return _committedText;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    [self.tableView beginUpdates];
    [self.objects insertObject:object atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        GTCommit *commit = self.objects[indexPath.row];
        NSString *fileData = [[GitHistoryManager sharedInstance] loadDataFromCommit:commit];

        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:fileData];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}


#pragma mark - Toolbar methods

- (void)moveToNextCommit {
    if (self.commitIndex <= 0) {
        return;
    }
    
    self.commitIndex--;
}

- (void)moveToPreviousCommit {
    if (self.commitIndex >= self.objects.count) {
        return;
    }
    
    self.commitIndex++;
}

- (void)restoreToHead {
    self.commitIndex = 0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    GTCommit *commit = self.objects[self.commitIndex];
    NSString *dataString = [[GitHistoryManager sharedInstance] loadDataFromCommit:commit];
    [self.committedText setText:dataString];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    GTCommit *commit = self.objects[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ at %@", [commit message], [commit commitDate]];
    cell.detailTextLabel.text = commit.author.name;
    
    return cell;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    GTCommit *newCommit = [[GitHistoryManager sharedInstance] saveData:textView.text];
    [self insertObject:newCommit atIndex:0];
}

@end
