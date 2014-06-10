//
//  ViewController.m
//  WorkTime
//
//  Created by Darren Tsung on 6/9/14.
//  Copyright (c) 2014 Lamdawoof. All rights reserved.
//

#import "ViewController.h"
#import "MainViewController.h"
#import "LocationAutoCompletionObject.h"

@interface ViewController ()

@property(nonatomic, strong) NSArray *autocompletionObjects;
@property(nonatomic, strong) IBOutlet UITextField *wageField;
@property(nonatomic, strong) IBOutlet MLPAutoCompleteTextField *autocompleteField;
@property(nonatomic, strong) NSMutableSet *stateSet;
@property(nonatomic, strong) IBOutlet UILabel *errorText;
@property(nonatomic, strong) IBOutlet UILabel *wageLabel;
@property(nonatomic, strong) IBOutlet UISegmentedControl *wageType;

@property(nonatomic) double wagePerYearStored;
@property(nonatomic, weak) NSString *stateStored;

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
    
    _stateSet = [[NSMutableSet alloc] init];
    
    // load the state csv file
    [self loadStateCSVFile:@"states" withType:@"txt"];
    
    // Add a "textFieldDidChange" notification method to the text field control.
    [_wageField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch * touch = [touches anyObject];
    if(touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }
}

#pragma mark - income

// format the cost correctly (decimal style)
- (void)textFieldDidChange:(UITextField *)textField
{
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    
    NSString *textFieldText = textField.text;
    // the number representation of the textfield
    NSNumber *currCost = [numFormatter numberFromString:textFieldText];
    
    // cap the maximum representation at 999,999,999
    if ([currCost doubleValue] > 999999999)
    {
        currCost = [NSNumber numberWithDouble:999999999];
        textField.text = @"999999999";
    }
    
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setMaximumFractionDigits:2];
    
    // empty string if the current cost is blank
    NSString *formattedText = ([currCost doubleValue] == 0) ? @"" : [NSString stringWithFormat:@"$%@", [numFormatter stringFromNumber:currCost]];
    
    _wageLabel.text = formattedText;
}

#pragma mark - Transitions

-(IBAction)checkStateAndSegue
{
    NSNumberFormatter *numForm = [[NSNumberFormatter alloc] init];
    double wagePerYear = [[numForm numberFromString:_wageField.text] doubleValue];
    
    // if the first segment is selected convert the wage to dollars per year
    if ([_wageType selectedSegmentIndex] == 0)
        wagePerYear *= 2008;
    
    if (wagePerYear < 1)
    {
        _errorText.text = @"Please enter a valid income greater than $1/hr or $2008/year";
        return;
    }
    
    _wagePerYearStored = wagePerYear;
    
    NSString *locationField = _autocompleteField.text;
    NSArray *locArray = [locationField componentsSeparatedByString:@","];
    if ([locArray count] == 2)
    {
        NSString *state = [[[locArray objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] capitalizedString];
        if ([_stateSet containsObject:state])
        {
            _stateStored = [locArray objectAtIndex:0];
            NSString *countryCode = [[[locArray objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
            if ([countryCode isEqualToString:@"US"])
            {
                [self performSegueWithIdentifier:@"main" sender:self];
            }
            else
            {
                _errorText.text = @"Please use the country code 'US'.";
            }
        }
        else
        {
            _errorText.text = @"Please enter a valid state in the US.";
        }
    }
    else
    {
        _errorText.text = @"Please enter a valid location in the US.";
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
    MainViewController *mainViewController = segue.destinationViewController;
    [mainViewController setIncome:_wagePerYearStored andState:_stateStored];
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
        [_stateSet addObject:[stateArray objectAtIndex:0]];
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
    if(selectedObject) {
        NSLog(@"selected object from autocomplete menu %@ with string %@", selectedObject, [selectedObject autocompleteString]);
        
        // close the keyboard
        [self.view endEditing:YES];
    } else {
        NSLog(@"selected string '%@' from autocomplete menu", selectedString);
    }
}

@end
