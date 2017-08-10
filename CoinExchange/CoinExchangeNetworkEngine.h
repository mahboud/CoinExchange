//
//  CoinExchangeNetworkEngine.h
//  CoinExchange
//
//  Created by mahboud on 8/7/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoinExchangeNetworkEngine : NSObject
- (void)getProductsWithSuccessHandler:(void (^)(NSArray *result))successHandler
                         errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler;
- (void)getBookForProduct:(NSString *)product
       withSuccessHandler:(void (^)(NSDictionary *result))successHandler
             errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler;

@end
