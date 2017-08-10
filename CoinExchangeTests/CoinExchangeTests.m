//
//  CoinExchangeTests.m
//  CoinExchangeTests
//
//  Created by mahboud on 8/4/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CoinExchangeDataEngine.h"

@interface CoinExchangeDataEngine (test)

- (void)processProductsArray:(NSArray <NSDictionary *>*)array;
- (void)clearState;

@end


@interface CoinExchangeTests : XCTestCase

@end

@implementation CoinExchangeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

  
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEngineArrays {
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  XCTAssertNotNil([CoinExchangeDataEngine sharedInstance].products, @"No products array");
  XCTAssertNotNil([CoinExchangeDataEngine sharedInstance].actions, @"No actions array");
  XCTAssertNotNil([CoinExchangeDataEngine sharedInstance].currencies, @"No currencies dict");
}

- (void)testEngineProcessWithNils {

  [CoinExchangeDataEngine.sharedInstance priceWithAction:nil
                                                 product:nil
                                                currency:nil
                                                  amount:nil
                                              completion:^(NSString *message, NSNumber *amount, NSNumber *price) {
                                                XCTAssert(message, @"no result");

                                              }];

  [CoinExchangeDataEngine.sharedInstance priceWithAction:@"Buy"
                                                   product:@"BTC"
                                                  currency:@"USD"
                                                  amount:nil
                                              completion:^(NSString *message, NSNumber *amount, NSNumber *price) {
                                                XCTAssert(message, @"no result");
                                                
                                              }];

}


- (void)testFakeProducts {
  
  // Create an expectation object.
  // This test only has one, but it's possible to wait on multiple expectations.
  XCTestExpectation *productExpectation = [self expectationWithDescription:@"product"];
  
  
  NSArray <NSDictionary *>*productArray = @[
                                            @{
                                              @"base_currency" : @"DOGCOIN-EUR",
                                              @"base_max_size" : @(1000000),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"DOGCOIN/EUR",
                                              @"id" : @"DOGCOIN-EUR",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"EUR",
                                              @"quote_increment" : @(0.01),
                                              },
                                            @{
                                              @"base_currency" : @"DOGCOIN",
                                              @"base_max_size" : @(1000000),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"DOGCOIN/BIRDCOIN",
                                              @"id" : @"DOGCOIN-BIRDCOIN",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"BIRDCOIN",
                                              @"quote_increment" : @(0.00001),
                                              },
                                            @{
                                              @"base_currency" : @"BIRDCOIN",
                                              @"base_max_size" : @(250),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"BIRDCOIN/EUR",
                                              @"id" : @"BIRDCOIN-EUR",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"EUR",
                                              @"quote_increment" : @(0.01),
                                              },
                                            @{
                                              @"base_currency" : @"DOGCOIN",
                                              @"base_max_size" : @(1000000),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"DOGCOIN/USD",
                                              @"id" : @"DOGCOIN-USD",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"USD",
                                              @"quote_increment" : @(0.01),
                                              },
                                            @{
                                              @"base_currency" : @"BIRDCOIN",
                                              @"base_max_size" : @(250),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"BIRDCOIN/USD",
                                              @"id" : @"BIRDCOIN-USD",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"USD",
                                              @"quote_increment" : @(0.01),
                                              },
                                            @{
                                              @"base_currency" : @"BIRDCOIN",
                                              @"base_max_size" : @(250),
                                              @"base_min_size" : @(0.01),
                                              @"display_name" : @"BIRDCOIN/GBP",
                                              @"id" : @"BIRDCOIN-GBP",
                                              @"margin_enabled" : @(0),
                                              @"quote_currency" : @"GBP",
                                              @"quote_increment" : @(0.01),
                                              },
                                            ];
  [[CoinExchangeDataEngine sharedInstance] clearState];
  
  [[CoinExchangeDataEngine sharedInstance] processProductsArray:productArray];
  
  // the last method finishes its task by dispatch_async to main_queue, so we need the
  // following to wait until it is done, which is after the run_loop runs.
  dispatch_async(dispatch_get_main_queue(), ^{
    [productExpectation fulfill];
  });
  
  // The test will pause here, running the run loop, until the timeout is hit
  // or all expectations are fulfilled.
  [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
    
    XCTAssert([CoinExchangeDataEngine sharedInstance].products.count == 2, @"bad fake products count");
    
    XCTAssert([CoinExchangeDataEngine sharedInstance].currencies.allKeys.count == 2, @"bad fake currencies count");
    
    XCTAssert([CoinExchangeDataEngine sharedInstance].currencies[ @"BIRDCOIN"].count == 4, @"DOGCOIN has bad currencies count");
    
    XCTAssert([CoinExchangeDataEngine sharedInstance].currencies[ @"DOGCOIN"].count == 3, @"BIRDCOIN has bad currencies count");
    
  }];
  
}
// if time permits, repeat somethign like above, with a fake orderbook.  Make it have simplistic values so it is easy to get some testing of pricing, as amount increases.



- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
