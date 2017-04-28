//
//  LPAppIconManager.m
//  Leanplum
//
//  Created by Alexis Oyama on 2/23/17.
//  Copyright (c) 2017 Leanplum. All rights reserved.
//

#import "LPAppIconManager.h"
#import "LeanplumRequest.h"
#import "LeanplumInternal.h"
#import "Utils.h"

@implementation LPAppIconManager

+ (void)uploadAppIconsOnDevMode
{
    if (![LPConstantsState sharedState].isDevelopmentModeEnabled ||
        ![LPAppIconManager supportsAlternateIcons]) {
        return;
    }

    NSDictionary *alternativeIcons = [LPAppIconManager alternativeIconsBundle];
    if ([Utils isNullOrEmpty:alternativeIcons]) {
        LPLog(LPWarning, @"Your project does not contain any alternate app icons. "
              "Add one or more alternate icons to the info.plist. "
              "https://support.leanplum.com/hc/en-us/articles/115001519046");
        return;
    }

    // Prepare to upload primary and alternative icons.
    NSMutableArray *requestParam = [NSMutableArray new];
    NSMutableDictionary *requestDatas = [NSMutableDictionary new];
    [LPAppIconManager prepareUploadRequestParam:requestParam
                            iconDataWithFileKey:requestDatas
                                 withIconBundle:[LPAppIconManager primaryIconBundle]
                                       iconName:LP_APP_ICON_PRIMARY_NAME];
    [alternativeIcons enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isEqualToString:LP_APP_ICON_PRIMARY_NAME]) {
            LPLog(LPWarning, @"%@ is reserved for primary icon."
                  "This alternative icon will not be uploaded.", LP_APP_ICON_PRIMARY_NAME);
            return;
        }
        [LPAppIconManager prepareUploadRequestParam:requestParam
                                iconDataWithFileKey:requestDatas
                                     withIconBundle:obj
                                           iconName:key];
    }];

    LeanplumRequest *request = [LeanplumRequest post:LP_METHOD_UPLOAD_FILE
                                              params:@{@"data":
                                                    [LPJSON stringFromJSON:requestParam]}];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
        LPLog(LPVerbose, @"App icons uploaded.");
    }];
    [request onError:^(NSError *error) {
        LPLog(LPError, @"Fail to upload app icons: %@", error.localizedDescription);
    }];
    [request sendDatasNow:requestDatas];
}

#pragma mark - Private methods

/**
 * Returns whether app supports alternate icons
 */
+ (BOOL)supportsAlternateIcons
{
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(supportsAlternateIcons)]) {
        return [app supportsAlternateIcons];
    }
    return NO;
}

/**
 * Returns primary icon bundle
 */
+ (NSDictionary *)primaryIconBundle
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    return bundleIcons[@"CFBundlePrimaryIcon"];
}

/**
 * Returns alternative icons bundle
 */
+ (NSDictionary *)alternativeIconsBundle
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    return bundleIcons[@"CFBundleAlternateIcons"];
}

/**
 * Helper method that prepares request parameters and dats to upload icons in batch.
 * It loops through all the possible image files and uses the first one.
 */
+ (void)prepareUploadRequestParam:(NSMutableArray *)requestParam
              iconDataWithFileKey:(NSMutableDictionary *)requestDatas
                   withIconBundle:(NSDictionary *)bundle
                         iconName:(NSString *)iconName
{
    for (NSString *iconImageName in bundle[@"CFBundleIconFiles"]) {
        if ([Utils isNullOrEmpty:iconName]) {
            continue;
        }

        UIImage *iconImage = [UIImage imageNamed:iconImageName];
        if (!iconImage) {
            continue;
        }

        NSData *iconData = UIImagePNGRepresentation(iconImage);
        if (!iconData) {
            continue;
        }

        NSString *filekey = [NSString stringWithFormat:LP_PARAM_FILES_PATTERN, requestParam.count];
        requestDatas[filekey] = iconData;

        NSString *filename = [NSString stringWithFormat:@"%@%@.png", LP_APP_ICON_FILE_PREFIX,
                              iconName];
        NSDictionary *param = @{LP_KEY_FILENAME: filename,
                                LP_KEY_HASH: [Utils md5OfData:iconData],
                                LP_KEY_SIZE: @(iconData.length)};
        [requestParam addObject:param];
        return;
    }
}

@end
