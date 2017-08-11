//
//  CoinExchangeDataEngine.m
//  CoinExchange
//
//  Created by mahboud on 8/7/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//

#import "CoinExchangeDataEngine.h"
#import "CoinExchangeNetworkEngine.h"

NSString *const gCoinExchangeEngineHasNewData = @"CoinExchangeEngineHasNewData";

static NSString *const buyAction = @"Buy";
static NSString *const sellAction = @"Sell";

static NSString *const btcProduct = @"BTC";
static NSString *const ethProduct = @"ETH";
static NSString *const ltcProduct = @"LTC";

static NSString *const usdCurrency = @"USD";
static NSString *const eurCurrency = @"EUR";
static NSString *const gbpCurrency = @"GBP";
static NSString *const ethCurrency = @"ETH";
static NSString *const ltcCurrency = @"LTC";
static NSString *const btcCurrency = @"BTC";

@implementation CoinExchangeDataEngine {
  int _outstandingRequests;
  NSMutableDictionary <NSString *, NSDictionary *>*_orderBooks;
  CoinExchangeNetworkEngine *_networkEngine;
  NSString *_errorString;
  NSMutableArray <NSString *>*_productIDs;
  NSArray <NSString *>*_products;
  NSDictionary <NSString *, NSArray *>*_currencies;
}


+ (instancetype)sharedInstance {
  static dispatch_once_t once;
  static id sharedInstance;
  dispatch_once(&once, ^{
    sharedInstance = [[self alloc] init];

  });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _productIDs = @[].mutableCopy;
    _orderBooks = @{}.mutableCopy;
  }
  return self;
}

- (NSArray <NSString *>*)actions {
  return @[
           buyAction,
           sellAction,
           ];
}

- (NSArray <NSString *>*)products {
  if (_products) {
    return _products;
  }
  else {
    return @[
             btcProduct,
             ethProduct,
             ltcProduct,
             ];
  }
}

- (NSDictionary <NSString *, NSArray <NSString *>*>*)currencies {
  if (_currencies) {
    return _currencies;
  }
  else {
    return @{
             btcProduct : @[usdCurrency,
                            eurCurrency,
                            gbpCurrency,
                            ethCurrency,
                            ltcCurrency,],
             ethProduct : @[usdCurrency,
                            eurCurrency,
                            btcCurrency,],
             ltcProduct : @[usdCurrency,
                            eurCurrency,
                            btcCurrency,],
             };
  }
}

- (void)startEngine {
  _networkEngine = [[CoinExchangeNetworkEngine alloc] init];
}

- (void)getProductsAndBooks {
  [_networkEngine getProductsWithSuccessHandler:^(NSArray *result) {
    [self processProductsArray:result];
    [self getBooks:_productIDs];

    _errorString = nil;
  } errorHandler:^(NSError *error, NSString *errorString) {
    _errorString = errorString;
  }];
}

- (void)getBooks:(NSArray <NSString *>*)productIDs {
  _outstandingRequests = 0;
  for (NSString *productID in productIDs) {
    _outstandingRequests++;
    [_networkEngine getBookForProduct:productID
                   withSuccessHandler:^(NSDictionary *result) {
                     // switch to internal queue
                     // clear all data here
                     [self processBook:result forProduct:productID];
                     _outstandingRequests--;
                   } errorHandler:^(NSError *error, NSString *errorString) {
                     _outstandingRequests--;
                   }];
  }
}

- (void)processProductsArray:(NSArray <NSDictionary *>*)array {
  NSMutableSet *productSet = [[NSMutableSet alloc] init];
  NSMutableDictionary *currencies = @{}.mutableCopy;
  for (NSDictionary *dict in array) {
    NSString *productID = dict[@"id"];
    [_productIDs addObject:productID];
    NSArray *separatedPairs = [productID componentsSeparatedByString:@"-"];
    NSString *product = [separatedPairs firstObject];
    [productSet addObject:product];
  }
  // We could do most of what is in the following loop in the above loop.
  // A second pass is needed to allow for inverse pricing (i.e. BTC in LTC).
  for (NSDictionary *dict in array) {
    NSString *productID = dict[@"id"];
    NSArray *separatedPairs = [productID componentsSeparatedByString:@"-"];
    if (separatedPairs.count == 2) {
      NSString *currency = separatedPairs[1];
      NSString *product = [separatedPairs firstObject];
      [self addCurrency:currency forProduct:product withDict:currencies];
      if ([productSet containsObject:currency]) {
        [self addCurrency:product forProduct:currency withDict:currencies];
      }
    }
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    _products = [productSet allObjects];
    _currencies = currencies;
  });
}

- (void)addCurrency:(NSString *)currency forProduct:(NSString *)product withDict:(NSMutableDictionary *)dict {
  NSMutableArray *currenciesArray = dict[product];
  if (currenciesArray == nil) {
    currenciesArray = @[].mutableCopy;
    dict[product] = currenciesArray;
  }
  [currenciesArray addObject:currency];
}

- (void)processBook:(NSDictionary *)book forProduct:(NSString *)productID {
  dispatch_async(dispatch_get_main_queue(), ^{
    _orderBooks[productID] = book;
    if (_outstandingRequests == 0) {
      [[NSNotificationCenter defaultCenter] postNotificationName:gCoinExchangeEngineHasNewData
                                                          object:nil
                                                        userInfo:nil];
    }
  });

}

- (void)priceWithAction:(NSString *)action
                product:(NSString *)product
               currency:(NSString *)currency
                 amount:(NSNumber *)amount
             completion:(void (^)(NSString *message, NSNumber *amount, NSString *price))completion {
  if (completion == nil) {
    NSAssert(completion == nil, @"completion must not be nil");
    return;
  }

  if (_orderBooks == nil || _orderBooks.count == 0) {
    completion(@"Order Book unavailable. There may be a network issue.", nil, nil);
    return;
  }

  int multiplier;
  if ([currency isEqualToString:@"BTC"]) {
    multiplier = 100000;
  }
  else {
    multiplier = 100;
  }
  NSString *productID = [NSString stringWithFormat:@"%@-%@", product, currency];
  BOOL reverseOrder = NO;

  if (![_productIDs containsObject:productID]) {
    productID = [NSString stringWithFormat:@"%@-%@", currency, product];
    reverseOrder = YES;
  }
  NSDictionary <NSString *, NSArray *>*orderBook = _orderBooks[productID];
  if (orderBook[@"message"]) {
    completion(((NSDictionary<NSString *, NSString *>*)orderBook)[@"message"], nil, nil);
    return;
  }

  NSArray *subBook;
  if (([action isEqualToString: buyAction] && !reverseOrder) ||
      ([action isEqualToString: sellAction] && reverseOrder)) {
    subBook = orderBook[@"asks"];
  }
  else {
    subBook = orderBook[@"bids"];
  }

  if (subBook.count == 0) {
    if ([action isEqualToString: sellAction]) {
      completion(@"Order Book unavailable or zero buyers are available.", nil, nil);
    }
    else if ([action isEqualToString: buyAction]) {
      completion(@"Order Book unavailable or zero supply is available.", nil, nil);
    }
    return;
  }
  NSArray *results = [self getPriceWithOrderBook:subBook
                                          amount:amount.doubleValue
                                      multiplier:multiplier
                                         reverse:reverseOrder];
  if (results.count == 3) {
    if (!((NSNumber *)results[2]).boolValue) {
      completion(@"Unable to fulfill entire amount.",
                 results[1],
                 results[0]);
    }
    else {
      completion(@"Completed succesfully.",
                 results[1],
                 results[0]);
    }
  }
  else {
    completion(@"Buy or Sell action not specified.", nil, nil);
  }
}

- (NSArray *)getPriceWithOrderBook:(NSArray *)bookArray
                            amount:(double)amount
                        multiplier:(int)multiplier
                           reverse:(BOOL)reverse {
  double amountLeftToSatisfy = amount;
  double runningTotalPrice = 0;
  double runningTotalAmounts = 0;

  for (NSArray <NSNumber *>*order in bookArray) {
    if (order.count == 3) {
      double price = order[0].floatValue;
      double available = order[1].floatValue;
      double amountConsumed;

      if (amountLeftToSatisfy <= available) {
        amountConsumed = amountLeftToSatisfy;
        amountLeftToSatisfy = 0;
      }
      else {
        amountConsumed = available;
        amountLeftToSatisfy -= available;
      }

      runningTotalPrice += amountConsumed * price;
      runningTotalAmounts += amountConsumed;

      if (amountLeftToSatisfy == 0) {
        break;
      }
    }
  }
  double numerator = runningTotalPrice;
  double denominator = runningTotalAmounts;
  long result = round(reverse ? (denominator * multiplier) / numerator : (numerator * multiplier) / denominator) ;
  NSString *resultString = [NSString stringWithFormat:@"%ld.%02ld", result / multiplier, result % multiplier];
  return @[resultString,
           @(runningTotalAmounts),
           @(amountLeftToSatisfy == 0)];
}

// For testing.

- (void)clearState {
  [_orderBooks removeAllObjects];
  [_productIDs removeAllObjects];
  _products = nil;
  _currencies = nil;

}

@end
