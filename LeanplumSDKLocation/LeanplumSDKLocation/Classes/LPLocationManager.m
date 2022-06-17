//
//  LPLocationManager.m
//  Leanplum
//
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPLocationManager.h"

#import <Leanplum/Leanplum.h>
#import <Leanplum/LPConstants.h>
#import <Leanplum/LPActionTriggerManager.h>
#import <Leanplum/LeanplumInternal.h>
#import <Leanplum/LPVarCache.h>

#define LP_REGION_IDENTIFIER_PREFIX @"__leanplum"
#define LP_REGION_DISTANCE_NEAR 1
#define LP_REGION_DISTANCE_IMMEDIATE 2

#define LP_DEFAULT_MAX_GEOFENCES 10
#define LP_DEFAULT_GEOFENCE_DISTANCE_UPPER_BOUND 3000

#define LP_LOCATION_UPDATE_INTERVAL 7200 // 2 hours in seconds.

@interface LPLocationManager()

@property (nonatomic,strong) CLLocationManager *locationManager;

@property (nonatomic,strong) NSDictionary *regionData;

@property (nonatomic,strong) NSSet *regions;
@property (nonatomic,strong) NSSet *foregroundRegions;
@property (nonatomic,strong) NSSet *backgroundRegions;

@property (nonatomic,strong) NSSet *foregroundNames;
@property (nonatomic,strong) NSSet *backgroundNames;
#ifdef LP_BEACON
@property (nonatomic,strong) NSMutableSet *activeBeaconRegions;
#endif

@property (nonatomic,strong) NSMutableDictionary *lastKnownState;

@property (nonatomic,assign) NSUInteger maxGeofences;
@property (nonatomic,strong) CLLocation *userLocation;
@property (nonatomic,assign) CLLocationDistance geofenceDistanceUpperBound;
@property (nonatomic,strong) NSDate *lastLocationSentDate;
@property (nonatomic,assign) LPLocationAccuracyType lastLocationSentAccuracyType;

@property (nonatomic,assign) BOOL setObserversForLocationUpdates;
@property (nonatomic,assign) BOOL setObserversForGeofences;
@property (nonatomic,assign) BOOL isForeground;
@property (nonatomic,assign) BOOL requestedAuth;
@property (nonatomic,assign) BOOL monitoringSignificantLocationChanges;
@property (nonatomic,assign) BOOL isSendingLocation;


@end

@implementation LPLocationManager

#pragma mark - initialization methods

- (id)init
{
    LP_TRY
    if (self = [super init]) {
        _authorizeAutomatically = YES;
        _maxGeofences = LP_DEFAULT_MAX_GEOFENCES;
        _geofenceDistanceUpperBound = LP_DEFAULT_GEOFENCE_DISTANCE_UPPER_BOUND;
        _monitoringSignificantLocationChanges = NO;
        _lastLocationSentAccuracyType = LPLocationAccuracyIP;
        _isSendingLocation = NO;
    }
    return self;
    LP_END_TRY
}

+ (void)load
{
    LP_TRY
    [[LPVarCache sharedCache] registerRegionInitBlock:^(NSDictionary *regions,
                                          NSSet *foregroundRegionNames,
                                          NSSet *backgroundRegionNames) {
        [[LPLocationManager sharedManager] setRegionsData:regions
                                      monitorInForeground:foregroundRegionNames
                                      monitorInBackground:backgroundRegionNames];
    }];

    // Request user location when Leanplum Start gets called.
    [Leanplum onStartIssued:^{
        if ([LPConstantsState sharedState].isLocationCollectionEnabled) {
            [[LPLocationManager sharedManager] requestLocation];
            [[LPLocationManager sharedManager] setApplicationStateObserversForLocationUpdates];
        }
    }];
    LP_END_TRY
}

+ (LPLocationManager *)sharedManager
{
    LP_TRY
    static LPLocationManager *_sharedManager = nil;
    static dispatch_once_t revenueManagerToken;
    dispatch_once(&revenueManagerToken, ^{
        _sharedManager = [self new];
    });
    return _sharedManager;
    LP_END_TRY
}

#pragma mark - Region tracking

- (void)setRegionsData:(NSDictionary *)regionData
   monitorInForeground:(NSSet *)foregroundNames
   monitorInBackground:(NSSet *)backgroundNames
{
    [self loadLastRegionState];

    _regionData = regionData;

    // Foreground/background region names.
    _foregroundNames = foregroundNames;
    _backgroundNames = backgroundNames;

    // Determine the foreground and background regions.
    NSMutableSet *foregroundRegions = [NSMutableSet set];
    NSMutableSet *backgroundRegions = [NSMutableSet set];
    for (NSString *regionName in regionData) {
        BOOL isForeground = [foregroundNames containsObject:regionName];
        BOOL isBackground = [backgroundNames containsObject:regionName];
        if (isForeground || isBackground) {
            CLRegion *region = [LPLocationManager regionFromDictionary:regionData[regionName]
                                                              withName:regionName];
            if (region == nil) {
                NSLog(@"Leanplum: Unrecognized type for region: %@", regionName);
            } else {
                if (isBackground) {
                    [backgroundRegions addObject:region];
                }
                if (isForeground) {
                    [foregroundRegions addObject:region];
                }
            }
        }
    }
    NSMutableSet *regions = [foregroundRegions mutableCopy];
    [regions unionSet:backgroundRegions];
    _regions = regions;
    _foregroundRegions = foregroundRegions;
    _backgroundRegions = backgroundRegions;

    [self requestAuthorization];

    // Update monitored regions.
    _isForeground =
        [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    [self updateMaxGeofences];
    [self setMonitoredRegions];
    [self setApplicationStateObserversForGeofences];
}

- (void)requestAuthorization
{
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];

    BOOL needsAuth = authStatus == kCLAuthorizationStatusNotDetermined;
    if (_backgroundRegions.count > 0 && authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        needsAuth = YES;
    }
    _needsAuthorization = needsAuth;
    if (_needsAuthorization) {
        _requestedAuth = YES;
        if (_authorizeAutomatically) {
            [self authorize];
        }
    }

}

- (void)authorize {
    LP_TRY
    CLLocationManager *locationManager = [self locationManager];
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    LP_END_TRY
}

- (void)loadLastRegionState
{
    if (!_lastKnownState) {
        NSDictionary *savedRegionState = [[NSUserDefaults standardUserDefaults]
                                          objectForKey:LEANPLUM_DEFAULTS_REGION_STATE_KEY];
        if (savedRegionState) {
            _lastKnownState = [savedRegionState mutableCopy];
        } else {
            _lastKnownState = [NSMutableDictionary dictionary];
        }
    }
}

/**
 * Set application state observer to reqeust location on resume.
 */
- (void)setApplicationStateObserversForLocationUpdates
{
    LP_TRY
    if (_setObserversForLocationUpdates) {
        return;
    }

    // Resume.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil queue:nil
                usingBlock:^(NSNotification *notification) {
        LP_TRY
        [[LPLocationManager sharedManager] requestLocation];
        LP_END_TRY
    }];

    _setObserversForLocationUpdates = YES;
    LP_END_TRY
}

/**
 * Set application state observers to update monitored regions.
*/
- (void)setApplicationStateObserversForGeofences
{
    if (_setObserversForGeofences || !_regions.count || !_backgroundRegions.count) {
        return;
    }

    // Pause.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil queue:nil
                usingBlock:^(NSNotification *notification) {
        LP_TRY
        self.isForeground = NO;
        [self setMonitoredRegions:self.backgroundRegions requestAllState:NO];
        LP_END_TRY
    }];

    // Resume.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil queue:nil
                usingBlock:^(NSNotification *notification) {
        LP_TRY
        self.isForeground = YES;
        [self setMonitoredRegions:self.regions requestAllState:YES];
        LP_END_TRY
    }];

    // Stop.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillTerminateNotification
                    object:nil queue:nil
                usingBlock:^(NSNotification *notification) {
        LP_TRY
        self.isForeground = NO;
        [self setMonitoredRegions:self.backgroundRegions requestAllState:NO];
        LP_END_TRY
    }];

    _setObserversForGeofences = YES;
}

- (void)setMonitoredRegions
{
    if (_isForeground) {
        [self setMonitoredRegions:_regions requestAllState:YES];
    } else {
        [self setMonitoredRegions:_backgroundRegions requestAllState:YES];
    }
}

- (void)setMonitoredRegions:(NSSet *)regions requestAllState:(BOOL)requestAllState
{
    CLLocationManager *locationManager = [self locationManager];
    [self setSignificantLocationMonitoringBasedOn:[regions count]];

    NSSet *regionsToBeMonitored = [self getRegionsToBeMonitored:regions];
    NSSet *leanplumRegions =
        [LPLocationManager filterLeanplumRegions:locationManager.monitoredRegions];

    for (CLRegion *monitoredRegion in leanplumRegions) {
        NSString *name = [LPLocationManager nameForRegion:monitoredRegion];
        if (name) {
            if (![regionsToBeMonitored containsObject:monitoredRegion]) {
                [locationManager stopMonitoringForRegion:monitoredRegion];
#ifdef LP_BEACON
                [self stopRangingBeaconsInRegion:monitoredRegion];
#endif
            }
        }
    }

    for (CLRegion *region in regionsToBeMonitored) {
        BOOL newlyAdded = NO;
        if (![locationManager.monitoredRegions containsObject:region]) {
            [locationManager startMonitoringForRegion:region];
            newlyAdded = YES;
        }
        if (requestAllState || newlyAdded) {
            [locationManager requestStateForRegion:region];
        }
    }

    if (_monitoringSignificantLocationChanges) {
        [self updateGeofenceDistanceUpperBound:regionsToBeMonitored];
    }
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    return _locationManager;
}

/**
 * Set up significantLocationChangeMonitoring based on the number of regions that need to be
 * monitored.
 */
- (void)setSignificantLocationMonitoringBasedOn:(NSUInteger)numberOfRegionsToBeMonitored
{
    CLLocationManager *locationManager = [self locationManager];
    BOOL shouldMonitorUserLocation = numberOfRegionsToBeMonitored > _maxGeofences;
    BOOL canMonitorUserLocation = [CLLocationManager significantLocationChangeMonitoringAvailable];
    if (shouldMonitorUserLocation && canMonitorUserLocation) {
        if (!_monitoringSignificantLocationChanges) {
            [locationManager startMonitoringSignificantLocationChanges];
            _monitoringSignificantLocationChanges = YES;
        }
    } else if (_monitoringSignificantLocationChanges){
        [locationManager stopMonitoringSignificantLocationChanges];
        _monitoringSignificantLocationChanges = NO;
    }
}

/**
 * Determines the number of geofences that can be used by Leanplum. If there are more than 10
 * geofences that are used by our customer, we claim the maximum number of goefences that are left
 * (|IOS_GEOFENCE_LIMIT| - the number of geofences used by our customer). Otherwise, we claim
 * |LP_DEFAULT_MAX_GEOFENCES|.
 */
- (void)updateMaxGeofences
{
    CLLocationManager *locationManager = [self locationManager];
    NSSet *leanplumRegions =
        [LPLocationManager filterLeanplumRegions:locationManager.monitoredRegions];
    NSUInteger nonLeanplumGeofencesCount = [locationManager.monitoredRegions count] -
        [leanplumRegions count];

    if (nonLeanplumGeofencesCount > IOS_GEOFENCE_LIMIT - LP_DEFAULT_MAX_GEOFENCES) {
        _maxGeofences = MAX(0, IOS_GEOFENCE_LIMIT - nonLeanplumGeofencesCount);
    }
}

/**
 * Reqeust the one-time delivery of the user's current location if authorized.
 */
- (void)requestLocation
{
    if (![LPConstantsState sharedState].isLocationCollectionEnabled) {
        return;
    }

    if ([[self locationManager] respondsToSelector:@selector(requestLocation)]) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse
            || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
            if (@available(iOS 9.0, *)) {
                [[self locationManager] requestLocation];
            }
        }
    } else {
        if ([[self locationManager] respondsToSelector:@selector
             (requestWhenInUseAuthorization)]) {
            [[self locationManager] requestWhenInUseAuthorization];
        }
        [[self locationManager] startUpdatingLocation];
    }
}

#pragma mark - Utility methods

+ (CLLocation *)locationFromRegion:(CLCircularRegion *)region
{
    CLLocationCoordinate2D center = [region center];
    return [[CLLocation alloc] initWithLatitude:center.latitude
                                      longitude:center.longitude];
}

+ (CLRegion *)regionFromDictionary:(NSDictionary *)regionData withName:(NSString *)name
{
    // General properties: version
    NSString *lat = regionData[@"lat"];
    NSString *identifier = [LPLocationManager identifierWithName:name
                                                         version:[regionData[@"version"] intValue]];

    // Circular region.
    // Properties: lat, lon, radius
    if (lat && ![lat isKindOfClass:NSNull.class]) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([lat doubleValue],
                                                                [regionData[@"lon"] doubleValue]);
        CLLocationDistance radius = [regionData[@"radius"] doubleValue];
        return [[CLCircularRegion alloc] initWithCenter:center
                                                 radius:radius
                                             identifier:identifier];
#ifdef LP_BEACON
    // Beacon region.
    // Properties: proximityUuid, major, minor, notifyEntryStateOnDisplay
    } else {
        NSString *proximityUuidString = regionData[@"proximity_uuid"];
        if (proximityUuidString && ![proximityUuidString isKindOfClass:NSNull.class]) {
            NSUUID *proximityUuid = [[NSUUID alloc] initWithUUIDString:proximityUuidString];
            if (proximityUuid == nil) {
                NSLog(@"Leanplum: Invalid proximity UUID for region %@", name);
                return nil;
            }
            id major = regionData[@"major"];
            id minor = regionData[@"minor"];
            CLBeaconRegion *region;
            if ([major isKindOfClass:NSNumber.class]) {
                if ([minor isKindOfClass:NSNumber.class]) {
                    region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUuid
                                                                     major:[major integerValue]
                                                                     minor:[minor integerValue]
                                                                identifier:identifier];
                } else {
                    region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUuid
                                                                     major:[major integerValue]
                                                                identifier:identifier];
                }
            } else {
                region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUuid
                                                            identifier:identifier];
            }
            id notifyEntryState = regionData[@"notify_entry_state_on_display"];
            if ([notifyEntryState isKindOfClass:NSNumber.class]) {
                region.notifyEntryStateOnDisplay = [notifyEntryState boolValue];
            }
            return region;
        }
#endif
    }
    return nil;
}

+ (NSString *)identifierWithName:(NSString *)name version:(NSUInteger)version
{
    return [NSString stringWithFormat:@"%@%@_%lu", LP_REGION_IDENTIFIER_PREFIX, name, (unsigned long)version];
}

+ (NSString *)nameForRegion:(CLRegion *)region
{
    if ([LPLocationManager isLeanplumRegion:region]) {
        NSString *name = [region.identifier substringFromIndex:[LP_REGION_IDENTIFIER_PREFIX length]];
        if ([name rangeOfString:@"_"].location != NSNotFound) {
            return [name substringToIndex:[name rangeOfString:@"_" options:NSBackwardsSearch].location];
        } else {
            return name;
        }
    }
    return nil;
}

+ (BOOL)isLeanplumRegion:(CLRegion *)region
{
    return [region.identifier rangeOfString:LP_REGION_IDENTIFIER_PREFIX].location != NSNotFound;
}

+ (NSSet *)filterLeanplumRegions:(NSSet<CLRegion *> *)regions
{
    NSSet *leanplumRegions = [regions objectsPassingTest:^BOOL(CLRegion *region, BOOL *stop) {
        return [LPLocationManager isLeanplumRegion:region];
    }];
    return leanplumRegions;
}

/**
 * Returns |_maxGeofences| or fewer regions to be monitored based on user location.
 * If user location is not available, it returns some |_maxGeofences| or fewer regions
 * nondeterministically.
 */
- (NSSet *)getRegionsToBeMonitored:(NSSet<CLRegion *> *)regions
{
    if ([regions count] <= _maxGeofences) {
        return regions;
    }

    NSMutableArray *arrayOfRegions = [[regions allObjects] mutableCopy];
    if (_userLocation) {
        [self sortRegionsByProximity:arrayOfRegions];
    }

    NSRange range = NSMakeRange(0, _maxGeofences);
    return [NSSet setWithArray:[arrayOfRegions subarrayWithRange:range]];
}

/**
 * Sorts regions by proximity to |_userLocation|.
 */
- (void)sortRegionsByProximity:(NSMutableArray<CLCircularRegion *> *)regions
{
    [regions sortUsingComparator:^(CLCircularRegion *regionA, CLCircularRegion *regionB) {
        CLLocation *locationA = [LPLocationManager locationFromRegion:regionA];
        CLLocation *locationB = [LPLocationManager locationFromRegion:regionB];
        CLLocationDistance distanceA = [_userLocation distanceFromLocation:locationA] -
            [regionA radius];
        CLLocationDistance distanceB = [_userLocation distanceFromLocation:locationB] -
            [regionB radius];
        return [[NSNumber numberWithDouble:distanceA]
                compare:[NSNumber numberWithDouble:distanceB]];
    }];
}

/**
 * Find the farthest region among the regions to be monitored from |_userLocation| and set
 * |_geofenceDistanceUpperBound| to be the distance from |_userLocation| to the farthest region.
 */
- (void)updateGeofenceDistanceUpperBound:(NSSet<CLCircularRegion *> *)regionsToBeMonitored
{
    _geofenceDistanceUpperBound = 0;
    for (CLCircularRegion *region in regionsToBeMonitored) {
        CLLocation *location = [LPLocationManager locationFromRegion:region];
        CLLocationDistance distance = [_userLocation distanceFromLocation:location] -
            [region radius];
        _geofenceDistanceUpperBound = MAX(_geofenceDistanceUpperBound, distance);
    }
}

- (int)maxDistanceForRegionNamed:(NSString *)name
{
    id maxDistance = _regionData[name][@"max_distance"];
    if ([maxDistance isKindOfClass:NSNumber.class]) {
        return [maxDistance intValue];
    }
    return 0;
}

/**
 * Call setUserAtributes API method for location udpate.
 */
- (void)setUserAttributesForLocationUpdate:(CLLocation *)location
                  withLocationAccuracyType:(LPLocationAccuracyType)locationAccuracyType
{
    LP_TRY
    _isSendingLocation = YES;
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
        if (error) {
            LPLog(LPDebug, @"Geocoding failed: %@", error.localizedDescription);
        }
        CLPlacemark *placemark = placemarks.firstObject;
        [Leanplum setUserLocationAttributeWithLatitude:location.coordinate.latitude
                                             longitude:location.coordinate.longitude
                                                  city:placemark? placemark.locality: nil
                                                region:placemark? placemark.administrativeArea: nil
                                               country:placemark? placemark.ISOcountryCode: nil
                                                  type:locationAccuracyType
                                       responseHandler:^(BOOL success) {
              self.isSendingLocation = NO;
              if (success) {
                  self.lastLocationSentDate = [NSDate date];
                  self.lastLocationSentAccuracyType = locationAccuracyType;
                  LPLog(LPDebug, @"setUserAttributes is successfully called");
              }
        }];
    }];
    LP_END_TRY
}

/**
 * Checks whether it is needed to call setUserAtributes API for location update.
 * Returns YES if it has been more than |LP_LOCATION_UPDATE_INTERVAL|
 * or the new location has better accuracy than the last location sent.
 */
- (BOOL)needToSendLocation:(LPLocationAccuracyType)newLocationAccuracyType
{
    return !_lastLocationSentDate
        || [[NSDate date] timeIntervalSinceDate:_lastLocationSentDate] > LP_LOCATION_UPDATE_INTERVAL
        || _lastLocationSentAccuracyType < newLocationAccuracyType;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    LP_TRY
    CLLocation *newLocation = [locations lastObject];

    if (newLocation.horizontalAccuracy < 0) {
        LPLog(LPError, @"Received an invalid location.");
        return;
    }

    // Currently, location segment treats GPS and CELL the same. In the future, we might want more
    // distinction in the accuracy types. For example, a customer might want to send messages only
    // to the ones with very accurate location information. We are assuming that it is from GPS if
    // the location accuracy is less than or equal to 100m.
    LPLocationAccuracyType newLocationAccuracyType =
        (newLocation.horizontalAccuracy <= kCLLocationAccuracyHundredMeters)
        ? LPLocationAccuracyGPS : LPLocationAccuracyCELL;

    if (!_isSendingLocation && [self needToSendLocation:newLocationAccuracyType]) {
        [self setUserAttributesForLocationUpdate:newLocation
                        withLocationAccuracyType:newLocationAccuracyType];
    }

    // Set new monitored regions if the user moves away more than |_geofenceDistanceUpperBound| from
    // |_userLocation| that is used to set geofences.
    if (!_userLocation
        || [_userLocation distanceFromLocation:newLocation] > _geofenceDistanceUpperBound) {
        _userLocation = newLocation;
        [self setMonitoredRegions];
    }
    LP_END_TRY
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    LPLog(LPError, @"location manager failed with error: %@", error);
    // If the user denied location services, we need to stop monitoring.
    if ([error.domain isEqualToString:kCLErrorDomain] && error.code == kCLErrorDenied) {
        [manager stopMonitoringSignificantLocationChanges];
    }
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    LP_TRY
    NSString *name = [LPLocationManager nameForRegion:region];
    if (!name) {
        return;
    }

    // Skip regions that are unused.
    if ((!_isForeground && ![_backgroundNames containsObject:name])) {
        return;
    }

    BOOL hasDeterminedState = YES;

#ifdef LP_BEACON
    // Beacons set to Immediate or Near are not entered until we range the beacons
    // and detect that they are close enough.
    if ([region isKindOfClass:CLBeaconRegion.class]) {
        int maxDistance = [self maxDistanceForRegionNamed:name];

        // Need proximity data.
        if (maxDistance == LP_REGION_DISTANCE_IMMEDIATE ||
            maxDistance == LP_REGION_DISTANCE_NEAR) {

            if (state == CLRegionStateInside) {
                [self startRangingBeaconsInRegion:region];
                hasDeterminedState = NO;
            } else {
                [self stopRangingBeaconsInRegion:region];
            }
        }
    }
#endif

    if (hasDeterminedState) {
        [self didDetermineState:state forLeanplumRegion:region withName:name];
    }
    LP_END_TRY
}

#ifdef LP_BEACON
- (void)startRangingBeaconsInRegion:(CLRegion *)region
{
    if ([region isKindOfClass:CLBeaconRegion.class]) {
        [_locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];

        // Need to also update location for beacon ranging to work in the background.
        [_locationManager startUpdatingLocation];

        [_activeBeaconRegions addObject:region];
    }
}

- (void)stopRangingBeaconsInRegion:(CLRegion *)region
{
    if ([region isKindOfClass:CLBeaconRegion.class]) {
        [_locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        [_activeBeaconRegions removeObject:region];
        if (_activeBeaconRegions.count == 0) {
            [_locationManager stopUpdatingLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    LP_TRY
    NSString *name = [LPLocationManager nameForRegion:region];
    if (!name) {
        return;
    }
    if (beacons.count == 0 || (!_isForeground && ![_backgroundNames containsObject:name])) {
        return;
    }

    BOOL isImmediate = NO;
    BOOL isNear = NO;
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity == CLProximityImmediate) {
            isImmediate = YES;
            isNear = YES;
        }
        if (beacon.proximity == CLProximityNear) {
            isNear = YES;
        }
    }

    int maxDistance = [self maxDistanceForRegionNamed:name];
    if (isImmediate || (isNear && maxDistance == LP_REGION_DISTANCE_NEAR)) {
        [self didDetermineState:CLRegionStateInside forLeanplumRegion:region withName:name];

        // We only need to be ranging until we find a hit, then we stop to save battery.
        // Note that to trigger a region exit even if the proximity is set to Immediate or Near,
        // the device must entirely exit the beacon's boundary.
        [self stopRangingBeaconsInRegion:region];
    }

    LP_END_TRY
}
#endif

- (void)locationManager:(CLLocationManager *)manager
        didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    LP_TRY
    _needsAuthorization = NO;
    if (_requestedAuth && (status == kCLAuthorizationStatusAuthorizedAlways ||
                           status == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        _requestedAuth = NO;
        [self setMonitoredRegions];
    }
    LP_END_TRY
}

- (void)didDetermineState:(CLRegionState)state
        forLeanplumRegion:(CLRegion *)region
                 withName:(NSString *)name
{
    [self didDetermineState:state forLeanplumRegion:region withName:name inForeground:NO];
    if (_isForeground) {
        [self didDetermineState:state forLeanplumRegion:region withName:name inForeground:YES];
    }
}

- (void)didDetermineState:(CLRegionState)state
        forLeanplumRegion:(CLRegion *)region
                 withName:(NSString *)name
             inForeground:(BOOL)foreground
{
    // Check state changes (unknown -> inside, outside -> inside, inside -> outside).
    NSString *stateKey = [NSString stringWithFormat:@"%@%d", name, foreground];
    if (state == CLRegionStateInside || state == CLRegionStateOutside) {
        NSNumber *stateNumber = @(state);
        int lastState = [_lastKnownState[stateKey] intValue];
        if ((state == CLRegionStateInside && lastState != CLRegionStateInside) ||
            (state == CLRegionStateOutside && lastState == CLRegionStateInside)) {
            _lastKnownState[stateKey] = stateNumber;
            [[NSUserDefaults standardUserDefaults] setObject:_lastKnownState
                                                      forKey:LEANPLUM_DEFAULTS_REGION_STATE_KEY];

            LeanplumActionFilter actionFilter = foreground ?
                kLeanplumActionFilterForeground : kLeanplumActionFilterBackground;

            if (state == CLRegionStateInside) {
                [Leanplum maybePerformActions:@[@"enterRegion"]
                                withEventName:name
                                   withFilter:actionFilter
                                fromMessageId:nil
                         withContextualValues:nil];
                [Leanplum trackGeofence:LPEnterRegion withInfo:name];
            } else if (state == CLRegionStateOutside) {
                [Leanplum maybePerformActions:@[@"exitRegion"]
                                withEventName:name
                                   withFilter:actionFilter
                                fromMessageId:nil
                         withContextualValues:nil];
                [Leanplum trackGeofence:LPExitRegion withInfo:name];
            }
        }
    }
}

@end
