//
//  vTranslator
//
//  Created by Vlad Seryakov on 1/9/10.
//

#import "vTranslator.h"
#include <AudioToolbox/AudioToolbox.h>


@implementation vTranslatorController

@synthesize settings, history, overlay, viewport, xmldata, status, from, to, bfrom, bto;


- (id)init 
{
    if (self = [super init]) {
		self.navigationController.toolbarHidden = YES;
		self.navigationController.navigationBarHidden = YES;
		self.sourceType = UIImagePickerControllerSourceTypeCamera;
		self.wantsFullScreenLayout = YES;
		self.allowsEditing = NO;
		self.toolbarHidden = YES;
		self.showsCameraControls = NO;
		self.navigationBarHidden = YES;
		self.delegate = self;
		scanning = NO;
	
		// First time
		if ([[NSUserDefaults standardUserDefaults] stringForKey:@"vTranslator:from"] == nil) {
			[[NSUserDefaults standardUserDefaults] setObject:@"Russian" forKey:@"vTranslator:to"];
			[[NSUserDefaults standardUserDefaults] setObject:@"English" forKey:@"vTranslator:from"];
			[[NSUserDefaults standardUserDefaults] synchronize];    
		}
		
		homedir = [[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"] retain];
		setenv("TESSDATA_PREFIX", [homedir UTF8String], 1);
		
		NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *doc = [dirs objectAtIndex:0];
		histfile = [[doc stringByAppendingPathComponent:@"vhistory.txt"] retain];
		
		history = [[NSMutableArray alloc] init];
		xmldata = [[NSMutableString alloc] init];
		
		lang_to = [[NSArray arrayWithObjects:	
					@"Afrikaans", 
					@"Albanian", 
					@"Arabic", 
					@"Belarusian", 
					@"Bulgarian", 
					@"Catalan", 
					@"Chinese Simplified", 
					@"Chinese Traditionsl",
					@"Croatian", 
					@"Czech", 
					@"Danish",
					@"Dutch", 
					@"English",
					@"Estonian",
					@"Filipino",
					@"Finnish",
					@"French",
					@"Galician", 
					@"German", 
					@"Greek", 
					@"Hebrew", 
					@"Hindi", 
					@"Hungarian",
					@"Icelandic",
					@"Indonesian",
					@"Irish", 
					@"Italian",
					@"Japanese",
					@"Korean", 
					@"Latvian", 
					@"Lithuanian",
					@"Macedonian",
					@"Malay", 
					@"Maltese",
					@"Norwegian", 
					@"Persian", 
					@"Polish", 
					@"Portuguese",
					@"Romanian", 
					@"Russian",
					@"Serbian",
					@"Slovak", 
					@"Slovenian",
					@"Spanish", 
					@"Swahili", 
					@"Swedish", 
					@"Thai", 
					@"Turkish", 
					@"Ukrainian",
					@"Vietnamese",
					@"Welsh", 
					@"Yiddish",
					nil] retain];
		
		lang_to_type = [[NSArray arrayWithObjects: 
					  @"af",
					  @"sq",
					  @"ar",
					  @"be",
					  @"bg",
					  @"ca",
					  @"zh-CH",
					  @"zh-TW",
					  @"hr",
					  @"cz",
					  @"da",
					  @"nl",
					  @"en",
					  @"et",	
					  @"tl",
					  @"fi",
					  @"fr",
					  @"gl",
					  @"de",
					  @"el",
					  @"iw",
					  @"hi",
					  @"hu",
					  @"is",
					  @"id",
					  @"ga",
					  @"it",
					  @"ja",
					  @"ko",
					  @"lv",
					  @"lt",
					  @"mk",
					  @"ms",
					  @"mt",
					  @"no",
					  @"fa",
					  @"pl",
					  @"pt",
					  @"ro",
					  @"ru",
					  @"sr",
					  @"sk",
					  @"sl",
					  @"es",
					  @"sw",
					  @"sv",
					  @"th",
					  @"tr",
					  @"uk",
					  @"vi",
					  @"cy",
					  @"yi",
					  nil] retain];

		lang_from = [[NSArray arrayWithObjects: 
					  @"English", 
					  @"Spanish",
					  @"French", 
					  @"German", 
					  @"Italian",
					  @"Dutch", 
					  @"Portuguese", 
					  nil] retain];
		
		lang_from_type = [[NSArray arrayWithObjects: 
						   @"eng", 
						   @"spa",
						   @"fra",
						   @"deu",
						   @"ita",
						   @"nld",
						   @"por",
						   nil] retain];
    }
	
	NSLog(@"init");
	
    return self;
}


- (void)dealloc 
{
	[homedir release];
	[histfile release];
	[viewport release];
	[overlay release];	
	[status release];
	[from release];
	[to release];
	[bfrom release];
	[bto release];
	[history release];
	[xmldata release];
    [super dealloc];
}

- (void)viewDidLoad
{
	NSLog(@"viewdidLoad");
	
    [super viewDidLoad];
	
	self.overlay = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.overlay.userInteractionEnabled = YES;
	self.overlay.opaque = NO;
	
	UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"overlay.png"]];
	[self.overlay addSubview:bg];
	
	self.viewport = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewport.png"]];
	self.viewport.frame = CGRectMake(200, 30, self.viewport.frame.size.width, self.viewport.frame.size.height);
	[self.overlay addSubview:self.viewport];
	
	self.status = [[UILabel alloc] initWithFrame:CGRectMake(180, 160, 260, 25)];
	self.status.textAlignment = UITextAlignmentCenter;
	self.status.adjustsFontSizeToFitWidth = YES;
	self.status.font = [UIFont systemFontOfSize: 12];
	self.status.textColor = [UIColor yellowColor];
	self.status.backgroundColor = [UIColor clearColor];
	[self.overlay addSubview:self.status];
	self.status.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	self.from = [[UILabel alloc] initWithFrame:CGRectMake(0, 165, 320, 80)];
	self.from.textAlignment = UITextAlignmentCenter;
	self.from.lineBreakMode = UILineBreakModeCharacterWrap;
	self.from.numberOfLines = 0;
	self.from.minimumFontSize = 8;
	self.from.adjustsFontSizeToFitWidth = YES;
	self.from.font = [UIFont boldSystemFontOfSize: 16];
	self.from.textColor = [UIColor greenColor];
	self.from.backgroundColor = [UIColor clearColor];
	self.from.shadowOffset = CGSizeMake(0, -1);  
	self.from.shadowColor = [UIColor grayColor];  
	[self.overlay addSubview:self.from];
	self.from.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	
	self.to = [[UILabel alloc] initWithFrame:CGRectMake(-80, 165, 320, 80)];
	self.to.textAlignment = UITextAlignmentCenter;
	self.to.lineBreakMode = UILineBreakModeWordWrap;
	self.to.numberOfLines = 0;
	self.to.minimumFontSize = 8;
	self.to.adjustsFontSizeToFitWidth = YES;
	self.to.font = [UIFont boldSystemFontOfSize: 16];
	self.to.textColor = [UIColor yellowColor];
	self.to.backgroundColor = [UIColor clearColor];
	self.to.shadowOffset = CGSizeMake(0, -1);  
	self.to.shadowColor = [UIColor grayColor];  
	[self.overlay addSubview:self.to];
	self.to.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	self.bto = [UIButton buttonWithType:UIButtonTypeCustom];
	self.bto.titleLabel.font = [UIFont systemFontOfSize: 9];
	self.bto.tag = 0;
	self.bto.frame = CGRectMake(10, 420, 50, 50);
	[self.bto addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
	[self.bto setBackgroundImage:[UIImage imageNamed:@"to.png"] forState:UIControlStateNormal];
	[self.bto setTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"vTranslator:to"] forState:UIControlStateNormal];
	[self.bto setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.overlay addSubview:self.bto];
	self.bto.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	self.bfrom = [UIButton buttonWithType:UIButtonTypeCustom];
	self.bfrom.titleLabel.font = [UIFont systemFontOfSize: 9];
	self.bfrom.tag = 1;
	self.bfrom.frame = CGRectMake(75, 420, 50, 50);
	[self.bfrom addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
	[self.bfrom setBackgroundImage:[UIImage imageNamed:@"from.png"] forState:UIControlStateNormal];
	[self.bfrom setTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"vTranslator:from"] forState:UIControlStateNormal];
	[self.overlay addSubview:self.bfrom];	
	self.bfrom.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.frame = CGRectMake(140, 420, 50, 50);
	[btn addTarget:self action:@selector(showHistory:) forControlEvents:UIControlEventTouchUpInside];
	[btn setBackgroundImage:[UIImage imageNamed:@"history.png"] forState:UIControlStateNormal];
	[self.overlay addSubview:btn];
	btn.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.frame = CGRectMake(205, 420, 50, 50);
	[btn addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
	[btn setBackgroundImage:[UIImage imageNamed:@"info.png"] forState:UIControlStateNormal];
	[self.overlay addSubview:btn];
	btn.transform = CGAffineTransformMakeRotation((M_PI / 2.0));

	btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.frame = CGRectMake(270, 420, 50, 50);
	[btn addTarget:self action:@selector(clearText:) forControlEvents:UIControlEventTouchUpInside];
	[btn setBackgroundImage:[UIImage imageNamed:@"clear.png"] forState:UIControlStateNormal];
	[self.overlay addSubview:btn];
	btn.transform = CGAffineTransformMakeRotation((M_PI / 2.0));
	
	[self.view addSubview:self.overlay];
	
	[UIView setAnimationsEnabled:YES];
	[UIView beginAnimations:nil context:self.viewport];
	[UIView setAnimationDelay:1.0];
	[UIView setAnimationDuration:.25];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationRepeatCount:9999999999999999999.0];
	[UIView setAnimationRepeatAutoreverses:YES];
	[UIView setAnimationDidStopSelector:@selector(startAnimation:)];
	[self.viewport setAlpha:0.1];
	[UIView commitAnimations];
}

- (NSString *)langType:(NSArray*)list1 list:(NSArray*)list2 name:(NSString *)name
{
	NSInteger idx = [list1 indexOfObject:name];
	if (idx != NSNotFound) {
		return [list2 objectAtIndex:idx];
	}
	return nil;
}


- (void)loadHistory
{
	NSMutableArray *a = [NSKeyedUnarchiver unarchiveObjectWithFile:histfile];
	if (a) {
		for (int i = 0;i < [a count]; i++) {
			[history addObject:[a objectAtIndex:i]];
		}
	}
	NSLog(@"loaded %d records", [history count]);
}

- (void)saveHistory
{
	[NSKeyedArchiver archiveRootObject:history toFile:histfile];
	NSLog(@"saved %d records", [history count]);
}

- (void)addHistory:(id)obj
{
	if ([history count] >= 100) {
		[history removeObjectAtIndex:0];
	}
	[history addObject:obj];
}

- (void)viewDidAppear:(BOOL)animated
{
	NSLog(@"viewDidAppear");

	[super viewDidAppear:animated];
  
	NSString *lang = [self langType:lang_from list:lang_from_type name:self.bfrom.currentTitle];
	NSLog(@"from=%@, lang=%@", self.bfrom.currentTitle, lang);
	
	[[NSUserDefaults standardUserDefaults] setObject:self.bto.currentTitle forKey:@"vTranslator:to"];
	[[NSUserDefaults standardUserDefaults] setObject:self.bfrom.currentTitle forKey:@"vTranslator:from"];
    [[NSUserDefaults standardUserDefaults] synchronize];    

	
	// Notify user about information not being sent anywhere
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"vTranslator:consent"]) {
		UIAlertView *alert = [[UIAlertView alloc]
							   initWithTitle:@"Information"
							   message:@"The captured image is NOT sent or saved anywhere, the Internet connection is needed to connect to Google for translation of the recognized words"
							   delegate:self
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
		
		[alert show];
		[alert release];
	}
	
	tess = new TessBaseAPI();
    tess->SimpleInit([homedir UTF8String], [lang UTF8String], false);
}

- (void)viewDidDisappear:(BOOL)animated
{
	NSLog(@"viewDidDisappear");
	
	tess->End();
	tess = NULL;
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning 
{
	NSLog(@"didReceiveMemoryWarning");
	
    [super didReceiveMemoryWarning];
	
	if (tess && !scanning) {
		tess->ClearAdaptiveClassifier();
	}
}

- (void)showSettings:(id)sender
{    
	NSLog(@"showSettings");
	
	vTranslatorSettingsController *c = [[vTranslatorSettingsController alloc] initWithNibName:@"SettingsView" bundle:nil];
	c.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	c.button = sender;
	c.lang = c.button.tag ? lang_from : lang_to;
	[self presentModalViewController:c animated:YES];
	[c release];
}

- (void)showHistory:(id)sender
{    
	NSLog(@"showHistory");
	
	vTranslatorHistoryController *c = [[vTranslatorHistoryController alloc] initWithNibName:@"HistoryView" bundle:nil];
	c.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	c.history = history;
	[self presentModalViewController:c animated:YES];
	[c release];
}

- (void)showInfo:(id)sender
{    
	NSLog(@"showInfo");
	
	vTranslatorInfoController *c = [[vTranslatorInfoController alloc] initWithNibName:@"InfoView" bundle:nil];
	c.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:c animated:YES];
	[c release];
}

- (void)clearText:(id)sender
{    
	self.to.text = nil;
	self.from.text = nil;
	self.status.text = nil;
}

- (void)setReady:(NSString*)msg
{
	scanning = NO;
	self.status.text = msg;
	[self.viewport setHidden:NO];
	
	if (msg) {
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate); 
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSString *)decodeHtml:(NSString *)str 
{
	unsigned char c;
	const char *s = [str UTF8String];
	NSMutableData *d = [[NSMutableData alloc] init];
	NSMutableData *d2 = [[NSMutableData alloc] init];
	
	// First pass, Unicode
	while (s && *s) {
		switch (*s) {
		case '\\':
			// Unicode symbol	
			if (*(s + 1) == 'u') {	
				c = strtol(s + 2, NULL, 16);
				s += 6;
				[d appendBytes:&c length:1];
				break;
			}
			
		default:
			[d appendBytes:s length:1];
			s++;
		}
	}
	c = 0;
	[d appendBytes:&c length:1];
	s = (const char*)[d mutableBytes];

	// Second pass, entities
	while (s && *s) {
		switch (*s) {
		case '&':
			// HTML entity
			if (*(s + 1) == '#') {
				s += 2;
				c = atoi(s);
				while (*s && isdigit(*s)) {
					s++;
				}
				if (*s == ';') {
					s++;
				}
				[d2 appendBytes:&c length:1];
				break;
			} else
			if (!strncmp(s, "&amp;", 5)) {
				[d2 appendBytes:"&" length:1];
				s += 5;
				break;
			} else
			if (!strncmp(s, "&lt;", 4)) {
				[d2 appendBytes:"<" length:1];
				s += 4;
				break;
			} else
			if (!strncmp(s, "&gt;", 4)) {
				[d2 appendBytes:">" length:1];
				s += 4;
				break;
			} else
			if (!strncmp(s, "&quot;", 6)) {
				[d2 appendBytes:"\"" length:1];
				s += 6;
				break;
			} else
			if (!strncmp(s, "&apos;", 6)) {
				[d2 appendBytes:"'" length:1];
				s += 6;
				break;
			}
			
		default:
				[d2 appendBytes:s length:1];
			s++;
		}
	}
	c = 0;
	[d2 appendBytes:&c length:1];
	
	NSString *rc = [[NSString alloc] initWithCString:(const char*)[d2 mutableBytes] encoding:NSUTF8StringEncoding];
	[d release];
	[d2 release];
	return rc;
}

- (NSString *)escapeUrl:(NSString *)str 
{
    NSString *rc = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("% '\"?=&+<>;:-"), kCFStringEncodingUTF8);
   
    return [rc autorelease];
}

- (void)refreshView:(id)obj
{
	NSLog(@"refreshView: %@", obj);

	self.status.text = @"Translating...";
	
	self.from.text = obj;
	[self.view setNeedsDisplay];
}
	
- (void)startTranslator:(UIImage *)pic
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    	
    CGSize size = [pic size];
    double stride = CGImageGetBytesPerRow([pic CGImage]);
    double bpp = CGImageGetBitsPerPixel([pic CGImage]) / 8.0;
    
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider([pic CGImage]));
    const UInt8 *pixbuf = CFDataGetBytePtr(data);
	CGRect rect = self.viewport.frame;

	// 1536x2048 == 320x480, scan only viewport rectangle, orientation changes after the first scan, detect it on the fly
	double av, ah;
	if (size.width < size.height) {
		av = size.width / 320;
		ah = size.height / 480;
	} else {
		ah = size.width / 480;
		av = size.height / 320;
	}

	NSLog(@"scanning size=%gx%g, bpp=%g, stride=%g, a=%g/%g, viewport=%g,%g,%g,%g", size.width, size.height, bpp, stride, ah, av, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
		
	char* text = tess->TesseractRect(pixbuf, bpp, stride, rect.origin.y * ah, (320 - rect.origin.x - rect.size.width) * av, rect.size.height * ah, rect.size.width * av);
	
	NSString *nstr = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
	nstr = [nstr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	self.from.text = nil;
	self.status.text = nil;
    delete[] text;
	CFRelease(data);
	
	NSLog(@"result area=%g,%g,%g,%g, text=%@, len=%d", rect.origin.y * ah, (320 - rect.origin.x - rect.size.width) * av, rect.size.height * ah, rect.size.width * av, nstr, [nstr length]);
	
	if ([nstr length] == 0) {
		[self setReady:@"No text recognized"];
		[pool release];
		return;
	}
	
	// Update from field in the main thread
	[self performSelectorOnMainThread:@selector(refreshView:) withObject:nstr waitUntilDone:YES];
	
	NSString *url = [NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&langpair=%@%%7C%@&q=%@", 
					 [self escapeUrl:[self langType:lang_to list:lang_to_type name:[self.bfrom currentTitle]]],
					 [self escapeUrl:[self langType:lang_to list:lang_to_type name:[self.bto currentTitle]]],
					 [self escapeUrl:nstr]];
	 
	NSLog(@"url=%@", url);
	 
	NSError *error = nil;
	NSString *resp = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:&error];
	
	if (resp == nil && error) {
		NSLog(@"didFailWithError - %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
		[self setReady:@"Error connecting to Google Translate"];
		[pool release];
		return;
	}
	 
	NSLog(@"resp=%@", resp);
	 
	NSScanner* scanner = [NSScanner scannerWithString:resp];
	 
	if ([scanner scanUpToString:@"\"translatedText\":\"" intoString:NULL] && [scanner scanString:@"\"translatedText\":\"" intoString:NULL]) {
		NSString *text = nil;
		if ([scanner scanUpToString:@"\"}" intoString:&text]) {
			self.from.text = nstr;
			self.to.text = [self decodeHtml:text];
			[self addHistory:[NSArray arrayWithObjects:self.from.text, self.to.text, nil]];
			[self setReady:nil];
		}
	} else {
		[self setReady:@"Could not translate"];
	}
    [pool release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* pic = [info objectForKey:UIImagePickerControllerOriginalImage];

	//UIImageWriteToSavedPhotosAlbum(pic, self, nil, nil);

	self.status.text = @"Scanning...";
	
	[NSThread detachNewThreadSelector:@selector(startTranslator:) toTarget:self withObject:pic];
}

- (void)image:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo:(NSDictionary*)info 
{
	self.status.text = @"Error";
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"vTranslator:consent"];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	if (scanning) {
		return;
	}
	
	UITouch *touch = [touches anyObject];
	CGPoint pos = [touch locationInView:self.view];
	
	NSLog(@"touchesEnded, %gx%g", pos.x, pos.y);
	
	[self.viewport stopAnimating];
	[self.viewport setHidden:YES];
	
	scanning = YES;
	self.status.text = @"Taking picture...";
	self.from.text = nil;
	self.to.text = nil;
	
	[self takePicture];
}


- (BOOL)canBecomeFirstResponder
{
	return YES;
}

@end


@implementation vTranslatorSettingsController

@synthesize button, lang;


- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor]; 
	UIPickerView *picker = (UIPickerView*)[self.view viewWithTag:9999];

	for (int i = 0; i < [lang count]; i++) {
		NSString *l = [lang objectAtIndex:i];
		if (l == [button currentTitle]) {
			[picker selectRow:i inComponent:0 animated:YES];
			break;
		}
	}	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (IBAction)done 
{
	[self dismissModalViewControllerAnimated:YES];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [lang count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	
	return [lang objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	NSString *text = [lang objectAtIndex:row];

	NSLog(@"lang=%@", text);
	
	[self.button setTitle:text forState:UIControlStateNormal];
}

@end


@implementation vTranslatorHistoryController

@synthesize history;


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [history count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:0];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:0] autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize: 12];
	}
	NSArray *a = [history objectAtIndex:indexPath.row];
	if ([a count] > 1) {
		cell.textLabel.text = [a objectAtIndex:0];
		cell.detailTextLabel.text = [a objectAtIndex:1];
		return cell;
	}
	
	return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[history removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (IBAction)clear
{
	[history removeAllObjects];
	UITableView *t = (UITableView*)[self.view viewWithTag:9999];
	[t reloadData];
}

- (IBAction)done 
{
	[self dismissModalViewControllerAnimated:YES];
}

@end



@implementation vTranslatorInfoController


- (IBAction)done 
{
	[self dismissModalViewControllerAnimated:YES];
}

@end



@implementation vTranslatorAppDelegate

@synthesize window, controller;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
	[UIApplication sharedApplication].statusBarHidden = YES;
	
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This device does not have still camera." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
        return;
	}
	
	vTranslatorController *c = [[vTranslatorController alloc] init];
	self.controller = c;
	[c loadHistory];
	[c release];
	
	
	[window addSubview:[self.controller view]];
    [window makeKeyAndVisible];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    exit(0);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	vTranslatorController *c = (vTranslatorController*)self.controller;
	[c saveHistory];
}

- (void)dealloc 
{
    [window release];
    [super dealloc];
}


@end