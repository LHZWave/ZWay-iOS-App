//
//  ZWayProfilesViewController.h
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/21/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ZWayProfilesViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSMutableArray *colors;
}

@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSFetchedResultsController *fetchController;
@property (strong, nonatomic) NSString *editing;
@property (strong, nonatomic) UIPickerView *colorPicker;

- (void)addProfile:(id)sender;
- (void)bringUpPickerViewWithRow:(NSIndexPath*)indexPath;
- (void)hidePickerView;
- (void)updateColor:(NSString*)color;

@end
