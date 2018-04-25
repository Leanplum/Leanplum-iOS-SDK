//
//  LPInboxMessage.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LPInboxMessage.h"
#import "LeanplumInternal.h"
#import "Utils.h"
#import "LPFileManager.h"
#import "LeanplumRequest.h"

@implementation LPInboxMessage

#pragma mark - LPInboxMessage private methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self messageId] forKey:LP_PARAM_MESSAGE_ID];
    [coder encodeObject:[self deliveryTimestamp] forKey:LP_KEY_DELIVERY_TIMESTAMP];
    [coder encodeObject:[self expirationTimestamp] forKey:LP_KEY_EXPIRATION_TIMESTAMP];
    [coder encodeBool:[self isRead] forKey:LP_KEY_IS_READ];
    [coder encodeObject:[[self context] args] forKey:LP_VALUE_ACTION_ARG];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _messageId = [decoder decodeObjectForKey:LP_PARAM_MESSAGE_ID];
        _deliveryTimestamp = [decoder decodeObjectForKey:LP_KEY_DELIVERY_TIMESTAMP];
        _expirationTimestamp = [decoder decodeObjectForKey:LP_KEY_EXPIRATION_TIMESTAMP];
        _isRead = [decoder decodeBoolForKey:LP_KEY_IS_READ];
        NSDictionary *actionArgs = [decoder decodeObjectForKey:LP_VALUE_ACTION_ARG];
        NSArray *messageIdParts = [_messageId componentsSeparatedByString:@"##"];
        _context = [LPActionContext actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                                     args:actionArgs
                                                messageId:messageIdParts[0]];
        [_context preventRealtimeUpdating];
        [self downloadImageIfPrefetchingEnabled];
    }
    return self;
}

- (id)initWithMessageId:(NSString *)messageId
      deliveryTimestamp:(NSDate *)deliveryTimestamp
    expirationTimestamp:(NSDate *)expirationTimestamp
                 isRead:(BOOL)isRead
             actionArgs:(NSDictionary *)actionArgs
{
    if (self = [super init]) {
        _messageId = messageId;
        _deliveryTimestamp = deliveryTimestamp;
        _expirationTimestamp = expirationTimestamp;
        _isRead = isRead;
        
        NSArray *messageIdParts = [messageId componentsSeparatedByString:@"##"];
        if ([messageIdParts count] != 2) {
            NSLog(@"Leanplum: Malformed inbox messageId: %@", messageId);
            return nil;
        }
        _context = [LPActionContext actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                                     args:actionArgs
                                                messageId:messageIdParts[0]];
        [_context preventRealtimeUpdating];
        if ([LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
            [_context maybeDownloadFiles];
        }
    }
    return self;
}

- (void)setIsRead:(BOOL)isRead
{
    _isRead = isRead;
}

#pragma mark - LPInboxMessage public methods

- (NSString *)title
{
    LP_TRY
    return [_context stringNamed:LP_KEY_TITLE];
    LP_END_TRY
    return @"";
}

- (NSString *)subtitle
{
    LP_TRY
    return [_context stringNamed:LP_KEY_SUBTITLE];
    LP_END_TRY
    return @"";
}

/**
 * This is a helper method that will return the cached file path of the image URL.
 * Will return nil if there is no file.
 */
- (NSString *)filePathOfImageURL
{
    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    if (![Utils isNullOrEmpty:imageURLString] && [LPFileManager fileExists:imageURLString]) {
        NSString *filePath = [LPFileManager fileValue:imageURLString withDefaultValue:@""];
        if (![Utils isNullOrEmpty:filePath]) {
            return [LPFileManager fileValue:imageURLString withDefaultValue:@""];
        }
    }
    return nil;
}

- (NSString *)imageFilePath
{
    LP_TRY
    NSString *filePath = [self filePathOfImageURL];
    if (filePath) {
        return filePath;
    }
    
    if (![LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
        LPLog(LPWarning, @"Inbox Message image path is null "
              "because you're calling [Leanplum disableImagePrefetching]. "
              "Consider using imageURL method or remove disableImagePrefetching.");
    }
    LP_END_TRY
    
    return nil;
}

- (NSURL *)imageURL
{
    LP_TRY
    // Check if the file has been downloaded.
    // This is to prevent from sending multiple requests.
    NSString *filePath = [self filePathOfImageURL];
    if (filePath) {
        return [NSURL fileURLWithPath:filePath];
    }
    
    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    return [NSURL URLWithString:imageURLString];
    LP_END_TRY
    
    return nil;
}

- (NSDictionary *)data
{
    LP_TRY
    return [_context dictionaryNamed:LP_KEY_DATA];
    LP_END_TRY
    return nil;
}

- (void)read
{
    if (![self isRead]) {
        [self setIsRead:YES];
        
        NSUInteger unreadCount = [[LPInbox sharedState] unreadCount] - 1;
        [[LPInbox sharedState] updateUnreadCount:unreadCount];
        
        RETURN_IF_NOOP;
        LP_TRY
        NSDictionary *params = @{LP_PARAM_INBOX_MESSAGE_ID: [self messageId]};
        LeanplumRequest *req = [LeanplumRequest post:LP_METHOD_MARK_INBOX_MESSAGE_AS_READ
                                              params:params];
        [req send];
        LP_END_TRY
    }
    
    LP_TRY
    [[self context] runTrackedActionNamed:LP_VALUE_DEFAULT_PUSH_ACTION];
    LP_END_TRY
}

- (BOOL)isActive
{
    if (![self expirationTimestamp]) {
        return YES;
    }
    NSDate *now = [NSDate date];
    return [now compare:[self expirationTimestamp]] == NSOrderedAscending;
}

- (void)remove
{
    LP_TRY
    [[LPInbox sharedState] removeMessageForId:[self messageId]];
    LP_END_TRY
}

/**
 * Download image if prefetching is enabled.
 * Returns YES if the image will be downloaded, otherwise NO.
 * Uses LPInbox.downloadedImageUrls to make sure we don't call fileExist method
 * multiple times for same URLs.
 */
- (BOOL)downloadImageIfPrefetchingEnabled
{
    if (![LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
        return NO;
    }
    
    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    if ([Utils isNullOrEmpty:imageURLString] ||
        [[Leanplum inbox].downloadedImageUrls containsObject:imageURLString]) {
        return NO;
    }
    
    [[Leanplum inbox].downloadedImageUrls addObject:imageURLString];
    BOOL willDownloadFile = [LPFileManager maybeDownloadFile:imageURLString
                                                defaultValue:nil
                                                  onComplete:nil];
    return willDownloadFile;
}

@end
