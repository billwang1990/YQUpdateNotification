YQUpdateHelper
====================

YQUpdateHelper will post a local notification if there is a new version of your app!

##How to use it?

I strongly recommend you use cocoapods to install:

	pod 'YQUpdateHelper', '~> 0.1.1'
	
It's really simple to use it, you should add several lines code in  

	- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions:{
	
    	[YQUpdateHelper singleton].checkInterval = YQCheckDayly;
    	[YQUpdateHelper singleton].appName = @"Test demo";
    	[[YQUpdateHelper singleton]setAppID:@"your app id"];
    	
    }

And you also should one line code in
	
	- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{

    [[YQUpdateHelper singleton] shouldHandleNotification:notification];
    
    }
    
    
    
Have fun!
