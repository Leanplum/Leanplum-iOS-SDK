//
//  GeofencingTest.m
//  Leanplum
//
//  Created by Kyu Hyun Chang on 6/30/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
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


#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import <Leanplum/LPConstants.h>
#import <Leanplum/LPJSON.h>
#import <LeanplumLocationAndBeacons/LPLocationManager.h>

/**
 * The following allows to call LPLocationManager private methods, instance variables, and
 * properties.
 */
@interface LPLocationManager ()

@property (nonatomic,assign) NSUInteger maxGeofences;
@property (nonatomic,strong) CLLocation *userLocation;
@property (nonatomic,assign) CLLocationDistance geofenceDistanceUpperBound;
@property (nonatomic,strong) CLLocationManager *locationManager;

+ (CLRegion *)regionFromDictionary:(NSDictionary *)regionData withName:(NSString *)name;
+ (NSSet*)filterLeanplumRegions:(NSSet<CLRegion *> *)regions;
- (CLLocationManager *)locationManager;
- (void)sortRegionsByProximity:(NSMutableArray *)arrayOfRegions;
- (void)setMonitoredRegions:(NSSet *)regions requestAllState:(BOOL)requestAllState;
- (void)updateMaxGeofences;
- (void)updateGeofenceDistanceUpperBound:(NSSet<CLRegion *> *)regionsToBeMonitored;
@end

@interface GeofencingTest : XCTestCase
@property (nonatomic) LPLocationManager *locationManager;
@property (nonatomic) NSMutableArray *regions;
@property (nonatomic) NSDictionary *locations;
@property (nonatomic) NSDictionary *regionNameToRegion;
@end


@implementation GeofencingTest
- (void)setUp
{
    [super setUp];
    [self setupTestData];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)setupTestData
{
    NSDictionary *regionData = [GeofencingTest getRegionData];
    self.regions = [GeofencingTest getRegionsFromRegionData:regionData];
    self.locations = [GeofencingTest getLocationsFromRegionData:regionData];
    self.locationManager = [[LPLocationManager alloc] init];
    self.regionNameToRegion =
        [GeofencingTest getRegionNameToRegionDictionaryFromRegions:self.regions];
}

/**
 * Tests testSortRegionsByProximity: of LPLocationManager for various user locations.
 */
- (void)testSortRegionsByProximity
{
    NSArray *expectedRegionNames;

    expectedRegionNames = @[@"NYC", @"Philadelphia", @"Chicago", @"Las Vegas", @"SF"];
    [self assertRegionNamesSortedByProximityTo:@"NYC"
                    equalToExpectedRegionNames:expectedRegionNames];

    // Testing when the user of device is in Philadelphia.
    expectedRegionNames = @[@"Philadelphia", @"NYC", @"Chicago", @"Las Vegas", @"SF"];
    [self assertRegionNamesSortedByProximityTo:@"Philadelphia"
                    equalToExpectedRegionNames:expectedRegionNames];

    // Testing when the user of device is in Chicago.
    expectedRegionNames = @[@"Chicago", @"Philadelphia", @"NYC", @"Las Vegas", @"SF"];
    [self assertRegionNamesSortedByProximityTo:@"Chicago"
                    equalToExpectedRegionNames:expectedRegionNames];

    // Testing when the user of device is in Las Vegas.
    expectedRegionNames = @[@"Las Vegas", @"SF", @"Chicago", @"Philadelphia", @"NYC"];
    [self assertRegionNamesSortedByProximityTo:@"Las Vegas"
                    equalToExpectedRegionNames:expectedRegionNames];

    // Testing when the user of device is in San Francisco.
    expectedRegionNames = @[@"SF", @"Las Vegas", @"Chicago", @"Philadelphia", @"NYC"];
    [self assertRegionNamesSortedByProximityTo:@"SF"
                    equalToExpectedRegionNames:expectedRegionNames];
}

/**
 * Tests setMonitoredRegions:requestAllState: of LPLocationManager when the number of geofences that
 * Leanplum needs to monitor is less than the limit (_maxGeofences).
 * There are 5 geofences: @"NYC", @"Philadelphia", @"Chicago", @"Las Vegas", @"SF".
 */
- (void)testSetMonitoredRegionsUnderLimit
{
    // All 5 regions are expected to be monitored since _maxGeofences < 5.
    NSSet* regionsExpectedToBeMonitored = [NSSet setWithArray:self.regions];
    NSSet* regionsCurrentlyBeingMonitored;

    // Cases when no region is currently being monitored.
    regionsCurrentlyBeingMonitored = [NSSet set];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"NYC"
                              withMaxGeofences:10
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];

    [self checkSetMonitoredRegionsWhenUserIsIn:@"Chicago"
                              withMaxGeofences:9
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];

    // Cases when regions that are currently being monitored still need to be monitored.
    regionsCurrentlyBeingMonitored = [self getSetOfRegionsFromRegionNames:@[@"NYC", @"SF"]];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"NYC"
                              withMaxGeofences:6
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];
}

/**
 * Tests setMonitoredRegions:requestAllState: of LPLocationManager when the number of geofences that
 * Leanplum needs to monitor is more than the limit (_maxGeofences).
 * There are 5 geofences: @"NYC", @"Philadelphia", @"Chicago", @"Las Vegas", @"SF".
 */
- (void)testSetMonitoredRegionsOverLimit
{
    NSSet* regionsCurrentlyBeingMonitored;
    NSSet* regionsExpectedToBeMonitored; // |_maxGeofences| closest regions from the user location.

    // Case when no region is currently being monitored.
    regionsCurrentlyBeingMonitored = [NSSet set];
    regionsExpectedToBeMonitored = [self getSetOfRegionsFromRegionNames:@[@"NYC", @"Philadelphia"]];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"NYC"
                              withMaxGeofences:2
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];

    // Case when regions that are currently being monitored still need to be monitored.
    regionsCurrentlyBeingMonitored
        = [self getSetOfRegionsFromRegionNames:@[@"NYC", @"Philadelphia"]];
    regionsExpectedToBeMonitored =
        [self getSetOfRegionsFromRegionNames:@[@"NYC", @"Philadelphia", @"Chicago"]];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"Philadelphia"
                              withMaxGeofences:3
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];

    // Case when regions that are currently being monitored needs to be stop being monitored.
    regionsCurrentlyBeingMonitored = [self getSetOfRegionsFromRegionNames:@[@"SF"]];
    regionsExpectedToBeMonitored
        = [self getSetOfRegionsFromRegionNames:@[@"NYC", @"Philadelphia", @"Chicago"]];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"Philadelphia"
                              withMaxGeofences:3
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];

    // Case when some regions need to be stop being monitored while some other regions need
    // to be remain being monitored.
    regionsCurrentlyBeingMonitored = [self getSetOfRegionsFromRegionNames:@[@"SF", @"Chicago"]];
    regionsExpectedToBeMonitored =
        [self getSetOfRegionsFromRegionNames:@[@"NYC", @"Philadelphia", @"Chicago", @"Las Vegas"]];
    [self checkSetMonitoredRegionsWhenUserIsIn:@"NYC"
                              withMaxGeofences:4
                regionsCurrentlyBeingMonitored:regionsCurrentlyBeingMonitored
                  regionsExpectedToBeMonitored:regionsExpectedToBeMonitored];
}

/**
 * Tests updateMaxGeofences based on different number of non Leanplum geofences.
 */
- (void)testUpdateMaxGeofences
{
    // Testing the case when there is no geofence set by customer.
    [self checkUpdateMaxGeofencesForNonLPRegions:0];

    // When 5, 11, and 18 geofences are sets.
    [self checkUpdateMaxGeofencesForNonLPRegions:5];
    [self checkUpdateMaxGeofencesForNonLPRegions:11];
    [self checkUpdateMaxGeofencesForNonLPRegions:18];

    // When all 20 geofences are set.
    [self checkUpdateMaxGeofencesForNonLPRegions:20];
}

/**
 * Tests updateGeofenceDistanceUpperBound based on user location.
 */
- (void)testUpdateGeofenceDistanceUpperBound {
    // Testing when user is in NYC. The farthest city is SF.
    [self checkNewDistanceForGeofenceUpdate:@"NYC"
                           withFarthestCity:@"SF"];

    // Testing when user is in Philadelphia. The farthest city is SF.
    [self checkNewDistanceForGeofenceUpdate:@"Philadelphia"
                           withFarthestCity:@"SF"];

    // Testing when user is in SF. The farthest city is NYC.
    [self checkNewDistanceForGeofenceUpdate:@"SF"
                           withFarthestCity:@"NYC"];

    // Testing when user is in Chicago. The farthest city is SF.
    [self checkNewDistanceForGeofenceUpdate:@"Chicago"
                           withFarthestCity:@"SF"];
}

/**
 * Tests |filterLeanplumRegions| of LPLocationManager
 */
- (void)testFilterLeanplumRegions
{
    NSMutableSet *allRegions;
    NSSet *expectedLeanplumRegions;
    NSSet *leanplumRegions;

    // Testing when regions are all Leanplum regions.
    allRegions = [[NSSet setWithArray:self.regions] mutableCopy];
    expectedLeanplumRegions = [NSSet setWithArray:self.regions];
    leanplumRegions = [LPLocationManager filterLeanplumRegions:allRegions];
    XCTAssertTrue([leanplumRegions isEqualToSet:expectedLeanplumRegions]);

    // Testing when regions have both Leanplum regions and non-Leanplum regions.
    [allRegions unionSet:[GeofencingTest generateSomeNonLeanplumRegions:4]];
    leanplumRegions = [LPLocationManager filterLeanplumRegions:allRegions];
    XCTAssertTrue([leanplumRegions isEqualToSet:expectedLeanplumRegions]);

    // Testing when none of the regions are Leanplum regions.
    allRegions = [GeofencingTest generateSomeNonLeanplumRegions:10];
    leanplumRegions = [LPLocationManager filterLeanplumRegions:allRegions];
    XCTAssertTrue([leanplumRegions count] == 0);
}

#pragma mark - Helper methods

/**
 * Converts JSON region data to a dictionary.
 */
+ (NSDictionary *)getRegionData
{
    NSString *jsonString = [GeofencingTest retrieve_string_from_file:@"regionData" ofType:@"json"];
    NSDictionary *regionData = [LPJSON JSONFromString:jsonString];
    return regionData;
}

/**
 * Get a location dictionary from region data dictionary.
 * Key: region name
 * Value: location
 */
+ (NSDictionary *)getLocationsFromRegionData:(NSDictionary *)regionData
{
    NSMutableDictionary *regionLocation = [NSMutableDictionary dictionary];
    for (NSString *regionName in regionData) {
        NSNumber *latitude = [[regionData objectForKey:regionName] objectForKey:@"lat"];
        NSNumber *longitude = [[regionData objectForKey:regionName] objectForKey:@"lon"];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                                          longitude:[longitude doubleValue]];
        [regionLocation setObject:location forKey:regionName];
    }
    return regionLocation;
}

/**
 * Returns a mutable array of CLRegion from region data dictionary.
 */
+ (NSMutableArray *)getRegionsFromRegionData:(NSDictionary *)regionData
{
    NSMutableArray *regions = [NSMutableArray array];
    for (NSString *regionName in regionData) {
        CLRegion *region =
            [LPLocationManager regionFromDictionary:[regionData objectForKey:regionName]
                                           withName:regionName];
        [regions addObject:region];
    }
    return regions;
}

/**
 * Returns an array of region names from an array of regions.
 */
+ (NSArray *)getRegionNamesFromRegions:(NSArray *)regions
{
    NSMutableArray *regionNames = [NSMutableArray array];
    for (CLRegion *region in regions) {
        // Extracting NAME from identifer @"__leanplum{NAME}_{VERSION}".
        NSString *identifer = [region identifier];
        NSUInteger indexOfLastUnderscore = [identifer rangeOfString:@"_"
                                                            options:NSBackwardsSearch].location;
        NSRange range = NSMakeRange(10, indexOfLastUnderscore - 10);
        NSString *regionName = [[region identifier] substringWithRange:range];
        [regionNames addObject:regionName];
    }
    return regionNames;
}

/**
 * Returns a region name to region dictionary from an array of regions.
 */
+ (NSDictionary *)getRegionNameToRegionDictionaryFromRegions:(NSArray *)regions
{
    NSArray *regionNames = [GeofencingTest getRegionNamesFromRegions:regions];
    return [NSDictionary dictionaryWithObjects:regions forKeys:regionNames];
}

/**
 * Returns a set of regions from an array of region names.
 */
- (NSSet *)getSetOfRegionsFromRegionNames:(NSArray *)regionNames
{
    NSMutableSet *regions = [NSMutableSet set];
    for (NSString *regionName in regionNames) {
        [regions addObject:[self.regionNameToRegion objectForKey:regionName]];
    }
    return regions;
}

/**
 * A helper method for testSortRegionsByProximity.
 * Sort regions by proximity to the location of user, and assert that sorted regions is equal to the
 * expected regions.
 */
- (void)assertRegionNamesSortedByProximityTo:(NSString *)userCity
                  equalToExpectedRegionNames:(NSArray *)expectedRegionNames
{
    self.locationManager.userLocation = [self.locations objectForKey:userCity];
    NSMutableArray *regions = self.regions;
    [self.locationManager sortRegionsByProximity:regions];
    NSArray *regionNamesSortedByProximty =
        [GeofencingTest getRegionNamesFromRegions:self.regions];

    XCTAssertTrue([regionNamesSortedByProximty isEqualToArray:expectedRegionNames]);
}

/**
 * A helper method for testSetMonitoredRegions.
 * Checks if stopMonitoringForRegion and startMonitoringForRegion are properly called.
 */
- (void)checkSetMonitoredRegionsWhenUserIsIn:(NSString *)userCity
                            withMaxGeofences:(NSUInteger)maxGeofences
              regionsCurrentlyBeingMonitored:(NSSet *)regionsCurrentlyBeingMonitored
                regionsExpectedToBeMonitored:(NSSet *)regionsExpectedToBeMonitored;

{
    self.locationManager.userLocation =  [self.locations objectForKey:userCity];
    self.locationManager.maxGeofences = maxGeofences;

    id mockLPLocationManager = OCMPartialMock(self.locationManager);
    id mockLocationManager = OCMPartialMock([self.locationManager locationManager]);
    OCMStub([mockLPLocationManager locationManager]).andReturn(mockLocationManager);
    OCMStub([mockLocationManager monitoredRegions]).andReturn(regionsCurrentlyBeingMonitored);

    __block NSMutableSet *regionsStartedBeingMonitored = [NSMutableSet set];
    __block NSMutableSet *regionsStopBeingMonitored = [NSMutableSet set];

    // For each call of startMonitoringForRegion store region in a regionsStartedBeingMonitored.
    OCMStub([mockLocationManager startMonitoringForRegion:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained CLRegion *region;
            [invocation getArgument:&region atIndex:2];
            [regionsStartedBeingMonitored addObject:region];
        });

    // For each call of stopMonitoringForRegion store region in a regionsStopBeingMonitored.
    OCMStub([mockLocationManager stopMonitoringForRegion:[OCMArg any]])
        .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained CLRegion *region;
            [invocation getArgument:&region atIndex:2];
            [regionsStopBeingMonitored addObject:region];
        });

    NSMutableSet* expectedStartRegions = [regionsExpectedToBeMonitored mutableCopy];
    [expectedStartRegions minusSet:regionsCurrentlyBeingMonitored];

    NSMutableSet* expectedStopRegions = [regionsCurrentlyBeingMonitored mutableCopy];
    [expectedStopRegions minusSet:regionsExpectedToBeMonitored];

    [self.locationManager setMonitoredRegions:regionsExpectedToBeMonitored requestAllState:YES];

    XCTAssertTrue([regionsStartedBeingMonitored isEqualToSet:expectedStartRegions]);
    XCTAssertTrue([regionsStopBeingMonitored isEqualToSet:expectedStopRegions]);

    [mockLPLocationManager stopMocking];
    [mockLocationManager stopMocking];
}

/**
 * Cancels all regions that are being monitored and sets |numberOfRegions| arbitrary non-Leaplum
 * geofences.
 */
- (void)setLocationManagerToMonitorArbitraryRegions:(NSUInteger)numberOfRegions
{
    CLLocationManager *locationManager = [self.locationManager locationManager];

    NSMutableArray *regions = [NSMutableArray new];
    for (NSInteger i = 0; i < numberOfRegions; i++) {
        NSString *identifer = [NSString stringWithFormat:@"arbitraryRegion%ld", (long) i];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(i, i);

        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:coordinate
                                                             radius:i
                                                         identifier:identifer];
        [regions addObject:region];
    }
    
    OCMStub([locationManager monitoredRegions]).andReturn([NSSet setWithArray:regions]);
}

/**
 * A helper method for testUpdateMaxGeofences.
 */
- (void)checkUpdateMaxGeofencesForNonLPRegions:(NSUInteger)alreadyMonitoredRegionsCount
{
    id  mockLocationManager = OCMClassMock([CLLocationManager class]);
    self.locationManager.locationManager = mockLocationManager;
    
    CLLocationManager *locationManager = [self.locationManager locationManager];
    
    NSUInteger unusedGeofencesCount = IOS_GEOFENCE_LIMIT - alreadyMonitoredRegionsCount;
    NSUInteger expectedMaxGeofences = MIN(self.locationManager.maxGeofences,
                                          unusedGeofencesCount);

    [self setLocationManagerToMonitorArbitraryRegions: alreadyMonitoredRegionsCount];
    XCTAssertEqual([locationManager.monitoredRegions count], alreadyMonitoredRegionsCount);

    [self.locationManager updateMaxGeofences];
    XCTAssertEqual(self.locationManager.maxGeofences, expectedMaxGeofences);
}

/**
 * Checks if |_geofenceDistanceUpperBound| is correctly set given a user location and farthest city
 * from the user location.
 */
- (void)checkNewDistanceForGeofenceUpdate:(NSString *)userCity
                         withFarthestCity:(NSString *)farthestCity
{
    CLLocation *userLocation = [self.locations objectForKey:userCity];
    CLLocation *farthestLocation = [self.locations objectForKey:farthestCity];
    CLCircularRegion *fartherRegion = [self.regionNameToRegion objectForKey:farthestCity];

    self.locationManager.userLocation = userLocation;

    NSSet *regions = [NSSet setWithArray:self.regions];
    [self.locationManager updateGeofenceDistanceUpperBound:regions];

    CLLocationDistance expectedDistance = [userLocation distanceFromLocation:farthestLocation] -
        fartherRegion.radius;
    CLLocationDistance difference = fabs(self.locationManager.geofenceDistanceUpperBound -
        expectedDistance);

    // Allow some room for floating point precision.
    XCTAssertTrue(difference < 0.1);
}

/**
 * A helper method for filterLeanplumRegions.
 * Returns given number of non Leanplum regions.
 */
+ (NSMutableSet *)generateSomeNonLeanplumRegions:(NSInteger)numberOfRegions
{
    NSMutableSet *regions = [NSMutableSet set];
    for (NSInteger i = 0; i < numberOfRegions; i++) {
        NSString *identifer = [NSString stringWithFormat:@"arbitraryRegion%ld", (long) i];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(i, i);
        CLRegion *region = [[CLCircularRegion alloc] initWithCenter:coordinate
                                                             radius:i
                                                         identifier:identifer];
        [regions addObject:region];
    }
    return regions;
}

+ (NSString *)retrieve_string_from_file:(NSString *)file ofType:(NSString *)type {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:file ofType:type];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    
    return content;
}
@end
