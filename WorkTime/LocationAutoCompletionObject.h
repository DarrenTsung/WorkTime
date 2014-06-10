//
//  LocationAutoCompletionObject.h
//  WorkTime
//
//  Created by Darren Tsung on 6/8/14.
//  Copyright (c) 2014 Lamdawoof. All rights reserved.
//

#import "MLPAutoCompletionObject.h"
#import <UIKit/UIKit.h>

@interface LocationAutoCompletionObject : NSObject <MLPAutoCompletionObject>

-(id)initWithState:(NSString *)state andCountry:(NSString *)country;
-(id)initWithCountry:(NSString *)country;

-(NSString *)getStateString;

@end
