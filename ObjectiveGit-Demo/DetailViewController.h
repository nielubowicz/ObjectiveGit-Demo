//
//  DetailViewController.h
//  ObjectiveGit-Demo
//
//  Created by Chris Nielubowicz on 10/31/15.
//  Copyright © 2015 Mobiquity, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

