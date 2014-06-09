//
//  ViewController.m
//  WorkTime
//
//  Created by Darren Tsung on 6/9/14.
//  Copyright (c) 2014 Lamdawoof. All rights reserved.
//

#import "ViewController.h"
#import "LocationAutoCompletionObject.h"

@interface ViewController ()

@property(nonatomic, strong) NSArray *autocompletionObjects;
@property(nonatomic, strong) IBOutlet UITextField *wageField;
@property(nonatomic, strong) IBOutlet MLPAutoCompleteTextField *autocompleteField;
@property(nonatomic, strong) NSDictionary *stateTaxesTable;
@property(nonatomic, strong) NSArray *federalTaxesArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.autocompleteField setBorderStyle:UITextBorderStyleRoundedRect];
    self.autocompleteField.delegate = (id)self;
    self.autocompleteField.autoCompleteDataSource = (id)self;
    self.autocompleteField.autoCompleteDelegate = (id)self;
    
    [self.autocompleteField setAutoCompleteTableBackgroundColor:[UIColor colorWithWhite:1 alpha:0.9]];
    // no spell checking / auto correction since states
    [self.autocompleteField setSpellCheckingType:UITextSpellCheckingTypeNo];
    [self.autocompleteField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.autocompleteField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    
    // load the state csv file
    [self loadStateCSVFile:@"states" withType:@"txt"];
    // load the state income taxes file
    [self loadStateIncomeTax:@"state_incomes" withType:@"txt"];
    // load the federal income taxes file
    [self loadFederalIncomeTax:@"federal_income" withType:@"txt"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IncomeTax DataSource

- (void)loadFederalIncomeTax:(NSString *)filename withType:(NSString *)type
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    NSMutableArray *federalBrackets = [[NSMutableArray alloc] init];
    for (NSString *str in listArray)
    {
        NSArray *components = [str componentsSeparatedByString:@","];
        NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
        
        if ([components count] >= 2)
        {
            NSNumber *taxPercentage = [numFormatter numberFromString:components[0]];
            NSNumber *taxBracket = [numFormatter numberFromString:components[1]];
            
            [federalBrackets addObject:@[taxPercentage, taxBracket]];
        }
    }
    _federalTaxesArray = federalBrackets;
}

- (double)getFederalIncomePercentageForIncome:(double)income
{
    double taxPercentage = 0.00;
    double highestIncomeBracket = 0.0;
    for (NSArray *taxBracket in _federalTaxesArray)
    {
        double currTaxPercentage = [[taxBracket objectAtIndex:0] doubleValue];
        double minIncome = [[taxBracket objectAtIndex:1] doubleValue];
        // if our income is higher than the minimum income to qualify for the tax bracket
        // and we haven't qualified for a higher bracket
        if (income >= minIncome && minIncome >= highestIncomeBracket)
        {
            taxPercentage = currTaxPercentage;
            highestIncomeBracket = minIncome;
        }
    }
    return taxPercentage;
}


- (void)loadStateIncomeTax:(NSString *)filename withType:(NSString *)type
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);
    
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    NSMutableDictionary *stateTaxesDict = [[NSMutableDictionary alloc] init];
    NSString *key = @"";
    NSMutableArray *value = [[NSMutableArray alloc] init];
    for (NSString *str in listArray)
    {
        // two types of lines in the file, state name and income taxes by bracket
        // if the string does not contain a comma (',') then it is the former type
        if ([str rangeOfString:@","].location == NSNotFound) {
            if (![key isEqualToString:@""])
            {
                [stateTaxesDict setObject:value forKey:key];
                value = [[NSMutableArray alloc] init];
            }
            key = str;
        }
        else
        {
            NSArray *components = [str componentsSeparatedByString:@","];
            NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
            
            if ([components count] >= 2)
            {
                NSNumber *taxPercentage = [numFormatter numberFromString:components[0]];
                NSNumber *taxBracket = [numFormatter numberFromString:components[1]];
                
                [value addObject:@[taxPercentage, taxBracket]];
            }
        }
    }
    _stateTaxesTable = stateTaxesDict;
}

- (double)getStateIncomePercentageForState:(NSString *)stateName andIncome:(double)income
{
    NSArray *taxes = [_stateTaxesTable objectForKey:stateName];
    double taxPercentage = 0.00;
    double highestIncomeBracket = 0.0;
    for (NSArray *taxBracket in taxes)
    {
        double currTaxPercentage = [[taxBracket objectAtIndex:0] doubleValue];
        double minIncome = [[taxBracket objectAtIndex:1] doubleValue];
        // if our income is higher than the minimum income to qualify for the tax bracket
        // and we haven't qualified for a higher bracket
        if (income >= minIncome && minIncome >= highestIncomeBracket)
        {
            taxPercentage = currTaxPercentage;
            highestIncomeBracket = minIncome;
        }
    }
    return taxPercentage;
}

#pragma mark - MLPAutoCompleteTextField DataSource

- (void)loadStateCSVFile:(NSString *)filename withType:(NSString *)type
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);

    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    NSMutableArray *completions = [[NSMutableArray alloc] init];
    for (NSString *stateString in listArray)
    {
        NSArray *stateArray = [stateString componentsSeparatedByString:@","];
        LocationAutoCompletionObject *completionObject = [[LocationAutoCompletionObject alloc] initWithState:[stateArray objectAtIndex:0] andCountry:@"US"];
        [completions addObject:completionObject];
    }
    _autocompletionObjects = completions;
}

// asynchronous fetch
- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        // simulate latency
        if(true){
            CGFloat seconds = (arc4random_uniform(4)+arc4random_uniform(4)) / 5; //normal distribution
            //NSLog(@"sleeping fetch of completions for %f", seconds);
            sleep(seconds);
        }
        
        handler(_autocompletionObjects);
    });
}

#pragma mark - MLPAutoCompleteTextField Delegate

- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
  didSelectAutoCompleteString:(NSString *)selectedString
       withAutoCompleteObject:(id<MLPAutoCompletionObject>)selectedObject
            forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(selectedObject){
        NSLog(@"selected object from autocomplete menu %@ with string %@", selectedObject, [selectedObject autocompleteString]);
        
        // remove the text in the autocompleteTextField
        [self.autocompleteField setText:@""];
        
        // close the keyboard
        [self.view endEditing:YES];
    } else {
        NSLog(@"selected string '%@' from autocomplete menu", selectedString);
    }
}

@end
