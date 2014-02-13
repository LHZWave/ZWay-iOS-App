//
//  ZWDeviceItem.m
//  ZWayJSON
//
//  Created by Lucas von Hacht on 1/20/14.
//  Copyright (c) 2014 Lucas von Hacht. All rights reserved.
//

#import "ZWDeviceItem.h"
#import "ZWDevice.h"
#import "SWTableViewCell.h"

@implementation ZWDeviceItem

@synthesize nameView = _nameView;
@synthesize device = _device;

- (void)setDisplayName
{
    NSDictionary *dict = self.device.metrics;
    self.nameView.text = [dict valueForKey:@"title"];
    
    if([self.device.deviceType isEqualToString:@"fan"])
        self.imageView.image = [UIImage imageNamed:@"fan.png"];
    else if([self.device.deviceType isEqualToString:@"thermostat"])
        self.imageView.image = [UIImage imageNamed:@"thermostat.png"];
    else if([self.device.deviceType isEqualToString:@"switchMultilevel"])
        self.imageView.image = [UIImage imageNamed:@"light.png"];
    else if([self.device.deviceType isEqualToString:@"switchBinary"])
        self.imageView.image = [UIImage imageNamed:@"switch.png"];
    else if([self.device.deviceType isEqualToString:@"probe"] || [self.device.deviceType isEqualToString:@"battery"])
        self.imageView.image = [UIImage imageNamed:@"battery.png"];
}

- (void)createRequestWithURL:(NSString *)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!theConnection)
        receivedData = nil;
}

- (void)updateState
{
    //Specified in subclasses
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int responseStatusCode = [httpResponse statusCode];
    
    if(responseStatusCode != 200)
        NSLog(@"Request failed!");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    receivedData = nil;
    
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

@end