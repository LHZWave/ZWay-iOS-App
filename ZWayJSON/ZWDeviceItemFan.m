//
//  ZWDeviceItemThermostat.m
//  Z-Way
//
//  Created by Alex Skalozub on 8/27/12.
//  Copyright (c) 2012 Alex Skalozub.
//
//  Z-Way for iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  Z-Way for iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with Z-Way for iOS. If not, see <http://www.gnu.org/licenses/>
//

#import "ZWDeviceItemFan.h"
#import "ZWayAppDelegate.h"
#import "ZWPickerPopup.h"

@implementation ZWDeviceItemFan

@synthesize modeView = _modeView;

+ (ZWDeviceItemFan*)device
{
    NSArray *a = [[NSBundle mainBundle] loadNibNamed:@"ZWDeviceItemFan" owner:nil options:nil];
    return [a objectAtIndex:0];
}

- (void)dealloc
{
    self.modeView = nil;
    states = nil;
}

- (void)currentTitle
{
    if([currentState isEqualToString:@"0"])
        [self.modeView setTitle:@"Auto Low" forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"1"])
        [self.modeView setTitle:@"On Low" forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"2"])
        [self.modeView setTitle:@"Auto High" forState:UIControlStateNormal];
    else if ([currentState isEqualToString:@"3"])
        [self.modeView setTitle:@"On High" forState:UIControlStateNormal];
}

- (void)updateState
{
    currentState = [NSString stringWithFormat:@"%@", [self.device.metrics objectForKey:@"currentMode"]];
    [self currentTitle];
    
    states = [NSMutableArray new];
    [states addObject:@"Auto Low"];
    [states addObject:@"On Low"];
    [states addObject:@"Auto High"];
    [states addObject:@"On High"];
}

- (void)setMode:(id)sender
{
    ZWPickerPopup *pickerPopup = [[ZWPickerPopup alloc] initWithParent:(UIView *)sender];
    UIPickerView *modePicker = pickerPopup.picker;
    
    modePicker.showsSelectionIndicator = YES;
    modePicker.dataSource = self;
    modePicker.delegate = self;
    modePicker.tag = 1;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:pickerPopup];
    [pickerPopup becomeFirstResponder];
    [pickerPopup addTarget:self action:@selector(setModeDone:) forControlEvents:UIControlEventValueChanged];
}

- (void)setModeDone:(ZWPickerPopup*)sender
{
    [sender removeTarget:self action:@selector(setModeDone:) forControlEvents:UIControlEventValueChanged];
    [sender removeFromSuperview];
    
    NSString *url = [NSString stringWithFormat:@"http://%@/ZAutomation/api/v1/devices/%@/command/setMode?mode=%@", ZWayAppDelegate.sharedDelegate.profile.indoorUrl, self.device.deviceId, currentState];
    [self createRequestWithURL:url];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 4;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [states objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if([[states objectAtIndex:row] isEqualToString:@"Auto Low"])
        currentState = @"0";
    else if([[states objectAtIndex:row] isEqualToString:@"On Low"])
        currentState = @"1";
    else if([[states objectAtIndex:row] isEqualToString:@"Auto High"])
        currentState = @"2";
    else if([[states objectAtIndex:row] isEqualToString:@"On High"])
        currentState = @"3";
    
    [self currentTitle];
}

@end
