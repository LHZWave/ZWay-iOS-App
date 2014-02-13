//
//  ZWaySecondViewController.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/15/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWayWidgetViewController.h"
#import "ZWayDashboardViewController.h"
#import "ZWayAppDelegate.h"
#import "ZWDeviceItem.h"
#import "ZWDevice.h"
#import "ZWDataHandler.h"
#import "ZWayRoomsViewController.h"
#import "ZWayNotificationViewController.h"

@interface ZWayWidgetViewController ()

@end

@implementation ZWayWidgetViewController

@synthesize currentButton;
@synthesize tableview;
@synthesize rooms, types, tags;
@synthesize objects;
@synthesize JSON;
@synthesize roomObjects, typeObjects, tagObjects;
@synthesize deviceIndex;
@synthesize tagsButton, typesButton, roomsButton;
@synthesize noItemsLabel;
@synthesize toolbar;


- (void)viewDidLoad
{
    currentButton = @"Rooms";
    roomsButton.tintColor = [UIColor whiteColor];
    UIColor *color = self.navigationController.navigationBar.tintColor;
    [self.toolbar setTintColor:color];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ZWDataHandler *handler = [[ZWDataHandler alloc] init];
    ZWDevice *device = [[ZWDevice alloc] init];
    
    //Get JSON data
    JSON = [handler getJSON:0];
    if([[JSON objectForKey:@"message"] isEqualToString:@"200 OK"])
    {
        NSMutableDictionary *dict = [JSON objectForKey:@"data"];
        if([[dict objectForKey:@"structureChanged"] isEqualToNumber:[NSNumber numberWithBool:YES]])
            objects = [[device updateObjects:objects atTimestamp:0] mutableCopy];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"There was a problem with the update" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    //or set it
    if(objects.count == 0)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSData *encodedJSON = [defaults objectForKey:@"JSON"];
        NSData *encodedObjects = [defaults objectForKey:@"Devices"];
        
        objects = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObjects];
        JSON = [NSKeyedUnarchiver unarchiveObjectWithData:encodedJSON];
        
        //and update it
        NSUInteger timestamp = [handler getTimestamp:JSON];
        objects = [[device updateObjects:objects atTimestamp:timestamp] mutableCopy];
    }
    
    [self getWidgets];
    [tableview reloadData];
}

-(IBAction)roomsSelected:(id)sender
{
    currentButton = @"Rooms";
    [roomsButton setTintColor:[UIColor whiteColor]];
    [typesButton setTintColor:nil];
    [tagsButton setTintColor:nil];
    [tableview reloadData];
}

-(IBAction)typesSelected:(id)sender
{
    currentButton = @"Types";
    [typesButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [tagsButton setTintColor:nil];
    [tableview reloadData];
}

-(IBAction)tagsSelected:(id)sender
{
    currentButton = @"Tags";
    [tagsButton setTintColor:[UIColor whiteColor]];
    [roomsButton setTintColor:nil];
    [typesButton setTintColor:nil];
    [tableview reloadData];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushWidgetDevices"])
    {
        ZWayRoomsViewController *destination = segue.destinationViewController;
        
        destination.typesDevices = typeObjects;
        destination.tagsDevices = tagObjects;
        destination.roomDevices = roomObjects;
        destination.selected = currentButton;
        destination.deviceIndex = deviceIndex;
    }
}


- (void)getWidgets
{
    types = [NSMutableArray new];
    tags  = [NSMutableArray new];
    typeObjects = [NSMutableArray new];
    tagObjects  = [NSMutableArray new];
    roomObjects = [NSMutableArray new];
    ZWDevice *device = [ZWDevice new];
    ZWDataHandler *handler = [ZWDataHandler new];
    rooms = [[NSMutableArray alloc] initWithArray:[handler getLocations]];
    
    for (NSInteger i=0; i<objects.count; i++)
    {
        device = [objects objectAtIndex:i];
        NSString *deviceType = device.deviceType;
        NSArray *deviceTags = [[NSArray alloc]initWithArray:device.tags];
        NSString *location = device.location;
        
        if (deviceType != (id)[NSNull null])
        {
            if(![types containsObject:deviceType])
            {
                [types addObject:deviceType];
                NSMutableArray *typeDevice = [NSMutableArray new];
                [typeDevice addObject:device];
                [self.typeObjects addObject:typeDevice];
            }
            else
            {
                NSUInteger index = [types indexOfObject:deviceType];
                NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[typeObjects objectAtIndex:index]];
                [puffer addObject:device];
                [typeObjects replaceObjectAtIndex:index withObject:puffer];
            }
        }

        for (NSInteger j=0; j<deviceTags.count; j++)
        {
            NSString *tagObject = [deviceTags objectAtIndex:j];
            
            if(tagObject != (id)[NSNull null])
            {
                if(![tags containsObject:tagObject])
                {
                    [tags addObject:tagObject];
                    NSMutableArray *tagDevice = [NSMutableArray new];
                    [tagDevice addObject:device];
                    [self.tagObjects addObject:tagDevice];
                }
                else
                {
                    NSUInteger index = [tags indexOfObject:tagObject];
                    NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[tagObjects objectAtIndex:index]];
                    [puffer addObject:device];
                    [tagObjects replaceObjectAtIndex:index withObject:puffer];
                }
            }
        }
        
        if(location != (id)[NSNull null])
        {
            NSLog(@"location: %@", location);
            if([[rooms objectAtIndex:i] isEqualToString:location])
            {
                NSUInteger index = [rooms indexOfObject:location];
                NSMutableArray *puffer = [[NSMutableArray alloc]initWithArray:[roomObjects objectAtIndex:index]];
                [puffer addObject:device];
                [roomObjects replaceObjectAtIndex:index withObject:puffer];
            }
        }
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([currentButton isEqualToString:@"Rooms"])
    {
        if(rooms.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return rooms.count;
    }
    else if([currentButton isEqualToString:@"Types"])
    {
        if(types.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return types.count;
    }
    else
    {
        if(tags.count == 0)
        {
            tableview.hidden = YES;
            noItemsLabel.hidden = NO;
        }
        else
        {
            tableview.hidden = NO;
            noItemsLabel.hidden = YES;
        }
        return tags.count;
    }

}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";

    if([currentButton isEqualToString:@"Rooms"] && rooms.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [rooms objectAtIndex:indexPath.row];
        return cell;
    }
    else if([currentButton isEqualToString:@"Types"] && types.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [types objectAtIndex:indexPath.row];
        return cell;
    }
    else if(tags.count != 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = [tags objectAtIndex:indexPath.row];
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = @"No devices found";
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    deviceIndex = [NSNumber numberWithInt:indexPath.row];
    [self performSegueWithIdentifier:@"pushWidgetDevices" sender:self];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
        
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:objects];
    NSData *encodedJSON = [NSKeyedArchiver archivedDataWithRootObject:JSON];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (objects) {
        [defaults setObject:encodedObject forKey:@"Devices"];
        objects = nil;
    }
    if(JSON)
    {
        [defaults setObject:encodedJSON forKey:@"JSON"];
        JSON = nil;
    }
}

@end
