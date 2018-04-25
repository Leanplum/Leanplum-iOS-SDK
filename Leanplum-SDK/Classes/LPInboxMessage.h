//
//  LPInboxMessage.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import <Foundation/Foundation.h>

@class LPActionContext;

@interface LPInboxMessage : NSObject <NSCoding>

/**
 * Returns the message identifier of the inbox message.
 */
- (NSString *)messageId;

/**
 * Returns the title of the inbox message.
 */
- (NSString *)title;

/**
 * Returns the subtitle of the inbox message.
 */
- (NSString *)subtitle;

/**
 * Returns the image path of the inbox message. Can be nil.
 * Use with [UIImage contentsOfFile:].
 */
- (NSString *)imageFilePath;

/**
 * Returns the image URL of the inbox message.
 * You can safely use this with prefetching enabled.
 * It will return the file URL path instead if the image is in cache.
 */
- (NSURL *)imageURL;

/**
 * Returns the data of the inbox message. Advanced use only.
 */
- (NSDictionary *)data;

/**
 * Returns the delivery timestamp of the inbox message.
 */
- (NSDate *)deliveryTimestamp;

/**
 * Return the expiration timestamp of the inbox message.
 */
- (NSDate *)expirationTimestamp;

/**
 * Returns YES if the inbox message is read.
 */
- (BOOL)isRead;

/**
 * Read the inbox message, marking it as read and invoking its open action.
 */
- (void)read;

/**
 * Remove the inbox message from the inbox.
 */
- (void)remove;

@end

#pragma mark - LPNewsfeed for backwards compatibility
@interface LPNewsfeedMessage : LPInboxMessage

@end

typedef void (^LeanplumNewsfeedChangedBlock)(void);

@interface LPNewsfeed : NSObject

+ (LPNewsfeed *)sharedState;
- (NSUInteger)count;
- (NSUInteger)unreadCount;
- (NSArray *)messagesIds;
- (NSArray *)allMessages;
- (NSArray *)unreadMessages;
- (void)onChanged:(LeanplumNewsfeedChangedBlock)block;
- (LPNewsfeedMessage *)messageForId:(NSString *)messageId;
- (void)addNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector __attribute__((deprecated));
- (void)removeNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector __attribute__((deprecated));

@end

@interface LPInboxMessage ()

#pragma mark - LPInboxMessage properties

@property(strong, nonatomic) NSString *messageId;
@property(strong, nonatomic) NSDate *deliveryTimestamp;
@property(strong, nonatomic) NSDate *expirationTimestamp;
@property(assign, nonatomic) BOOL isRead;
@property(strong, nonatomic) LPActionContext *context;

- (BOOL)downloadImageIfPrefetchingEnabled;
- (id)initWithMessageId:(NSString *)messageId
      deliveryTimestamp:(NSDate *)deliveryTimestamp
    expirationTimestamp:(NSDate *)expirationTimestamp
                 isRead:(BOOL)isRead
             actionArgs:(NSDictionary *)actionArgs;

@end

