//
//  ESDebugConsole.m
//
//  Copyright Doug Russell 2011. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ESDebugConsole.h"
#import <asl.h>

#if !__has_feature(objc_arc)
#define NO_ARC(noarccode) noarccode
#else
#define NO_ARC(noarccode) 
#endif

#define ISPAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define ISPHONE [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone

//#define ASL_KEY_TIME      "Time"
//#define ASL_KEY_HOST      "Host"
//#define ASL_KEY_SENDER    "Sender"
//#define ASL_KEY_FACILITY  "Facility"
//#define ASL_KEY_PID       "PID"
//#define ASL_KEY_UID       "UID"
//#define ASL_KEY_GID       "GID"
//#define ASL_KEY_LEVEL     "Level"
//#define ASL_KEY_MSG       "Message"

NSString *const kESDebugConsoleAllLogsKey = @"ESDebugConsoleAllLogsKey";

@interface ESConsoleEntry ()
@property (nonatomic, retain) NSString *shortMessage;
- (id)initWithDictionary:(NSDictionary *)dictionary;
@end

@interface ESDebugAppListTableViewController : UITableViewController
@property (nonatomic, retain) NSDictionary *allApplicationLogs;
@property (nonatomic, retain) NSArray *allApps;
@end

@interface ESDebugTableViewController : UITableViewController
@property (nonatomic, retain) NSArray *applicationLogs;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@end

@interface ESDebugTableViewCell : UITableViewCell
@property (nonatomic, retain) UILabel *applicationIdentifierLabel;
@property (nonatomic, retain) UILabel *messageLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

@interface ESDebugDetailViewController : UIViewController
@property (nonatomic, retain) UITextView *textView;
@end

@interface ESDebugConsole ()
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UINavigationController *navigationController;
- (void)commonInit;
@end

@implementation ESDebugConsole
@synthesize window=_window;
@synthesize popoverController=_popoverController;
@synthesize navigationController=_navigationController;
@synthesize gestureRecognizer=_gestureRecognizer;
@synthesize size=_size;;

#pragma mark - 

+ (id)sharedDebugConsole
{
	static ESDebugConsole *sharedConsole;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedConsole = [ESDebugConsole new];
	});
	return sharedConsole;
}

NO_ARC(
	   // Little bit of dummy proofing for pre arc singleton
	   - (id)retain { return self; }
	   - (oneway void)release { }
	   - (id)autorelease { return self; }
	   - (NSUInteger)retainCount { return NSUIntegerMax; }
)

- (id)init
{
	self = [super init];
	if (self)
	{
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window)
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	if (window == nil)
	{
		[NSException raise:@"Nil Window Exception" format:@"Activated ESDebugConsole without a window to attach to"];
		return;
	}
	if (window.rootViewController == nil && ISPHONE)
	{
		[NSException raise:@"Nil Root View Controller Exception" format:@"Activated ESDebugConsole without a root view controller to attach to"];
		return;
	}
	self.window = window;
    self.size = CGSizeZero;
	UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognized:)];
	rotationGesture.cancelsTouchesInView = NO;
	self.gestureRecognizer = rotationGesture;
	[window addGestureRecognizer:rotationGesture];
	NO_ARC([rotationGesture release];)
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lowMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	NO_ARC(
		   [_window release];
		   [_popoverController release];
		   [_navigationController release];
		   [_gestureRecognizer release];
		   [super dealloc];
		   )
}

#pragma mark -

//http://www.cocoanetics.com/2011/03/accessing-the-ios-system-log/
//http://developer.apple.com/library/ios/#documentation/System/Conceptual/ManPages_iPhoneOS/man3/asl.3.html#//apple_ref/doc/man/3/asl
+ (NSDictionary *)getConsole
{
	aslmsg q, m;
	int i;
	const char *key, *val;
	NSMutableDictionary *consoleLog;
	
	q = asl_new(ASL_TYPE_QUERY);
	
	consoleLog = [NSMutableDictionary new];
	
	NSMutableArray *allLogs = [NSMutableArray new];
	[consoleLog setObject:allLogs forKey:kESDebugConsoleAllLogsKey];
	NO_ARC([allLogs release];)
	
	aslresponse r = asl_search(NULL, q);
	while (NULL != (m = aslresponse_next(r)))
	{
		NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
		
		for (i = 0; (NULL != (key = asl_key(m, i))); i++)
		{
			NSString *keyString = [NSString stringWithUTF8String:(char *)key];
			
			val = asl_get(m, key);
			
			if (val != NULL)
			{
				NSString *string = [NSString stringWithUTF8String:val];
				
				if (string != nil)
					[tmpDict setObject:string forKey:keyString];
			}
		}
		
		ESConsoleEntry *entry = [[ESConsoleEntry alloc] initWithDictionary:tmpDict];
		if (entry != nil)
		{
			NSMutableArray *logEntries = [consoleLog objectForKey:entry.applicationIdentifier];
			if (logEntries == nil)
			{
				logEntries = [NSMutableArray new];
				[consoleLog setObject:logEntries forKey:entry.applicationIdentifier];
				NO_ARC([logEntries release];)
			}
			[logEntries addObject:entry];
			logEntries = [consoleLog objectForKey:kESDebugConsoleAllLogsKey];
			[logEntries addObject:entry];
			NO_ARC([entry release];)
		}
	}
	aslresponse_free(r);
	
	for (NSMutableArray *logEntries in [consoleLog allValues])
	{
		[logEntries sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO], nil]];
	}
	
	NSDictionary *retVal = [NSDictionary dictionaryWithDictionary:consoleLog];
	
	NO_ARC([consoleLog release];)
	
	return retVal;
}

#pragma mark - 

- (void)lowMemoryWarning:(NSNotification *)notification
{
	[self.popoverController dismissPopoverAnimated:NO];
	self.popoverController = nil;
	if ([self.navigationController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	else
		[self.navigationController dismissModalViewControllerAnimated:YES];
	self.navigationController = nil;
}

#pragma mark - 

- (void)gestureRecognized:(UIGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
		return;
	
	if (ISPAD)
	{
		[self.popoverController presentPopoverFromRect:CGRectMake(0, 0, 10, 10) 
												inView:gestureRecognizer.view 
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
	}
	else if (ISPHONE)
	{
		[self.window.rootViewController presentModalViewController:self.navigationController animated:YES];
	}
}

#pragma mark - 

- (UIPopoverController *)popoverController
{
	if (_popoverController == nil)
	{
		if (!(ISPAD))
			return nil;
		_popoverController = [[UIPopoverController alloc] initWithContentViewController:self.navigationController];
	}
	return _popoverController;
}

- (UINavigationController *)navigationController
{
	if (_navigationController == nil)
	{
		ESDebugAppListTableViewController *tvc = [ESDebugAppListTableViewController new];
        if (!CGSizeEqualToSize(self.size, CGSizeZero))
            tvc.contentSizeForViewInPopover = self.size;
		_navigationController = [[UINavigationController alloc] initWithRootViewController:tvc];
		NO_ARC([tvc release];)
	}
	return _navigationController;
}

- (void)setGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
	if (_gestureRecognizer != gestureRecognizer)
	{
		if (_gestureRecognizer != nil)
			[_gestureRecognizer.view removeGestureRecognizer:_gestureRecognizer];
		NO_ARC(
			   [_gestureRecognizer release];
			   [gestureRecognizer retain];
			   )
		_gestureRecognizer = gestureRecognizer;
	}
}

@end

@implementation ESConsoleEntry
@synthesize message=_message;
@synthesize shortMessage=_shortMessage;
@synthesize applicationIdentifier=_applicationIdentifier;
@synthesize date=_date;

#pragma mark -

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if (self != nil)
	{
		if (dictionary == nil)
		{
			NO_ARC([self release];)
			self = nil;
			return nil;
		}
		
		self.message = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_MSG encoding:NSUTF8StringEncoding]];
		if (self.message.length > 200)
			self.shortMessage = [self.message substringToIndex:200];
		else
			self.shortMessage = self.message;
		self.applicationIdentifier = [dictionary objectForKey:[NSString stringWithCString:ASL_KEY_FACILITY encoding:NSUTF8StringEncoding]];
		self.date = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:[NSString stringWithCString:ASL_KEY_TIME encoding:NSUTF8StringEncoding]] doubleValue]];
	}
	return self;
}

- (void)dealloc
{
	NO_ARC(
		   [_message release];
		   [_shortMessage release];
		   [_applicationIdentifier release];
		   [_date release];
		   [super dealloc];
		   )
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"Application Identifier: %@\n\nConsole Message: %@\n\nTime: %@", self.applicationIdentifier, self.message, self.date];
}

@end

@implementation ESDebugAppListTableViewController
@synthesize allApplicationLogs=_allApplicationLogs;
@synthesize allApps=_allApps;

#pragma mark - 

- (void)dealloc
{
	NO_ARC(
		   [_allApplicationLogs release];
		   [_allApps release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)done:(id)sender
{
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
		[self dismissViewControllerAnimated:YES completion:nil];
	else
		[self dismissModalViewControllerAnimated:YES];
}

- (void)refresh:(id)sender
{
	UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activity startAnimating];
	UIBarButtonItem *activityButton = [[UIBarButtonItem alloc] initWithCustomView:activity];
	NO_ARC([activity release];)
	self.navigationItem.leftBarButtonItem = activityButton;
	NO_ARC([activityButton release];)
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
		NSDictionary *logs = [ESDebugConsole getConsole];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			self.allApplicationLogs = logs;
			NSMutableArray *allApps = [[self.allApplicationLogs allKeys] mutableCopy];
			[allApps removeObject:kESDebugConsoleAllLogsKey];
			self.allApps = allApps;
			NO_ARC([allApps release];)
			[self.tableView reloadData];
			UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
			self.navigationItem.leftBarButtonItem = refreshButton;
			NO_ARC([refreshButton release];)
		});
	});
}

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"App List";
	
	if (ISPHONE)
	{
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
		self.navigationItem.rightBarButtonItem = doneButton;
		NO_ARC([doneButton release];)
	}
	
	[self refresh:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.allApplicationLogs = nil;
	self.allApps = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.allApps)
		return self.allApps.count + 2;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		NO_ARC([cell autorelease];)
	}
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"All";
			break;
		case 1:
			cell.textLabel.text = @"Current";
			break;
		default:
			cell.textLabel.text = [self.allApps objectAtIndex:indexPath.row-2];
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugTableViewController *tvc = [ESDebugTableViewController new];
    tvc.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	switch (indexPath.row) {
		case 0:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:kESDebugConsoleAllLogsKey];
			break;
		case 1:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey]];
			break;
		default:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:[self.allApps objectAtIndex:indexPath.row-2]];
			break;
	}
	[self.navigationController pushViewController:tvc animated:YES];
	NO_ARC([tvc release];)
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end

@implementation ESDebugTableViewController
@synthesize applicationLogs=_applicationLogs;
@synthesize segmentedControl=_segmentedControl;

#pragma mark - 

- (void)dealloc
{
	NO_ARC(
		   [_applicationLogs release];
		   [_segmentedControl release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Console";
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.segmentedControl = nil;
	self.applicationLogs = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.applicationLogs)
		return self.applicationLogs.count;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	ESDebugTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[ESDebugTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		NO_ARC([cell autorelease];)
	}
	
	ESConsoleEntry *entry = [self.applicationLogs objectAtIndex:indexPath.row];
	cell.applicationIdentifierLabel.text = entry.applicationIdentifier;
	cell.messageLabel.text = entry.shortMessage;
	cell.dateLabel.text = [entry.date description];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugDetailViewController *detailViewController = [ESDebugDetailViewController new];
    detailViewController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	detailViewController.textView.text = [NSString stringWithFormat:@"%@", [self.applicationLogs objectAtIndex:indexPath.row]];
	[self.navigationController pushViewController:detailViewController animated:YES];
	NO_ARC([detailViewController release];)
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// This assumes that the table view cells content view is as wide as the actual table,
	// which isn't necessarily true, but works fine here
	CGSize size = [[[self.applicationLogs objectAtIndex:indexPath.row] shortMessage] sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 20, 10000) lineBreakMode:UILineBreakModeWordWrap];
	// add in the padding for the applicationIdentifier and date
	size.height += 60;
	return size.height;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end

@implementation ESDebugTableViewCell
@synthesize applicationIdentifierLabel=_applicationIdentifierLabel;
@synthesize messageLabel=_messageLabel;
@synthesize dateLabel=_dateLabel;

#pragma mark - 

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self != nil)
	{
		_applicationIdentifierLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_applicationIdentifierLabel.font = [UIFont boldSystemFontOfSize:18];
		[self.contentView addSubview:_applicationIdentifierLabel];
		_messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_messageLabel.numberOfLines = 0;
		_messageLabel.font = [UIFont systemFontOfSize:17];
		_messageLabel.textColor = [UIColor darkGrayColor];
		[self.contentView addSubview:_messageLabel];
		_dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_dateLabel];
	}
	return self;
}

- (void)dealloc
{
	NO_ARC(
		   [_applicationIdentifierLabel release];
		   [_messageLabel release];
		   [_dateLabel release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.applicationIdentifierLabel.frame = CGRectMake(10, 10, self.contentView.frame.size.width - 20, 18);
	CGSize size = CGSizeMake(self.contentView.frame.size.width - 20, 18);
	if (self.messageLabel.text.length)
		size = [self.messageLabel.text sizeWithFont:[self.messageLabel font] constrainedToSize:CGSizeMake(size.width, 10000) lineBreakMode:UILineBreakModeWordWrap];
	self.messageLabel.frame = CGRectMake(10, 30, size.width, size.height);
	self.dateLabel.frame = CGRectMake(10, CGRectGetMaxY(self.messageLabel.frame), self.contentView.frame.size.width - 20, 18);
}

@end

@implementation ESDebugDetailViewController
@synthesize textView=_textView;

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Details";
	
	self.textView.frame = self.view.bounds;
	
	[self.view addSubview:self.textView];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.textView = nil;
}

#pragma mark -

- (UITextView *)textView
{
	if (_textView == nil)
	{
		_textView = [[UITextView alloc] initWithFrame:CGRectZero];
		_textView.editable = NO;
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _textView;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
