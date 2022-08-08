//
//  LPActionContextNotification.h
//  LeanplumSDK
//
//  Created by Nikola Zagorchev on 4.08.22.
//

#import <Foundation/Foundation.h>
#import "LPActionContext.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * LPActionContext subclass used for presenting Push Notification as a Confirm In-app message
 * when Notification is received when App is in foreground.
 * Do NOT use except for the above-mentioned use case.
 */
NS_SWIFT_NAME(ActionContextNotification)
@interface LPActionContextNotification : LPActionContext {
}

- (void)runTrackedActionNamed:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
