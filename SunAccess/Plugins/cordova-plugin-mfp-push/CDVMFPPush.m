/*
   Licensed Materials - Property of IBM

   (C) Copyright 2016 IBM Corp.

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */
 
#import "CDVMFPPush.h"


// private methods declaration
@interface CDVMFPPush()
    void _setValueIfExists(NSString *key, NSDictionary *source, NSMutableDictionary *dest);
    NSSet* _createCategories(NSArray *categoryArray);
    NSArray* _createActionsDictionary(NSArray *actionArray);
    NSArray* _filterActions(NSArray *actionIds,NSArray* actions);
@end

@implementation CDVMFPPush

typedef enum MFPUIUserNotificationActionContext : NSUInteger {
    MFPUIUserNotificationActionContextDefault,
    MFPUIUserNotificationActionContextMinimal
} MFPUIUserNotificationActionContext;

typedef enum MFPUIUserNotificationActivationMode : NSUInteger {
    MFPUIUserNotificationActivationModeForeground,
    MFPUIUserNotificationActivationModeBackground
} MFPUIUserNotificationActivationMode;


@synthesize registerCallbackId;
@synthesize registerCommandDelegate;
@synthesize notifCallbackId;
@synthesize notifCommandDelegate;


- (void) pluginInitialize {
    [super pluginInitialize];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotifications:) name:CDVMFPPushDidRegisterForRemoteNotificationsWithDeviceToken object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToRegisterForRemoteNotifications:) name:CDVMFPPushDidFailToRegisterForRemoteNotificationsWithError object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:CDVMFPPushDidReceiveRemoteNotification object:nil];
    
    [self processRemoteNotificationsOnPluginInitialization];
}

- (void)processRemoteNotificationsOnPluginInitialization
{

    if(!self.launchOptions){
        self.launchOptions = [[NSMutableDictionary alloc] init];
    }
    @synchronized(self.launchOptions) {
        NSDictionary *userInfo = [self.launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo) {
            [self processRemoteNotification:userInfo];
            // Remove remote notifications info from the launch options to eliminate duplicate handling
            [self.launchOptions removeObjectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        }
    }
}


/*
 * Initializes MFPPush instance
 */

- (void) initialize: (CDVInvokedUrlCommand*)command {
    
    CDVPluginResult *result = nil;
    
    NSArray* arguments = [[NSArray alloc]initWithArray:command.arguments];
    id timeoutArg = [arguments objectAtIndex:0];
    NSTimeInterval timeout = [timeoutArg doubleValue];
    MFPPush *push = [MFPPush sharedInstance];
    if(push != nil) {
        [push initialize:timeout];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];

}

/*
 * Checks whether push notification is supported.
 */
- (void) isPushSupported: (CDVInvokedUrlCommand*)command {
    
    NSString *isSupported = @"true";
    BOOL isPushSupported = [[MFPPush sharedInstance] isPushSupported];
    if(!isPushSupported) {
        isSupported = @"false";
    }
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:isSupported];
    
    [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
}


/*
 * Registers the device with APNs
 */
-(void) registerDevice: (CDVInvokedUrlCommand*)command {
    
    registerCallbackId = command.callbackId;
    registerCommandDelegate = self.commandDelegate;
    NSDictionary* options = NULL;
    NSDictionary* iosOptions = NULL;

    
    NSArray* arguments = [[NSArray alloc]initWithArray:command.arguments];
    NSLog(@"Value of arguments count is %lu", (unsigned long)arguments.count);
    if ([arguments count] > 0) {
        NSLog(@"arguments are not null");
        options = [[NSDictionary alloc]initWithDictionary:[arguments objectAtIndex:0]];
        
        iosOptions = _setDeviceOptions(options);
    }
    
    [self.commandDelegate runInBackground:^{
        
        [[MFPPush sharedInstance]registerDevice:iosOptions completionHandler:^(WLResponse *response, NSError *error){
            CDVPluginResult *result = nil;
            if (error != nil) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response.responseText];
            }
            [registerCommandDelegate sendPluginResult:result callbackId:registerCallbackId];
            
        }];
        
        
    }];

}


/*
 * Unregisters the device with MFP Push Notification Server
 */
-(void) unregisterDevice: (CDVInvokedUrlCommand*)command  {
    
    [self.commandDelegate runInBackground:^{
        [[MFPPush sharedInstance] unregisterDevice:^(WLResponse *response, NSError *error) {
            CDVPluginResult *result = nil;
            if (error != nil) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response.description];
            }
            [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        }];
        
    }];
}

/*
 * Subscribes to a particular backend mobile application Tag(s)
 */
-(void) subscribe: (CDVInvokedUrlCommand*)command  {
    
    [self.commandDelegate runInBackground:^{
        id tags = command.arguments[0];
        if([tags isKindOfClass:[NSString class]]){
            NSArray *tagsArray = [tags componentsSeparatedByString:@","];
            [[MFPPush sharedInstance] subscribe:tagsArray completionHandler:^(WLResponse *response, NSError *error) {
                CDVPluginResult *result = nil;
                if (error != nil) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response.responseText];
                }
                [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
            }];
        } else {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tag Parameter is Invalid."];
            [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        }
    }];
}

/*
 * Unsubscribes from particular backend mobile application Tag(s)
 */
-(void) unsubscribe: (CDVInvokedUrlCommand*)command  {
    
    [self.commandDelegate runInBackground:^{
        id tags = command.arguments[0];
        if([tags isKindOfClass:[NSString class]]){
            NSArray *tagsArray = [tags componentsSeparatedByString:@","];
            [[MFPPush sharedInstance] unsubscribe:tagsArray completionHandler:^(WLResponse *response, NSError *error) {
                CDVPluginResult *result = nil;
                if (error != nil) {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                } else {
                    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response.responseText];
                }
                [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
            }];
        } else {
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tag Parameter is Invalid."];
            [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
        }
    }];
}
/*
 * Gets all the available Tags for the backend mobile application
 */
-(void) getTags: (CDVInvokedUrlCommand*)command {
    
    [self.commandDelegate runInBackground:^{
        
        [[MFPPush sharedInstance] getTags:^(WLResponse *response, NSError *error) {
            CDVPluginResult *result = nil;
            if (error != nil) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:response.availableTags];
            }
            [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
            
        }];
        
    }];
}


/*
 * Gets the Tags that are subscribed by the device
 */
-(void) getSubscriptions: (CDVInvokedUrlCommand*)command {
    
    [self.commandDelegate runInBackground:^{
        
        [[MFPPush sharedInstance] getSubscriptions:^(WLResponse *response, NSError *error) {
            CDVPluginResult *result = nil;
            if (error != nil) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            } else {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:response.subscriptions];
            }
            [self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];
            
        }];
        
    }];
}

-(void) registerNotificationsCallback: (CDVInvokedUrlCommand*)command  {
    
    notifCallbackId = command.callbackId;
    notifCommandDelegate = self.commandDelegate;
    
    [self dispatch];
}

-(void) backgroundJobDone:(CDVInvokedUrlCommand *)command {
    NSString *id = [[NSString alloc] initWithString:[command.arguments objectAtIndex:0]];
    int jsResult = [[command.arguments objectAtIndex:1] intValue];
    CompletionHandler handler = (CompletionHandler)[completionHandlers objectForKey:id];
    if(handler){
        UIBackgroundFetchResult result = UIBackgroundFetchResultNoData;
        if(jsResult < 0){
            result = UIBackgroundFetchResultFailed;
        }
        if(jsResult > 0){
            result = UIBackgroundFetchResultNewData;
        }
        handler(result);
        [completionHandlers removeObjectForKey:id];
    }
}

// Internal functions

/*
 * Function called after registered for remote notifications. Registers device token from APNs with MFP Push Server.
 */
-(void) didRegisterForRemoteNotifications: (NSNotification*) notification {
    
    NSData* deviceToken = [notification object];
    
    if (registerCallbackId == nil) {
        return;
    }
    
    
    [registerCommandDelegate runInBackground:^{
        
        [[MFPPush sharedInstance] sendDeviceToken:deviceToken];
        
    }];
}

-(void) didFailToRegisterForRemoteNotifications: (NSNotification*) notification {
    

    NSError* error = [notification object];
    
    if (registerCallbackId == nil) {
        return;
    }
    
    [registerCommandDelegate runInBackground:^{
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        [registerCommandDelegate sendPluginResult:result callbackId:registerCallbackId];
    }];
}

-(void) didReceiveRemoteNotification: (NSNotification*) notification {
    NSDictionary* userInfo = [notification object];
    [self processRemoteNotification:userInfo];
    
}


-(void) processRemoteNotification: (NSDictionary*) notification {
    
    NSMutableDictionary *notif = [[NSMutableDictionary alloc] init];
    NSDictionary *aps = [notification objectForKey:@"aps"];
    _setValueIfExists(@"alert", aps, notif);
    _setValueIfExists(@"badge", aps, notif);
    _setValueIfExists(@"sound", aps, notif);
    _setValueIfExists(@"content-available",aps,notif);
    //If the props contains content-available Initialize to -1 and overwrite with value if callback-id is available
    if([notif objectForKey:@"content-available"]){
        [notif setValue:@"-1" forKey:@"callback-id"];
    }
    _setValueIfExists(@"callback-id",aps,notif);
    _setValueIfExists(@"category",aps,notif);
    _setValueIfExists(@"action-id",aps,notif);
    
    NSDictionary *payload;
    if ([notification objectForKey:@"payload"] != nil){
        payload = [notification objectForKey:@"payload"];
        NSLog(@"Payload : %@",[payload description]);
    } else {
        NSLog(@"Payload is null, attaching empty payload");
        payload = @{};
    }
    [notif setValue:payload forKey:@"payload"];
    
    [self queueMessage:notif];
}

- (void) sendToJSCallback: (NSMutableDictionary *) notification  {

    [notifCommandDelegate runInBackground:^{
        CDVPluginResult *result = nil;
        if (notification == nil) {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error in receiving notification"];
            [result setKeepCallbackAsBool:true];
        }
        else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:notification];
            [result setKeepCallbackAsBool:true];
            
        }
        [notifCommandDelegate sendPluginResult:result callbackId:notifCallbackId];
        
    }];
    
}

- (void) queueMessage:(NSMutableDictionary *)notification {
    @synchronized (pending){
        if (!pending) {
            pending = [[NSMutableArray alloc] initWithCapacity:8];
        }
        [pending addObject: notification];
        NSString *isSilent = @"false";
        NSNumber *contentAvialable = [notification objectForKey:@"content-available"];
        if([contentAvialable intValue] == 1){
            if(![notification objectForKey:@"alert"]){
                isSilent = @"true";
            }
            else{
                UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                if(state == UIApplicationStateBackground){
                    isSilent = @"true";
                }
            }
        }
        // Workaround for javascript functions that do some UI.
        // We need to delay a bit to let view appear, otherwise the application will become forzen.
        //TODO: validate when webview is available and not use delay
        if (notifCallbackId != nil) {
            [self performSelector:@selector(dispatchSelector:) withObject:isSilent afterDelay:1];
        }
    }
}

- (void) dispatchSelector: (NSString *) isSilent {
    @synchronized (pending) {
        [self dispatch];
        if([isSilent isEqualToString:@"false"]){
            // Hide notifications from notification center
            NSInteger badgeNum = [[UIApplication sharedApplication] applicationIconBadgeNumber];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNum];
        }
    }
}

- (void) dispatch {
    @synchronized (pending) {
        if (pending)	{
            for (NSInteger i = 0, n = pending.count; i < n; ++i) {
                NSMutableDictionary *notification = [pending objectAtIndex:i];
                
                BOOL setApplicationBadgeNo = NO;
                UIApplication *application = [UIApplication sharedApplication];
                if([application respondsToSelector:@selector(registerUserNotificationSettings:)]){
                    id userNotificationSettings = ((id (*) (id, SEL)) objc_msgSend) (application,@selector(currentUserNotificationSettings));
                    NSUInteger types = ((NSUInteger (*) (id, SEL)) objc_msgSend)(userNotificationSettings, @selector(types));
                    if(types & (1 << 0)){
                        setApplicationBadgeNo = YES;
                    }
                }
                else{
                    if ([application enabledRemoteNotificationTypes] & UIRemoteNotificationTypeBadge) {
                        setApplicationBadgeNo = YES;
                    }
                }
                
                if (setApplicationBadgeNo) {
                    application.applicationIconBadgeNumber = [((NSString *)[notification valueForKey:@"badge"]) intValue];
                }
                [self sendToJSCallback: notification];
            }
            
            [pending removeAllObjects];
        }
    }
}

void _setValueIfExists(NSString *key, NSDictionary *source, NSMutableDictionary *dest) {
    if (!source) return;
    id obj = [source valueForKey:key];
    if (obj) [dest setValue:obj forKey:key];
}

NSSet* _createCategories(NSArray *categoryArray){
    
    NSMutableSet* categories = nil;
    if([categoryArray count] > 0) {
        categories = [[NSMutableSet alloc] init];
        for(id categoryObj in categoryArray){
            NSDictionary *categoryDic = [[NSDictionary alloc] initWithDictionary:categoryObj];
            
            id category = [[NSClassFromString(@"UIMutableUserNotificationCategory") alloc] init];
            
            [category setValue:(NSString *)[categoryDic valueForKey:@"id"] forKey:@"identifier"];
            
            //Create actions array object
            NSArray *actionArray = [[NSArray alloc] initWithArray:[categoryDic valueForKey:@"actions"]];
            NSArray *actions = _createActionsDictionary(actionArray);
            
            
            //Set the default context
            NSArray *defaultContextActionsJSON = [[NSArray alloc] initWithArray:[categoryDic valueForKey:@"defaultContextActions"]];
            NSArray *defaultContextActions = _filterActions(defaultContextActionsJSON, actions);
            if([defaultContextActions count] > 0){
                ((void (*) (id, SEL, id, NSUInteger))objc_msgSend)(category, @selector(setActions:forContext:),defaultContextActions,MFPUIUserNotificationActionContextDefault);
            }
            else{
                ((void (*) (id, SEL, id, NSUInteger))objc_msgSend)(category, @selector(setActions:forContext:),actions ,MFPUIUserNotificationActionContextDefault);
            }
            
            
            //Set the minimal context
            NSArray *minimalContextActionsJSON = [[NSArray alloc] initWithArray:[categoryDic valueForKey:@"minimalContextActions"]];
            NSArray *minimalContextActions = _filterActions(minimalContextActionsJSON, actions);
            if([minimalContextActionsJSON count] > 0){
                ((void (*) (id, SEL, id, NSUInteger))objc_msgSend)(category, @selector(setActions:forContext:),minimalContextActions,MFPUIUserNotificationActionContextMinimal);
            }
            else{
                ((void (*) (id, SEL, id, NSUInteger))objc_msgSend)(category, @selector(setActions:forContext:),actions,MFPUIUserNotificationActionContextMinimal);
            }
            
            [categories addObject:category];
        }
    }
    return categories;
}

NSArray* _createActionsDictionary(NSArray *actionArray){
    
    NSMutableArray *actions = [[NSMutableArray alloc] init];
    for(id actionObj in actionArray){
        NSDictionary *actionDic = [[NSDictionary alloc] initWithDictionary:actionObj];
        
        id action = [[NSClassFromString(@"UIMutableUserNotificationAction") alloc] init];
        
        [action setValue:(NSString *)[actionDic valueForKey:@"id"] forKey:@"identifier"];
        [action setValue: (NSString *)[actionDic valueForKey:@"title"] forKey:@"title"];
        [action setValue:[NSNumber numberWithInt:MFPUIUserNotificationActivationModeForeground] forKey:@"activationMode"];
        
        if([actionDic objectForKey:@"mode"] != nil){
            NSInteger mode = [[actionDic valueForKey:@"mode"] integerValue];
            if(mode  == 0){
                [action setValue:[NSNumber numberWithInt:MFPUIUserNotificationActivationModeBackground] forKey:@"activationMode"];
            }
        }
        
        if([actionDic objectForKey:@"destructive"] != nil){
            BOOL destructive = [[actionDic valueForKey:@"destructive"] boolValue];
            [action setValue:[NSNumber numberWithBool:destructive] forKey:@"destructive"];
        }
        
        if([actionDic objectForKey:@"authenticationRequired"] != nil){
            BOOL requireAuthentication = [[actionDic valueForKey:@"authenticationRequired"] boolValue];
            [action setValue:[NSNumber numberWithBool:requireAuthentication] forKey:@"authenticationRequired"];
        }
        
        [actions addObject:action];
    }
    return actions;
}

NSArray* _filterActions(NSArray *actionIds,NSArray* actions){
    NSMutableArray *filteredActions = [[NSMutableArray alloc]init];
    if([actionIds count] > 0){
        for(NSString *identifier in actionIds){
            for(id action in actions){
                NSString *actionId = (NSString *) [action valueForKey:@"identifier"];
                if([identifier isEqualToString:actionId]){
                    [filteredActions addObject:action];
                    break;
                }
            }
            
        }
    }
    return filteredActions;
}

/*
 * Sets the push notification options.
 */
NSDictionary* _setDeviceOptions(NSDictionary *options) {
    
    CDVPluginResult *result = nil;
    NSDictionary* iosOptions = nil;
    NSObject *phoneNumber = nil;
    if(options != nil && ![options isKindOfClass:[NSNull class]]) {
        
        iosOptions = [options objectForKey:@"ios"];
        phoneNumber = [options objectForKey:@"phoneNumber"];
        
        if(phoneNumber != nil) {
            if(iosOptions == nil) {
                iosOptions = [[NSMutableDictionary alloc] init];
            }
            [iosOptions setValue:phoneNumber forKey:@"phoneNumber"];
        }
        
        if(iosOptions != nil && ![iosOptions isKindOfClass:[NSNull class]]) {

            NSSet *categories = _createCategories([iosOptions objectForKey:@"categories"]);
            [iosOptions setValue:categories forKey:@"categories"];
            
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    /*[self.commandDelegate sendPluginResult:result callbackId:[command callbackId]];*/
    return iosOptions;
}




@end
