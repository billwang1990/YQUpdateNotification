//
//  YQUpdate.h
//  YQUpdateNotification
//
//  Created by niko on 13-12-25.
//  Copyright (c) 2013年 billwang1990.github.io. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    YQCheckDayly = 1,
    YQCheckWeekly
}YQCheckInterval;

@protocol YQUpdateNewVersionNotifyDelegate <NSObject>

- (void)handleNewVersionDetectedEvent;

@end

@interface YQUpdateHelper : NSObject<UIAlertViewDelegate>


+(instancetype)singleton;

/**
 (OPTIONAL) defaulr check weekly
 */
@property (nonatomic) YQCheckInterval checkInterval;

/**
 (OPTIONAL)If you don't set delegate, the default action when usr tap location notification is open AppStore
*/
@property (nonatomic, weak) id<YQUpdateNewVersionNotifyDelegate> delegate;

/**
 The app id of your app.
 */
@property (strong, nonatomic) NSString *appID;

/**
 (OPTIONAL) The preferred name for the app.
 */
@property (strong, nonatomic) NSString *appName;

/**
 (OPTIONAL) If your application is not availabe in the U.S. Store, you must specify the two-letter
 country code for the region in which your applicaiton is available in.
 */
@property (strong, nonatomic) NSString *countryCode;

/**
 (OPTIONAL) You can specify the local notification alert body string;
 */
@property (strong, nonatomic) NSString *notificationBodyString;

/**
 Add this method in application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
 */
- (void)shouldHandleNotification:(UILocalNotification*)notification;

@end
