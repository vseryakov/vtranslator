//
//  vTranslator
//
//  Created by Vlad Seryakov on 1/9/10.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import "baseapi.h"
#else
@class TessBaseAPI;
#endif

@interface vTranslatorSettingsController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
	NSArray *lang;
	UIButton *button;
}

@property (nonatomic, assign) NSArray *lang;
@property (nonatomic, assign) UIButton *button;

- (IBAction)done;

@end


@interface vTranslatorHistoryController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSMutableArray *history;
}

@property (nonatomic, assign) NSMutableArray *history;

- (IBAction)clear;
- (IBAction)done;

@end

@interface vTranslatorInfoController : UIViewController
{
}

- (IBAction)done;

@end


@interface vTranslatorController : UIImagePickerController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> 
{
	vTranslatorSettingsController *settings;
	NSString *homedir;
	NSString *histfile;
	UIView *overlay;
	UILabel *status;
	UILabel *from;
	UILabel *to;
	UIButton *bfrom;
	UIButton *bto;
	NSMutableArray *history;
	NSArray *lang_from;
	NSArray *lang_to;
	NSArray *lang_to_type;
	NSArray *lang_from_type;
	NSMutableString *xmldata;
	UIImageView *viewport;
	TessBaseAPI *tess;
	BOOL scanning;
}

- (void)saveHistory;	

@property (nonatomic, retain) vTranslatorSettingsController *settings;
@property (nonatomic, retain) NSMutableArray *history;
@property (nonatomic, retain) NSMutableString *xmldata;
@property (nonatomic, retain) UIView *overlay;
@property (nonatomic, retain) UILabel *status;
@property (nonatomic, retain) UILabel *from;
@property (nonatomic, retain) UILabel *to;
@property (nonatomic, retain) UIButton *bfrom;
@property (nonatomic, retain) UIButton *bto;
@property (nonatomic, retain) UIImageView *viewport;

@end



@interface vTranslatorAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	vTranslatorController *controller;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet vTranslatorController *controller;

@end





