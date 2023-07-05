/*
   Licensed Materials - Property of IBM

   (C) Copyright 2016 IBM Corp.

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */
#import "MFPAppDelegate+push.h"


NSString *const CDVMFPPushDidRegisterForRemoteNotificationsWithDeviceToken = @"CDVMFPPushDidRegisterForRemoteNotificationsWithDeviceToken";
NSString *const CDVMFPPushDidFailToRegisterForRemoteNotificationsWithError = @"CDVMFPPushDidFailToRegisterForRemoteNotificationsWithError";
NSString *const CDVMFPPushDidReceiveRemoteNotification = @"CDVMFPPushDidReceiveRemoteNotification";

@implementation AppDelegate(push)

static int callback_id = 0;

+(void)load {
    
    Method original, swizzled;
    
    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(myinit));
    method_exchangeImplementations(original, swizzled);
    
}

- (AppDelegate *) myinit {
    
    return [self myinit];
}


- (void) application:(UIApplication *) application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSLog(@"APNS Token Registered");
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVMFPPushDidRegisterForRemoteNotificationsWithDeviceToken object:deviceToken];
}

- (void) application:(UIApplication*)application didFailToRegisterForRemoteNotifications: (NSError*) error {
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVMFPPushDidFailToRegisterForRemoteNotificationsWithError object:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVMFPPushDidReceiveRemoteNotification object:userInfo];
}

- (void) application:(UIApplication *)application 
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    userInfo = [self processSilentNotification:userInfo fetchCompletionHandler:completionHandler];
    NSNumber *isSilent = userInfo[@"aps"][@"content-available"];

    [[NSNotificationCenter defaultCenter] postNotificationName:CDVMFPPushDidReceiveRemoteNotification object:userInfo];
    if([isSilent intValue] != 1){
        completionHandler(UIBackgroundFetchResultNoData);
    }
    else{
        //handler will be called once the download is completed in javascript and call backs the methods.
    }
    
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler{
    
    NSMutableDictionary *aps =  [[NSMutableDictionary alloc ] initWithDictionary:(NSDictionary *)userInfo[@"aps"]];
    [aps setValue:identifier forKey:@"action-id"];
    
    NSMutableDictionary *newUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
    [newUserInfo setValue:aps forKey:@"aps"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVMFPPushDidReceiveRemoteNotification object:newUserInfo];
    completionHandler();
}

-(NSDictionary *)processSilentNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler{
    NSNumber *contentAvailable = userInfo[@"aps"][@"content-available"];
    if([contentAvailable intValue] == 1){
        
        NSString *id = [NSString stringWithFormat:@"%i", -1];
        if(handler != nil){
            callback_id = callback_id + 1;
            if(callback_id <= 0 )
                callback_id = 1;
            id = [NSString stringWithFormat:@"%i", callback_id];
            if(!completionHandlers){
                completionHandlers = [[NSMutableDictionary alloc] init];
            }
            
            [completionHandlers setValue:handler forKey:id];
        }
        
        NSMutableDictionary *aps =  [[NSMutableDictionary alloc ] initWithDictionary:(NSDictionary *)userInfo[@"aps"]];
        
        [aps setValue:id forKey:@"callback-id"];
        
        NSMutableDictionary *newUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
        [newUserInfo setValue:aps forKey:@"aps"];
        return newUserInfo;
    }
    return userInfo;
}


@end
