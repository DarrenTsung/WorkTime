//
//  LocationAutoCompletionObject.m
//  WorkTime
//
//  Created by Darren Tsung on 6/8/14.
//  Copyright (c) 2014 Lamdawoof. All rights reserved.
//

#import "LocationAutoCompletionObject.h"

@interface LocationAutoCompletionObject()

@property(strong) NSString *state;
@property(strong) NSString *country;

@end

@implementation LocationAutoCompletionObject

-(id)initWithState:(NSString *)state andCountry:(NSString *)country
{
    if (self = [super init])
    {
        self.state = state;
        self.country = country;
    }
    return self;
}

-(id)initWithCountry:(NSString *)country
{
    if (self = [super init])
    {
        self.country = country;
    }
    return self;
}

#pragma mark - MLPAutoCompletionObject Protocol

- (NSString *)autocompleteString
{
    NSMutableString *ret = [[NSMutableString alloc] initWithString:@""];
    
    // check that country exists
    if (!_country)
        return @"";
    
    if (_state)
        [ret appendString:[NSString stringWithFormat:@"%@, %@", _state, _country]];
    else
        [ret appendFormat:_country];
    
    return ret;
}

- (UIColor *)getTextColor
{
    return [UIColor darkGrayColor];
}

@end
