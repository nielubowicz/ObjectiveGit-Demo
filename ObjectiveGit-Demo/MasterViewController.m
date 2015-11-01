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

@property (strong, nonatomic) UITextView *committedText;

@property NSMutableArray<GTCommit *> *objects;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    NSLog([[GitHistoryManager sharedInstance] loadCurrentData]);
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.objects = [[[GitHistoryManager sharedInstance] commitHistory] mutableCopy];
    [self.committedText setText:[[GitHistoryManager sharedInstance] loadCurrentData]];
    self.tableView.tableHeaderView = self.committedText;
    [self.tableView reloadData];
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
    [[GitHistoryManager sharedInstance] saveData:textView.text];
}

@end
