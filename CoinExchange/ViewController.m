//
//  ViewController.m
//  CoinExchange
//
//  Created by mahboud on 8/4/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//

#import "ViewController.h"
#import "CoinExchangeDataEngine.h"

@interface ViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>

@end

@implementation ViewController {

  __weak IBOutlet UITextField *_amountTextField;
  __weak IBOutlet UIPickerView *_productPicker;
  __weak IBOutlet UILabel *_messagesLabel;
  __weak IBOutlet UILabel *_amountResultLabel;
  __weak IBOutlet UILabel *_priceResultLabel;
  NSArray *_actions;
  NSArray *_products;
  NSDictionary <NSString *,NSArray <NSString *>*>*_currencies;
  NSString *_actionString;
  NSString *_productString;
  NSString *_currencyString;
  NSNumber *_amount;

}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  [_amountTextField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];

  [[CoinExchangeDataEngine sharedInstance] startEngine];
  [self getLatest];
  [NSTimer scheduledTimerWithTimeInterval:15 target:self
                                 selector:@selector(getLatest) userInfo:nil repeats:YES];
  
  _productPicker.dataSource = self;
  _productPicker.delegate = self;

  [self clearResults];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateWithLatest)
                                               name:gCoinExchangeEngineHasNewData
                                             object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  _actions = [[CoinExchangeDataEngine sharedInstance] actions];
  _products = [[CoinExchangeDataEngine sharedInstance] products];
  _currencies = [[CoinExchangeDataEngine sharedInstance] currencies];
  _actionString = _actions[0];
  _productString = _products[0];
  _currencyString = _currencies[_productString][0];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)clearResults {
  _messagesLabel.text = @"Querying…";
  _amountResultLabel.text = @"-";
  _priceResultLabel.text = @"-";
}

- (void)getLatest {
  [[CoinExchangeDataEngine sharedInstance] getProductsAndBooks];
}

- (void)updateWithLatest {
  [self getParams];
}

- (void)getParams {
  _actionString = _actions[[_productPicker selectedRowInComponent:0]];
  _productString = _products[[_productPicker selectedRowInComponent:1]];
  _currencyString = _currencies[_productString][[_productPicker selectedRowInComponent:3]];
  [self getRequestedInfo];
}

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 4;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  if (component == 0) {
    return _actions.count;
  }
  else if (component == 1) {
    return _products.count;
  }
  else if (component == 2) {
    return 1;
  }
  else {
    return _currencies[_productString].count;
  }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  if (component == 0) {
    return _actions[row];
  }
  else if (component == 1) {
    return _products[row];
  }
  else if (component == 2) {
    return @"with";
  }
  else {
    return _currencies[_productString][row];
  }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  if (component == 0) {
    _actionString = _actions[row];
  }
  else if (component == 1) {
    _productString = _products[row];
    [_productPicker reloadComponent:3];
    NSInteger selectedRow = [_productPicker selectedRowInComponent:3];
    if (selectedRow >= _currencies.count) {
      selectedRow = _currencies.count - 1;
      [_productPicker selectRow:selectedRow inComponent:3 animated:YES];
    }
    _currencyString = _currencies[_productString][selectedRow];
  }
  else if (component == 2) {
  }
  else {
    _currencyString = _currencies[_productString][row];
  }
  [self delayedGetRequestedInfo];
}

- (void)textFieldDidChange:(UITextField *)textField {
  [self delayedGetRequestedInfo];
}

- (void)delayedGetRequestedInfo {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getRequestedInfo) object:nil];
  [self performSelector:@selector(getRequestedInfo) withObject:nil afterDelay:1.0];

}

- (void)getRequestedInfo {
  [_amountTextField resignFirstResponder];
  NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
  NSNumber *number = [numberFormatter numberFromString:_amountTextField.text];

  _amount = number;
  if (_actionString && _currencyString && _productString && _amount) {
    [self clearResults];
    [[CoinExchangeDataEngine sharedInstance] priceWithAction:_actionString
                                                     product:_productString
                                                    currency:_currencyString
                                                      amount:_amount
                                                  completion:^(NSString *message, NSNumber *amount, NSString *price){
                                                    _messagesLabel.text = message;
                                                    _priceResultLabel.text = [NSString stringWithFormat:@"%@ %@", price ?: @"-", _currencyString];
                                                    _amountResultLabel.text = [NSString stringWithFormat:@"%@ %@", amount ?: @"-", _productString];                                                  }];
  }
}

@end
