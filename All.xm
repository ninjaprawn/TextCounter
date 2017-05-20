#import "TextCounter.h"

BOOL showedAlert() {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"com.ninjaprawn.textcounter/firstTimeAlert"]) {
		return YES;
	}
	return NO;
}

void setShowedAlert() {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"com.ninjaprawn.textcounter/firstTimeAlert"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

%hook CKConversationListController

-(void)viewDidLoad {
	%orig();
	if (!showedAlert()) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TextCounter" message:@"To view your overall stats, tap the title (Messages). Note that 'O' stands for overall and 'M' stands for monthly. The format is:\n'[total] | [sent] | [received]'\nTo view your convo stats, press details in a convo." preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
		[alertController addAction:ok];

		[self presentViewController:alertController animated:YES completion:nil];
		setShowedAlert();
	}
}

-(void)updateNavigationItems {
	%orig();
	UINavigationItemView* itemView = nil;
	for (id v in ((UINavigationController*)self.parentViewController).navigationBar.subviews) {
		if ([v isKindOfClass:[%c(UINavigationItemView) class]]) { // Less than iOS 10
			itemView = v;
			break;
		} elif (![v isKindOfClass:[%c(_UIBarBackground) class]]) { // iOS 10+
			UIView *unknown = (UIView*)v;
			// unknown.backgroundColor = [UIColor greenColor];
			for (id coolView in unknown.subviews) {
				if ([coolView isKindOfClass:[%c(UINavigationItemView) class]]) { // Less than iOS 10
					itemView = coolView;
					break;
				}
			}
		}
	}

	OSLog(@"itemView: %@", itemView);

	if (itemView && !itemView.gestureRecognizers){
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed:)];
		tapGesture.numberOfTapsRequired=1;
		[itemView setUserInteractionEnabled:YES];
		[itemView addGestureRecognizer:tapGesture];
		[tapGesture release];
	} elif (!itemView) {
		abort();
	}

}

int count = 1;
%new -(void)tapPressed:(UITapGestureRecognizer*)sender {
	if (count == 1) {
		FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
		[db open];

		FMResultSet *s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deletedMessages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[deletedMessages addObject:[s stringForColumn:@"guid"]];
		}

		// Get the chat index
		s = [db executeQuery:@"SELECT * FROM message"];
		int total = 0;
		int sent = 0;
		int received = 0;
		while ([s next]) {
			if (![deletedMessages containsObject:[s stringForColumn:@"guid"]]) {
				if ([s boolForColumn:@"is_sent"]) {
					sent += 1;
				} else {
					received += 1;
				}
				total += 1;
			}
		}

		[db close];

		self.title = [NSString stringWithFormat:@"O: %d | %d | %d", total, sent, received];
		count = 2;
	} else if (count == 2) {
		FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
		[db open];

		FMResultSet *s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deletedMessages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[deletedMessages addObject:[s stringForColumn:@"guid"]];
		}

		// Get the chat index
		s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE date between '%d' AND '%d'", (int)round([[NSDate date] timeIntervalSinceReferenceDate])-2592000, (int)round([[NSDate date] timeIntervalSinceReferenceDate])]];
		int total = 0;
		int sent = 0;
		int received = 0;
		while ([s next]) {
			if (![deletedMessages containsObject:[s stringForColumn:@"guid"]]) {
				if ([s boolForColumn:@"is_sent"]) {
					sent += 1;
				} else {
					received += 1;
				}
				total += 1;
			}
		}

		[db close];

		self.title = [NSString stringWithFormat:@"M: %d | %d | %d", total, sent, received];
		count = 0;
	} else {
		self.title = @"Messages";
		count = 1;
	}
}

%end
