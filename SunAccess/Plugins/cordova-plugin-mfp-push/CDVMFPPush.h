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
#import <IBMMobileFirstPlatformFoundationPush/IBMMobileFirstPlatformFoundationPush.h>
#import <UIKit/UIKit.h>
#import "MFPAppDelegate+push.h"

@interface CDVMFPPush: CDVPlugin{
    NSMutableArray *pending;
}

@property (strong, nonatomic) NSString *registerCallbackId;
@property (strong, nonatomic) NSString *notifCallbackId;
@property (nonatomic, strong) NSMutableDictionary* launchOptions;

@property (strong, nonatomic) id<CDVCommandDelegate>  registerCommandDelegate;
@property (strong, nonatomic) id<CDVCommandDelegate>  notifCommandDelegate;

- (void) initialize:(CDVInvokedUrlCommand*)command;
- (void) isPushSupported: (CDVInvokedUrlCommand*)command;
- (void) registerDevice: (CDVInvokedUrlCommand*)command;
- (void) unregisterDevice: (CDVInvokedUrlCommand*)command;
- (void) subscribe: (CDVInvokedUrlCommand*)command;
- (void) unsubscribe: (CDVInvokedUrlCommand*)command;
- (void) getTags: (CDVInvokedUrlCommand*)command;
- (void) getSubscriptions: (CDVInvokedUrlCommand*)command;
- (void) registerNotificationsCallback: (CDVInvokedUrlCommand*)command;
- (void) backgroundJobDone:(CDVInvokedUrlCommand *)command;
@end
