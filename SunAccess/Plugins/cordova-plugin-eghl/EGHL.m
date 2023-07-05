#import "EGHL.h"
#import "EGHLPayViewController.h"
#import <objc/runtime.h>
#import <EGHL/EGHL.h>

#pragma mark - eGHL secret debug fields...

@interface PaymentRequestPARAM ()
- (void)eghlDebugURL: (NSString *)urlString;
@end


#pragma mark - "Private" variables

@interface EGHL ()

@property Boolean processingInProgress;
@property UINavigationController *contentViewController;
@property CDVInvokedUrlCommand* command;
@property NSArray *eGHLStringParams;
@property NSArray *eGHLStringParams_mpeRequest;

@end


#pragma mark - Implementation

@implementation EGHL

@synthesize processingInProgress;
@synthesize contentViewController;
@synthesize command;
@synthesize eGHLStringParams;
@synthesize eGHLStringParams_mpeRequest;


#pragma mark - Plugin API

- (void)pluginInitialize
{
    if(self.eGHLStringParams == nil) {
        self.eGHLStringParams = @[
            @"Amount",
            @"EPPMonth",
            @"PaymentID",
            @"OrderNumber",
            @"MerchantName",
            @"ServiceID",
            @"PymtMethod",
            @"PaymentType",
            @"MerchantReturnURL",
            @"CustEmail",
            @"Password",
            @"CustPhone",
            @"CurrencyCode",
            @"CustName",
            @"LanguageCode",
            @"PaymentDesc",
            @"PageTimeout",
            @"CustIP",
            @"CustID",
            @"MerchantApprovalURL",
            @"CustMAC",
            @"MerchantUnApprovalURL",
            @"CardHolder",
            @"CardNo",
            @"CardExp",
            @"CardCVV2",
            @"BillAddr",
            @"BillPostal",
            @"BillCity",
            @"BillRegion",
            @"BillCountry",
            @"eghlDebugURL",
            @"HashValue",
            @"PromoCode",
            @"ShipAddr",
            @"ShipPostal",
            @"ShipCity",
            @"ShipRegion",
            @"ShipCountry",
            @"TokenType",
            @"Token",
            @"TransactionType",
            @"SessionID",
            @"IssuingBank",
            @"MerchantCallBackURL",
            @"B4TaxAmt",
            @"TaxAmt",
            @"Param6",
            @"Param7",
            @"ReqToken",
            @"ReqVerifier",
            @"PairingToken",
            @"PairingVerifier",
            @"CheckoutResourceURL",
            @"CardId",
            @"PreCheckoutId",
            @"mpLightboxParameter",
        ];

        self.eGHLStringParams_mpeRequest = @[
            @"ServiceID",
            @"CurrencyCode",
            @"Amount",
            @"TokenType",
            @"Token",
            @"PaymentDesc",
        ];
    }
}

- (void)makePayment: (CDVInvokedUrlCommand*)command
{
    if(self.processingInProgress) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Another request is in progress. Please wait a few seconds."]
                              callbackId:[command callbackId]];
        return;
    }

    NSDictionary *args = (NSDictionary*) [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];
    if(args == nil) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Argument must be an object."]
                              callbackId:[command callbackId]];
        return;
    }

    self.processingInProgress = YES;
    self.command = command;

    PaymentRequestPARAM *payParams = [[PaymentRequestPARAM alloc] init];

    // Get Staging or production environment
    NSString *gatewayUrl = [args objectForKey:@"PaymentGateway"];
    if([gatewayUrl isEqualToString:@"https://pay.e-ghl.com/IPGSG/Payment.aspx"]) {
        payParams.settingDict = @{
            EGHL_DEBUG_PAYMENT_URL: @true,
        };
    }

    payParams.sdkTimeOut = [((NSNumber*) [args objectForKey:@"sdkTimeout"]) doubleValue];
    for(NSString *paramName in self.eGHLStringParams) {
        NSString *paramValue = [args objectForKey:paramName];
        if(paramValue != nil) {
            [payParams setValue:paramValue forKey:paramName];
        }
    }

    EGHLPayViewController *payViewController =
        [[EGHLPayViewController alloc] initWithEGHLPlugin:self
                                       andPayment:payParams
                                       andOtherParams:args];
//    self.contentViewController = [[UINavigationController alloc] initWithRootViewController:payViewController];
//    self.contentViewController.delegate = self;
//    [self.viewController presentViewController:self.contentViewController
//                         animated:YES
//                         completion:^(void){}];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];

        UIViewController *vc = keyWindow.rootViewController;

        EGHLPayment * eghlpay = [[EGHLPayment alloc]init];
        [eghlpay execute:payParams fromViewController:vc successBlock:^(PaymentRespPARAM *responseData) {
            if(!responseData.TxnStatus) {
                [self endPaymentWithFailureMessage:responseData];
            }else if(!responseData.TxnExists || [responseData.TxnExists isEqualToString:@"0"]) {
                if([responseData.TxnStatus isEqualToString:@"0"]) {
                    [self endPaymentSuccessfullyWithResult:responseData];
                }else if([responseData.TxnStatus isEqualToString:@"1"]) {
                    [self endPaymentWithFailureMessage:responseData];
                }else if([responseData.TxnStatus isEqualToString:@"2"]) {
                    [self endPaymentWithCancellation:responseData];
                }else{
                    [self endPaymentWithFailureMessage:responseData];
                }
            }else if(responseData.TxnExists) {
                if([responseData.TxnExists isEqualToString:@"1"]) {
                    [self endPaymentWithCancellation:responseData];
                } else if([responseData.TxnExists isEqualToString:@"2"]) {
                    [self endPaymentWithFailureMessage:responseData];
                }
            }else {
                [self endPaymentWithFailureMessage:responseData];
            }
        } failedBlock:^(NSString *errorCode, NSString *errorData, NSError *error) {
            [payViewController displayError:errorData];
        }];
    });
}

- (void)mpeRequest: (CDVInvokedUrlCommand*)command
{
    if(self.processingInProgress) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Another request is in progress. Please wait a few seconds."]
                              callbackId:[command callbackId]];
        return;
    }

    NSDictionary *args = (NSDictionary*) [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];
    if(args == nil) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Argument must be an object."]
                              callbackId:[command callbackId]];
        return;
    }

    self.processingInProgress = YES;

    PaymentRequestPARAM *params = [[PaymentRequestPARAM alloc] init];

    // Get Staging or production environment
    NSString *gatewayUrl = [args objectForKey:@"PaymentGateway"];
    if([gatewayUrl isEqualToString:@"https://pay.e-ghl.com/IPGSG/Payment.aspx"]) {
        params.settingDict = @{
            EGHL_DEBUG_PAYMENT_URL: @true,
        };
    }

    // Get other params from command arguments.
    params.sdkTimeOut = [((NSNumber*) [args objectForKey:@"sdkTimeout"]) doubleValue];
    for(NSString *paramName in self.eGHLStringParams_mpeRequest) {
        NSString *paramValue = [args objectForKey:paramName];
        if(paramValue != nil) {
            [params setValue:paramValue forKey:paramName];
        }
    }
    
    EGHLPayment *req = [[EGHLPayment alloc] init];
    [req executeMasterpass:params successBlock:^(PaymentRespPARAM *resp) {
        NSDictionary *dict = [self objectAsDictionary:resp];
        self.processingInProgress = NO;
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                messageAsDictionary:dict]
                              callbackId:[command callbackId]];
    } failedBlock:^(NSString *errorCode, NSString *errorData, NSError *error) {
        self.processingInProgress = NO;
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:errorData]
                              callbackId:[command callbackId]];
    }];
    
}


#pragma mark - Return to JS methods

- (void)endPaymentSuccessfullyWithResult: (PaymentRespPARAM*)result
{
    [self dismissContentView];
    self.processingInProgress = NO;

    NSDictionary *dict = [self objectAsDictionary:result];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict]
                          callbackId:[command callbackId]];
}

- (void)endPaymentWithFailureMessage: (PaymentRespPARAM*)result
{
    [self dismissContentView];
    self.processingInProgress = NO;
    
    NSDictionary *dict = [self objectAsDictionary:result];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict]
                          callbackId:[self.command callbackId]];
}

- (void)endPaymentWithCancellation: (PaymentRespPARAM*)result
{
    [self dismissContentView];
    self.processingInProgress = NO;
    // TMP hard code -999 as cancel payment. (follow android SDK.)
    // NSMutableDictionary *result = [NSMutableDictionary dictionary];
    // [result setObject: @""  forKey: @""];
    NSDictionary *dict = [self objectAsDictionary:result];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict]
                          callbackId:[self.command callbackId]];
}


#pragma mark - UINavigationControllerDelegate

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations: (UINavigationController*)navigationController;
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Internal helpers

- (void)dismissContentView
{
    [self.viewController dismissViewControllerAnimated:YES
                         completion:^(void){}];
}


// Get all non-nil fields in an NSObject and returns them in an NSDictionary.
// http://stackoverflow.com/a/31181746
- (NSDictionary*)objectAsDictionary: (NSObject*)object {
    // Get a list of all properties in the class.
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([object class], &count);

    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:count];
    for(int i=0; i<count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        NSString *value = [object valueForKey:key];

        // Only add to the NSDictionary if it's not nil.
        if (value) [dictionary setObject:value forKey:key];
    }

    free(properties);

    return dictionary;
}

@end
