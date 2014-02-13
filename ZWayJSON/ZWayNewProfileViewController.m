//
//  ZWayNewProfileViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/24/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayNewProfileViewController.h"
#import "ZWDataStore.h"
#import "CMProfile.h"
#import "ZWayAppDelegate.h"
#import "Reachability.h"

@interface ZWayNewProfileViewController ()

@end

@implementation ZWayNewProfileViewController

@synthesize tableview;
@synthesize editing;
@synthesize loaded;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ZWDataStore *store = ZWDataStore.store;
    
    if(![editing isEqualToString:@"YES"])
    {
    NSEntityDescription *profileEntity = [NSEntityDescription entityForName:@"Profile" inManagedObjectContext:store.managedObjectContext];
    
    CMProfile *profile = [[CMProfile alloc] initWithEntity:profileEntity insertIntoManagedObjectContext:store.managedObjectContext];
    profile.name = @"Name";
    [store saveContext];
    self.navigationItem.title = @"New Profile";
    _profile = profile;
    }
    else
    {
        _profile = ZWayAppDelegate.sharedDelegate.profile;
        self.navigationItem.title = _profile.name;
    }
    
    _fields = [NSMutableDictionary dictionary];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"name"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWUrlEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"indoorUrl"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWUrlEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"outdoorUrl"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWTextEditCell" owner:self options:nil] objectAtIndex:0] forKey:@"userLogin"];
    [_fields setObject:[[[NSBundle mainBundle] loadNibNamed:@"ZWPasswordCell" owner:self options:nil] objectAtIndex:0] forKey:@"userPassword"];
    
    _fieldsOrder = [NSMutableArray arrayWithObjects:@"name", @"indoorUrl", @"outdoorUrl", @"userLogin", @"userPassword", nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// Checks if we have a connection or not
- (void)testConnection:(NSString*)field With:(UITextField*)connection
{
    UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:connection.tag];
    UIImageView *connected = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connected-g.png"]];
    UIImageView *fail = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-down.png"]];
    reachableFoo = [Reachability reachabilityWithHostname:connection.text];
    
    if([field isEqualToString:@"@ home"])
    {
        if([reachableFoo currentReachabilityStatus] == NotReachable)
        {
            NSLog(@"No indoor connection found");
            cell.accessoryView = fail;
        }
        else
        {
            NSLog(@"Indoor connection found!");
            cell.accessoryView = connected;
        }
    }
    
    if([field isEqualToString:@"away"])
    {
            if([reachableFoo currentReachabilityStatus] == NotReachable)
            {
                NSLog(@"No outdoor connection found");
                cell.accessoryView = fail;
            }
            else
            {
                NSLog(@"Outdoor connection found!");
                cell.accessoryView = connected;
            }
    }
    
    [reachableFoo startNotifier];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    _profile = nil;
    self.navigationItem.title = nil;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
#else
        NSValue *keyboardBoundsValue = [[notification userInfo] objectForKey:UIKeyboardBoundsUserInfoKey];
#endif
        CGRect keyboardBounds;
        [keyboardBoundsValue getValue:&keyboardBounds];
        UIEdgeInsets e = UIEdgeInsetsMake(0, 0, keyboardBounds.size.height, 0);
        [[self tableview] setScrollIndicatorInsets:e];
        [[self tableview] setContentInset:e];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_3_2
    }
#endif
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets e = UIEdgeInsetsZero;
    [[self tableview] setScrollIndicatorInsets:e];
    [[self tableview] setContentInset:e];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.view endEditing:YES];
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
    
    if (_profile == ZWayAppDelegate.sharedDelegate.profile)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return nil;
        case 1:
            return @"INDOOR SERVER";
        case 2:
            return @"REMOTE ACCESS CREDENTIALS";
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        case 1:
        case 2:
            return 2;
        case 3:
            return 1;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    NSString *name;
    NSString *displayName;
    UILabel *label;
    UITextField *editor;
    
    UIButton *SaveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    SaveButton.frame = CGRectMake(0, 0, 280, 40);
    [SaveButton setTitle:@"Store Data" forState:UIControlStateNormal];
    SaveButton.backgroundColor = [UIColor clearColor];
    [SaveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [SaveButton addTarget:self action:@selector(store:) forControlEvents:UIControlEventTouchUpInside];
    
    switch (indexPath.section)
    {
        case 0:
            name = @"name";
            displayName = @"Name";
            break;
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"indoorUrl";
                    displayName = @"@ home";
                    break;
                case 1:
                    name = @"outdoorUrl";
                    displayName = @"away";
                    break;
            }
            break;
        }
            
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"userLogin";
                    displayName = @"ID";
                    break;
                case 1:
                    name = @"userPassword";
                    displayName = @"Password";
                    break;
            }
            break;
        }
            
        case 3:
        {
            name = @"name";
            cell.textLabel.text = @"Delete Profile";
        }
            break;
    }
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 280, 100)];
    [footerView addSubview:SaveButton];
    tableView.tableFooterView = footerView;
    
    cell = [_fields objectForKey:name];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if(![loaded isEqualToString:@"YES"])
    {
        label = (UILabel*)[cell viewWithTag:1];
        editor = (UITextField*)[cell viewWithTag:2];
    }
    else
    {
        editor = (UITextField*)[cell viewWithTag:cell.tag];
        label = (UILabel*)[cell viewWithTag:(cell.tag + 1)];
    }
    
    if([name isEqualToString:@"userPassword"])
        loaded = @"YES";
    
    label.text = displayName;
    editor.text = [_profile valueForKey:name];
    editor.tag = (indexPath.section * 1000 + indexPath.row + 1);
    cell.tag = editor.tag;
    label.tag = (editor.tag +1);
    
    return cell;
}

- (void)store:(id)sender
{
    if (ZWayAppDelegate.sharedDelegate.settingsLocked) return;
    
    [ZWDataStore.store.managedObjectContext processPendingChanges];
    [ZWDataStore.store saveContext];
    
    if (_profile == ZWayAppDelegate.sharedDelegate.profile)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZWProfileHasChanged" object:nil];
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Profiles" message:@"Your data has been stored" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name = nil;
    
    switch (indexPath.section)
    {
        case 0:
            name = @"name";
            break;
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"indoorUrl";
                    break;
                case 1:
                    name = @"outdoorUrl";
                    break;
            }
            break;
        }
            
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    name = @"userLogin";
                    break;
                case 1:
                    name = @"userPassword";
                    break;
            }
            break;
        }
            
        case 3:
        {
            if (indexPath.row == 0) {
                
            }
        }
    }
    
    UITableViewCell* cell = [_fields objectForKey:name];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    UITextField *editor = (UITextField*)[cell viewWithTag:cell.tag];
    [editor becomeFirstResponder];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return !ZWayAppDelegate.sharedDelegate.settingsLocked;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UITableViewCell *cell = (UITableViewCell*)[tableview viewWithTag:textField.tag];
    UILabel *label = (UILabel*)[cell viewWithTag:(textField.tag + 1)];
    [self testConnection:label.text With:textField];
    [_profile setValue:textField.text forKey:[self conformToProfile:label.text]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (NSString*)conformToProfile:(NSString*)profile
{
    if([profile isEqualToString:@"Name"])
        return @"name";
    else if([profile isEqualToString:@"@ home"])
        return @"indoorUrl";
    else if([profile isEqualToString:@"away"])
        return @"outdoorUrl";
    else if([profile isEqualToString:@"ID"])
        return @"userLogin";
    else
        return @"userPassword";
}

@end