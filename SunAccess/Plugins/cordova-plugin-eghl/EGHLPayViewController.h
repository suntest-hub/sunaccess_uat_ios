#import <UIKit/UIKit.h>
#import "EGHL.h"
#import <EGHL/EGHL.h>

@interface EGHLPayViewController : UIViewController

- (id)initWithEGHLPlugin: (EGHL*)cdvPlugin andPayment:(PaymentRequestPARAM*)payment andOtherParams:(NSDictionary*)otherParams;

- (void)QueryResult: (PaymentRespPARAM*)result;
- (void)displayError:(NSString*) errorData;
@end
