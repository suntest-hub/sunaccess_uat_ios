/*
   Licensed Materials - Property of IBM

   (C) Copyright 2016 IBM Corp.

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import <objc/runtime.h>
#import "CDVMFPPush.h"

extern NSString *const CDVMFPPushDidRegisterForRemoteNotificationsWithDeviceToken;
extern NSString *const CDVMFPPushDidFailToRegisterForRemoteNotificationsWithError;
extern NSString *const CDVMFPPushDidReceiveRemoteNotification;
typedef void (^CompletionHandler)(UIBackgroundFetchResult);
static NSMutableDictionary *completionHandlers;

@interface AppDelegate(push)

@end
