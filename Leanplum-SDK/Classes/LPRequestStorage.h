//
//  LPRequestStorage.h
//  Leanplum
//
//  Created by Andrew First on 10/23/14.
//
//

#import <Foundation/Foundation.h>

@interface LPRequestStorage : NSObject {
    @private
    NSTimeInterval _lastSentTime;
    NSMutableArray *_requests;
    NSUserDefaults *_defaults;
}

+ (LPRequestStorage *)sharedStorage;

- (void)pushRequest:(NSDictionary *)requestData;
- (NSArray *)popAllRequests;
- (void)saveRequests;

@property (nonatomic, readonly) NSTimeInterval lastSentTime;

@end
