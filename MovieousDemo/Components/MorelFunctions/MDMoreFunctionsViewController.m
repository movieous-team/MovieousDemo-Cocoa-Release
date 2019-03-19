//
//  MDMoreFunctionsViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDMoreFunctionsViewController.h"
#import "MDGlobalSettings.h"

@interface MDMoreFunctionsViewController ()

@end

@implementation MDMoreFunctionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

@end

@interface MDSettingsViewController : UITableViewController

@end

@implementation MDSettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        cell.detailTextLabel.text = getVendorName(MDGlobalSettings.sharedInstance.vendorType);
    }
}

@end

@interface MDVendorSelectionViewController : UIViewController
<
UIPickerViewDataSource,
UIPickerViewDelegate
>

@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;

@end

@implementation MDVendorSelectionViewController

- (void)viewDidLoad {
    [_pickerView selectRow:(NSInteger)MDGlobalSettings.sharedInstance.vendorType inComponent:0 animated:NO];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 4;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return getVendorName(row);
}

- (IBAction)saveButtonPressed:(UIButton *)sender {
    MDGlobalSettings.sharedInstance.vendorType = [_pickerView selectedRowInComponent:0];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
