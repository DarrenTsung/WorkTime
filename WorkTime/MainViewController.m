//
//  MainViewController.m
//  WorkTime
//
//  Created by Darren Tsung on 6/9/14.
//  Copyright (c) 2014 Lamdawoof. All rights reserved.
//

#import "MainViewController.h"

#define MAX_HOUR_COST 1000

@interface MainViewController ()

@property(nonatomic, strong) IBOutlet UITextField *itemCost;
@property(nonatomic, strong) IBOutlet UILabel *costLabel;
@property(nonatomic, strong) IBOutlet UILabel *itemRepresentation;

@property(nonatomic, strong) NSDictionary *stateTaxesTable;
@property(nonatomic, strong) NSArray *federalTaxesArray;

@property(nonatomic) double computedIncomePerHour;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)setIncome:(double)incomePerYear andState:(NSString *)stateString
{
    // load the state income taxes file
    [self loadStateIncomeTax:@"state_incomes" withType:@"txt"];
    // load the federal income taxes file
    [self loadFederalIncomeTax:@"federal_income" withType:@"txt"];
    
    double federalTaxPercentage = [self getFederalIncomePercentageForIncome:incomePerYear];
    double stateTaxPercentage = [self getStateIncomePercentageForState:stateString andIncome:incomePerYear];
    
    _computedIncomePerHour = (incomePerYear * (1 - (federalTaxPercentage + stateTaxPercentage)))/2008.0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // add padding so the numbers do not overlap with the $ symbol on the left
    UIView *thePadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 20)];
    _itemCost.leftView = thePadding;
    _itemCost.leftViewMode = UITextFieldViewModeAlways;
    
    // Add a "textFieldDidChange" notification method to the text field control.
    [_itemCost addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    
    // select the item cost field
    [_itemCost becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Update

- (void)processCost:(NSNumber *)cost
{
    NSMutableAttributedString *hourCostString = [[NSMutableAttributedString alloc] initWithString:@""];
    double itemCost = [cost doubleValue];
    
    double hourCost = itemCost / _computedIncomePerHour;
    
    // compute scale of the hour string
    double scale = (hourCost > MAX_HOUR_COST) ? 1 : hourCost / MAX_HOUR_COST;
    
    double costFontSize = 40.0 + 15.0*scale;
    double smallTextFontSize = 17.0 + 5.0*scale;
    double largerTextFontSize = 23 + 10.0*scale;
    
    _costLabel.font = [UIFont boldSystemFontOfSize:20.0 + 20.0*scale];
    
    [hourCostString appendAttributedString:
     [[NSMutableAttributedString alloc] initWithString:@"It'll cost you\n"
                                            attributes:@{
                                                         NSFontAttributeName : [UIFont boldSystemFontOfSize:smallTextFontSize]
                                                         }]];
    if (hourCost > 10000)
    {
        [hourCostString appendAttributedString:
         [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.0fK\n", hourCost/1000.0f] attributes:@{
                NSFontAttributeName : [UIFont boldSystemFontOfSize:costFontSize]
                }]];
    }
    else
    {
        [hourCostString appendAttributedString:
         [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f\n", hourCost] attributes:@{
                NSFontAttributeName : [UIFont boldSystemFontOfSize:costFontSize]
                }]];
    }
    [hourCostString appendAttributedString:
     [[NSMutableAttributedString alloc] initWithString:@"hours\n"
                                            attributes:@{
                                                         NSFontAttributeName : [UIFont boldSystemFontOfSize:largerTextFontSize]
                                                         }]];
    [hourCostString appendAttributedString:
     [[NSMutableAttributedString alloc] initWithString:@"to pay for that."
                                            attributes:@{
                                                         NSFontAttributeName : [UIFont boldSystemFontOfSize:smallTextFontSize]
                                                         }]];
    
    _costLabel.attributedText = hourCostString;
    
    _costLabel.transform = CGAffineTransformScale(_costLabel.transform, .5, .5);
    _costLabel.center = self.view.center;
    [_costLabel sizeToFit];
    
    [UIView animateWithDuration:1.0
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.9
                        options:0
                     animations:^{
                         _costLabel.transform = CGAffineTransformScale(_costLabel.transform, 2.0, 2.0);
                         _costLabel.center = self.view.center;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

#pragma mark - TextFieldInput

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
    
    // update the work hour display
    [self processCost:currCost];
    
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setMaximumFractionDigits:2];
    
    _itemRepresentation.text = [numFormatter stringFromNumber:currCost];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
