YQUpdateHelper
====================

YQUpdateHelper will post a local notification if there is a new version of your app!

It's really a simple thing to use it, what you should do is add several lines code in your  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions:

    [YQUpdateHelper singleton].checkInterval = YQCheckDayly;
    [YQUpdateHelper singleton].appName = @"Test demo";
    [[YQUpdateHelper singleton]setAppID:@"593444693"];

And you also should one line code in - (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification method like this :

    [[YQUpdateHelper singleton] shouldHandleNotification:notification];

