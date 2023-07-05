#import <Cordova/CDV.h>
#import <EGHL/EGHL.h>

@interface EGHL : CDVPlugin <UINavigationControllerDelegate>

- (void)pluginInitialize;

- (void)makePayment: (CDVInvokedUrlCommand*)command;
- (void)mpeRequest: (CDVInvokedUrlCommand*)command;

- (void)endPaymentSuccessfullyWithResult: (PaymentRespPARAM*)result;
- (void)endPaymentWithFailureMessage: (PaymentRespPARAM*)result;
- (void)endPaymentWithCancellation: (PaymentRespPARAM*)result;

@end
