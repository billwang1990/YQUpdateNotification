//
//  YQUpdate.m
//  YQUpdateNotification
//
//  Created by niko on 13-12-25.
//  Copyright (c) 2013年 billwang1990.github.io. All rights reserved.
//

#import "YQUpdateHelper.h"

/// App Store URL
#define kAppStoreLinkUniversal              @"http://itunes.apple.com/lookup?id=%@"
#define kAppStoreLinkCountrySpecific        @"http://itunes.apple.com/lookup?id=%@&country=%@"

#define kCurrentAppVersion                  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]

#define kYQBundle [[NSBundle mainBundle] pathForResource:@"YQUpdateHelper" ofType:@"bundle"]
#define kYQLocalizedString(stringKey)  [[NSBundle bundleWithPath:kYQBundle] localizedStringForKey:stringKey value:stringKey table:@"YQLocalizable"]

#define kTimeDelayOpenAppStore 1.0f


@interface YQUpdateHelper()
{
    BOOL        _shoulPostLocalNotification;
    NSString    *_currentVersionStr;
}

@end

@implementation YQUpdateHelper

+(instancetype)singleton
{
    static YQUpdateHelper *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[YQUpdateHelper alloc]init];
        
    });

    return instance;
}

-(id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(checkShouldPostLocalNotification) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleLauchNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleLauchNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

-(void)setDelegate:(id<YQUpdateNewVersionNotifyDelegate>)delegate
{
    if (delegate && ![delegate conformsToProtocol:@protocol(YQUpdateNewVersionNotifyDelegate) ]) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Delegate object not conform to the delegate protocol" userInfo:nil] raise];
    }
    _delegate = delegate;
}


-(void)checkVersion
{
    NSString *AppStoreURLString = nil;
    
    if (self.countryCode) {
        AppStoreURLString = [NSString stringWithFormat:kAppStoreLinkCountrySpecific, self.appID, self.countryCode];
    }
    else
        AppStoreURLString = [NSString stringWithFormat:kAppStoreLinkUniversal, self.appID];
    
    NSURL *AppStoreURL = [NSURL URLWithString:AppStoreURLString];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:AppStoreURL];
    [request setHTTPMethod:@"GET"];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
        if ([data length] > 0 && !connectionError) {
    
            //success
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
  
            self.lastVersionCheckDate = [NSDate date];
            
            // All versions that have been uploaded to the AppStore
            NSArray *versionsInAppStore = [[result valueForKey:@"results"] valueForKey:@"version"];
            
            if (0 == [versionsInAppStore count]) { // No versions of app in AppStore

                return;
                
            } else {
                
                NSString *currentAppStoreVersion = [versionsInAppStore objectAtIndex:0];
                
                if ([kCurrentAppVersion compare:currentAppStoreVersion options:NSNumericSearch] == NSOrderedAscending) {
                    
                    _shoulPostLocalNotification = YES;
                    _currentVersionStr = currentAppStoreVersion;


                } else {
                    
                    // Current installed version is the newest public version or newer (e.g., dev version)

                }
            }
        }
    }];
}

-(void)checkShouldPostLocalNotification
{
    if (_shoulPostLocalNotification) {
        [self postNewVersionNotification];
    }
}

-(void)postNewVersionNotification{
    
    NSString *appName = ([self appName]) ? [self appName] : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    
    for (UILocalNotification *note in [UIApplication sharedApplication].scheduledLocalNotifications) {
        if ([note.userInfo[@"YQId"] isEqualToString:@"detectedNewVersion"]) {
            //remove previous local notification
            [[UIApplication sharedApplication]cancelLocalNotification:note];
        }
    }
    
    UILocalNotification *notify = [[UILocalNotification alloc]init];
    notify.fireDate = [NSDate dateWithTimeIntervalSinceNow:2.0];
    notify.hasAction = YES;
    notify.alertBody = [NSString stringWithFormat:kYQLocalizedString(@"%@ has new version, download it now!"), appName];
    notify.alertAction = kYQLocalizedString(@"Update Now");
    notify.userInfo = @{@"YQId": @"detectedNewVersion", @"Version": _currentVersionStr};
    
    [[UIApplication sharedApplication] scheduleLocalNotification:notify];
}

-(void)shouldHandleNotification:(UILocalNotification *)notification
{
    if ([notification.userInfo[@"YQId"] isEqualToString:@"detectedNewVersion"] && ([kCurrentAppVersion compare:[notification.userInfo objectForKey:@"Version"] options:NSNumericSearch] == NSOrderedAscending )) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(hanleNewVersionDetectedEvent)]) {
            [self.delegate hanleNewVersionDetectedEvent];
        }
        else
        {
            //open App store, default action
            [self performSelector:@selector(launchAppStore) withObject:nil afterDelay:kTimeDelayOpenAppStore];
        }
    }
}

-(void)handleLauchNotification:(NSNotification*)notify
{
    if ([notify.name isEqualToString:UIApplicationDidFinishLaunchingNotification]) {
        UILocalNotification *localNotify = nil;
        if ((localNotify = [notify.userInfo objectForKey:UIApplicationLaunchOptionsLocalNotificationKey])) {
            [self shouldHandleNotification:localNotify];
        }
    }
    else if ([notify.name isEqualToString:UIApplicationDidBecomeActiveNotification])
    {
        _shoulPostLocalNotification = NO;
        if (self.checkInterval == YQCheckDayly) {
            [self checkVersionDaily];
        }
        else
            [self checkVersionWeekly];
    }
}

- (void)launchAppStore
{
    NSString *iTunesString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", [self appID]];
    NSLog(@"link %@", iTunesString);
    NSURL *iTunesURL = [NSURL URLWithString:iTunesString];
    
    [[UIApplication sharedApplication] openURL:iTunesURL];

}

-(void)checkVersionDaily
{
    if (!self.lastVersionCheckDate) {
        self.lastVersionCheckDate = [NSDate date];
        [self checkVersion];
    }
    else
    {
        if ([self numbersOfDaysBetweenLastVersionCheckDate] > 1) {
            [self checkVersion];
        }
    }
}

- (void)checkVersionWeekly
{
    if (!self.lastVersionCheckDate) {
        self.lastVersionCheckDate = [NSDate date];
        
        [self checkVersion];
    }
    else
    {
        if ([self numbersOfDaysBetweenLastVersionCheckDate] > 7 ) {
            [self checkVersion];
        }
    }
}

- (NSUInteger)numbersOfDaysBetweenLastVersionCheckDate
{
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [currentCalendar components:NSCalendarUnitDay fromDate:self.lastVersionCheckDate toDate:[NSDate date] options:0];
    
    return [components day];
}


@end
