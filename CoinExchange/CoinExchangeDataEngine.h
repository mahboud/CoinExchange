//
//  CoinExchangeDataEngine.h
//  CoinExchange
//
//  Created by mahboud on 8/7/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const gCoinExchangeEngineHasNewData;

@interface CoinExchangeDataEngine : NSObject
+ (instancetype)sharedInstance;

- (NSArray <NSString *>*)actions;
- (NSArray <NSString *>*)products;
- (NSDictionary <NSString *, NSArray <NSString *>*>*)currencies;
- (void)startEngine;
- (void)getProductsAndBooks;
- (void)priceWithAction:(NSString *)action
                product:(NSString *)product
               currency:(NSString *)currency
                 amount:(NSNumber *)amount
             completion:(void (^)(NSString *message, NSNumber *amount, NSNumber *price))completion;

@end
