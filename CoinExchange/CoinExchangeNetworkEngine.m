//
//  CoinExchangeNetworkEngine.m
//  CoinExchange
//
//  Created by mahboud on 8/7/17.
//  Copyright © 2017 BitsOnTheGo.com. All rights reserved.
//
//  Access network resources.  This can be stubbed out for testing.

#import "CoinExchangeNetworkEngine.h"

static NSString *const urlScheme = @"https";
static NSString *const urlUsername = nil;
static NSString *const urlPassword = nil;
static NSString *const urlServer = @"api.gdax.com";
static NSString *const urlProducts = @"/products";
static NSString *const urlBook = @"/book";
static NSString *const urlLevelQuery = @"level=2";


@implementation CoinExchangeNetworkEngine {
  NSURLSession *_session;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //  No need for this to be a singleton since it isn't a backgroundSession
    _session = [NSURLSession sharedSession];
    
    //    });
  }
  return self;
}

- (void)getProductsWithSuccessHandler:(void (^)(NSArray *result))successHandler
                         errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler {
  NSURLComponents *baseURL = [[NSURLComponents alloc] init];
  baseURL.scheme = urlScheme;
  baseURL.host = urlServer;
  baseURL.user = urlUsername;
  baseURL.password = urlPassword;
  baseURL.path = urlProducts;
  [self executeNetworkMethodWithURL:[baseURL URL]
                     successHandler:^(NSArray *result) {
                       if ([result isKindOfClass:NSArray.class]) {
                         successHandler((NSArray *)result);
                       }
                       else {
                         errorHandler(nil, @"JSON Not an array");
                       }
                     }
                       errorHandler:errorHandler];
}

- (void)getBookForProduct:(NSString *)product
       withSuccessHandler:(void (^)(NSDictionary *result))successHandler
             errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler {
  NSURLComponents *baseURL = [[NSURLComponents alloc] init];
  baseURL.scheme = urlScheme;
  baseURL.host = urlServer;
  baseURL.user = urlUsername;
  baseURL.password = urlPassword;
  baseURL.path = [NSString stringWithFormat:@"%@/%@%@", urlProducts, product, urlBook];
  baseURL.query = urlLevelQuery;
  [self executeNetworkMethodWithURL:[baseURL URL]
                     successHandler:^(id result) {
                       if ([result isKindOfClass:NSDictionary.class]) {
                         successHandler((NSDictionary *)result);
                       }
                       else {
                         errorHandler(nil, @"JSON Not a dictionary");
                       }
                     }
                       errorHandler:errorHandler];
}

- (void)executeNetworkMethodWithURL:(NSURL *)downloadURL
                     successHandler:(void (^)(id result))successHandler
                       errorHandler:(void (^)(NSError *error, NSString *errorString))errorHandler {
  NSURLSessionDownloadTask *downloadTask =
  [_session downloadTaskWithURL:downloadURL
              completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (error) {
                  errorHandler(error, error.localizedDescription);
                }
                else {
                  NSData *data=[NSData dataWithContentsOfFile:location.path];
                  NSError *error;
                  id objectFromJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:&error];
                  if (error) {
                    errorHandler(error, error.localizedDescription);
                  }
                  else {
                    successHandler(objectFromJSON);
                  }
                }
              }];
  [downloadTask resume];
}

@end
