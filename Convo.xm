#import "TextCounter.h"

%group Less10

%hook CKTranscriptRecipientsController

int oldIndex;
BOOL moreThan = NO;

int total = 0;
int sent = 0;
int received = 0;

-(void)viewDidLoad {
	%orig();

	FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
	[db open];

	total = sent = received = 0;

	for (NSString *guid in self.conversation.chat._guids) {
		// Get the chat index
		FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat WHERE guid='%@'", guid]];
		int chatIndex = -1;
		while ([s next]) {
			chatIndex = [s intForColumn:@"ROWID"];
			break;
		}

		if (chatIndex == -1) {
			HBLogError(@"Chat index not found");
			[db close];
			return;
		}

		s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deleted = [[NSMutableArray alloc] init];
		if ([s next]) {
			[deleted addObject:[s stringForColumn:@"guid"]];
		}


		// Get the messages
		s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat_message_join WHERE chat_id='%d'", chatIndex]];
		NSMutableArray *messages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[messages addObject:[s stringForColumn:@"message_id"]];
		}

		total += messages.count;

		// Get sent/received
		for (NSString *message in messages) {
			s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@'", message]];
			while ([s next]) {
				if (![deleted containsObject:[s stringForColumn:@"guid"]]) {
					if ([s boolForColumn:@"is_sent"]) {
						sent += 1;
					} else {
						received += 1;
					}
				}
			}
		}
	}

	[db close];

	[self.tableView reloadData];

}

-(NSInteger)tableView:(id)arg1 numberOfRowsInSection:(NSInteger)arg2 {
	if (arg2 == 0) {
		oldIndex = %orig();
		int newNum = oldIndex+4;
		if (oldIndex > 1) {
			moreThan = YES;
		} else {
			moreThan = NO;
		}
		return newNum;
	}
	return %orig();
}

%new -(void)segmentPressed:(UISegmentedControl*)sender {

	FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
	[db open];

	total = sent = received = 0;

	for (NSString *guid in self.conversation.chat._guids) {
		// Get the chat index
		FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat WHERE guid='%@'", guid]];
		int chatIndex = -1;
		while ([s next]) {
			chatIndex = [s intForColumn:@"ROWID"];
			break;
		}

		if (chatIndex == -1) {
			HBLogError(@"Chat index not found");
			[db close];
			return;
		}

		s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deleted = [[NSMutableArray alloc] init];
		if ([s next]) {
			[deleted addObject:[s stringForColumn:@"guid"]];
		}


		// Get the messages
		s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat_message_join WHERE chat_id='%d'", chatIndex]];
		NSMutableArray *messages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[messages addObject:[s stringForColumn:@"message_id"]];
		}

		int current = 0;

		// Get sent/received
		for (NSString *message in messages) {
			if (sender.selectedSegmentIndex == 1) {
				s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@' AND (date between '%d' AND '%d')", message, (int)round([[NSDate date] timeIntervalSinceReferenceDate])-2592000, (int)round([[NSDate date] timeIntervalSinceReferenceDate])]];
			} else {
				s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@'", message]];
			}
			while ([s next]) {
				if (![deleted containsObject:[s stringForColumn:@"guid"]]) {
					if ([s boolForColumn:@"is_sent"]) {
						sent += 1;
					} else {
						received += 1;
					}
					current += 1;
				}
			}
		}

		total += current;
	}

	[db close];

	[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldIndex+1 inSection:0],[NSIndexPath indexPathForRow:oldIndex+2 inSection:0],[NSIndexPath indexPathForRow:oldIndex+3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(id)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)arg2 {
	if (arg2.section == 0 && arg2.row == oldIndex+1) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"statsCell"];

	    if (cell == nil) {
	        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
	    }

		cell.textLabel.text = @"Total";
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", total];
		return cell;
	} elif (arg2.section == 0 && arg2.row == oldIndex+2) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"statsCell"];

	    if (cell == nil) {
	        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
	    }

		cell.textLabel.text = @"Sent";
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", sent];
		return cell;
	} elif (arg2.section == 0 && arg2.row == oldIndex+3) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"statsCell"];

	    if (cell == nil) {
	        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
	    }

		cell.textLabel.text = @"Received";
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", received];
		return cell;
	} elif (arg2.section == 0 && arg2.row == oldIndex) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bgCell"];

		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"bgCell"];
		}

		cell.backgroundColor = UIColorFromRGB(0xEAEAEA);

		for (UIView* v in cell.subviews) {
			if ([v isKindOfClass:[UISegmentedControl class]]) {
				[v removeFromSuperview];
			}
		}

		UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Overall", @"Monthly"]];
		segmentedControl.frame = CGRectMake(25, 10, cell.frame.size.width-50, cell.frame.size.height-20);
		[segmentedControl addTarget:self action:@selector(segmentPressed:) forControlEvents:UIControlEventValueChanged];
		segmentedControl.selectedSegmentIndex = 0;
		[cell addSubview:segmentedControl];
		[segmentedControl release];

		if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
			   [cell setSeparatorInset:UIEdgeInsetsZero];
		}

		// Explictly set your cell's layout margins
		if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
			[cell setLayoutMargins:UIEdgeInsetsZero];
		}

		// Prevent the cell from inheriting the Table View's margin settings
		if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
			[cell setPreservesSuperviewLayoutMargins:NO];
		}

		return cell;
	} elif (arg2.section == 0 && arg2.row == oldIndex-1) {
		UITableViewCell* cell = %orig;
		if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
	           [cell setSeparatorInset:UIEdgeInsetsZero];
	    }

	    // Explictly set your cell's layout margins
	    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
	        [cell setLayoutMargins:UIEdgeInsetsZero];
	    }

	    // Prevent the cell from inheriting the Table View's margin settings
	    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
	        [cell setPreservesSuperviewLayoutMargins:NO];
	    }
		return cell;
	}

	if ([%orig isKindOfClass:[%c(CKTranscriptAddRecipientCell) class]]) {
		HBLogInfo(@"%ld, %ld", (long)arg2.row, (long)arg2.section);
	}

	return %orig();
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	%orig();
	if (indexPath.section == 0 && indexPath.row >= oldIndex-1 && indexPath.row < oldIndex+3) {
	    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
	           [cell setSeparatorInset:UIEdgeInsetsZero];
	    }

	    // Explictly set your cell's layout margins
	    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
	        [cell setLayoutMargins:UIEdgeInsetsZero];
	    }

	    // Prevent the cell from inheriting the Table View's margin settings
	    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
	        [cell setPreservesSuperviewLayoutMargins:NO];
	    }

	}
}

-(double)tableView:(id)arg1 heightForRowAtIndexPath:(NSIndexPath*)arg2 {
	if (arg2.section == 0 && arg2.row == oldIndex) {
		return [self tableView:arg1 heightForHeaderInSection:(moreThan ? 2 : 1)];
	} elif (arg2.section == 0 && arg2.row >= oldIndex+1) {
		return %orig(arg1, [NSIndexPath indexPathForRow:0 inSection:2]);
	}
	return %orig();
}

%end

%end

%group Great10

%hook CKDetailsController

// int oldIndex;
// BOOL moreThan = NO;
//
// int total = 0;
// int sent = 0;
// int received = 0;

-(void)viewDidLoad {
	%orig();

	FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
	[db open];

	total = sent = received = 0;

	for (NSString *guid in self.conversation.chat._guids) {
		// Get the chat index
		FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat WHERE guid='%@'", guid]];
		int chatIndex = -1;
		while ([s next]) {
			chatIndex = [s intForColumn:@"ROWID"];
			break;
		}

		if (chatIndex == -1) {
			HBLogError(@"Chat index not found");
			[db close];
			return;
		}

		s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deleted = [[NSMutableArray alloc] init];
		if ([s next]) {
			[deleted addObject:[s stringForColumn:@"guid"]];
		}


		// Get the messages
		s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat_message_join WHERE chat_id='%d'", chatIndex]];
		NSMutableArray *messages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[messages addObject:[s stringForColumn:@"message_id"]];
		}

		total += messages.count;

		// Get sent/received
		for (NSString *message in messages) {
			s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@'", message]];
			while ([s next]) {
				if (![deleted containsObject:[s stringForColumn:@"guid"]]) {
					if ([s boolForColumn:@"is_sent"]) {
						sent += 1;
					} else {
						received += 1;
					}
				}
			}
		}
	}

	[db close];

	OSLog(@"DB finished");

	[self.tableView reloadData];

}

-(NSInteger)numberOfSectionsInTableView:(id)arg1 {
	OSLog(@"num of sections finished");
	return %orig()+1;
}

-(NSInteger)tableView:(id)arg1 numberOfRowsInSection:(NSInteger)arg2 {
	OSLog(@"num of rows in section '%ld' finished", (long)arg2);
	if (arg2 == 0) {
		return 1;
	}
	return %orig(arg1, arg2);
}

%new -(void)segmentPressed:(UISegmentedControl*)sender {

	FMDatabase *db = [FMDatabase databaseWithPath:@"/var/mobile/Library/SMS/sms.db"];
	[db open];

	total = sent = received = 0;

	for (NSString *guid in self.conversation.chat._guids) {
		// Get the chat index
		FMResultSet *s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat WHERE guid='%@'", guid]];
		int chatIndex = -1;
		while ([s next]) {
			chatIndex = [s intForColumn:@"ROWID"];
			break;
		}

		if (chatIndex == -1) {
			HBLogError(@"Chat index not found");
			[db close];
			return;
		}

		s = [db executeQuery:@"SELECT * FROM deleted_messages"];
		NSMutableArray *deleted = [[NSMutableArray alloc] init];
		if ([s next]) {
			[deleted addObject:[s stringForColumn:@"guid"]];
		}


		// Get the messages
		s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM chat_message_join WHERE chat_id='%d'", chatIndex]];
		NSMutableArray *messages = [[NSMutableArray alloc] init];
		while ([s next]) {
			[messages addObject:[s stringForColumn:@"message_id"]];
		}

		int current = 0;

		// Get sent/received
		for (NSString *message in messages) {
			if (sender.selectedSegmentIndex == 1) {
				s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@' AND (date between '%d' AND '%d')", message, (int)round([[NSDate date] timeIntervalSinceReferenceDate])-2592000, (int)round([[NSDate date] timeIntervalSinceReferenceDate])]];
			} else {
				s = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM message WHERE ROWID='%@'", message]];
			}
			while ([s next]) {
				if (![deleted containsObject:[s stringForColumn:@"guid"]]) {
					if ([s boolForColumn:@"is_sent"]) {
						sent += 1;
					} else {
						received += 1;
					}
					current += 1;
				}
			}
		}

		total += current;
	}

	[db close];

	// [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:oldIndex+1 inSection:0],[NSIndexPath indexPathForRow:oldIndex+2 inSection:0],[NSIndexPath indexPathForRow:oldIndex+3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(id)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)arg2 {
	OSLog(@"Cell for row %ld, %ld called", (long)arg2.row, (long)arg2.section);
	// return %orig();
	if (arg2.section != 0) {
		return %orig(tableView, [NSIndexPath indexPathForRow:arg2.row inSection:arg2.section-1]);
	}

// 	if (arg2.section == 0 && arg2.row == oldIndex+1) {
// 		CKTranscriptDetailsResizableCell *cell = [self locationSendCell];
// //resizable_cell
// 	    if (cell == nil) {
// 	        cell = [[%c(CKTranscriptDetailsResizableCell) alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
// 	    }
//
// 		cell.textLabel.text = @"Total";
// 		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", total];
// 		return cell;
// 	} elif (arg2.section == 0 && arg2.row == oldIndex+2) {
// 		CKTranscriptDetailsResizableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"statsCell"];
//
// 	    if (cell == nil) {
// 	        cell = [[%c(CKTranscriptDetailsResizableCell) alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
// 	    }
//
// 		cell.textLabel.text = @"Sent";
// 		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", sent];
// 		return cell;
// 	} elif (arg2.section == 0 && arg2.row == oldIndex+3) {
// 		CKTranscriptDetailsResizableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"statsCell"];
//
// 	    if (cell == nil) {
// 	        cell = [[%c(CKTranscriptDetailsResizableCell) alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"statsCell"];
// 	    }
//
// 		cell.textLabel.text = @"Received";
// 		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", received];
// 		return cell;
// 	} elif (arg2.section == 0 && arg2.row == oldIndex) {
// 		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bgCell"];
//
// 		if (cell == nil) {
// 			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"bgCell"];
// 		}
//
// 		cell.backgroundColor = UIColorFromRGB(0xEAEAEA);
//
// 		for (UIView* v in cell.subviews) {
// 			if ([v isKindOfClass:[UISegmentedControl class]]) {
// 				[v removeFromSuperview];
// 			}
// 		}
//
// 		UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Overall", @"Monthly"]];
// 		segmentedControl.frame = CGRectMake(25, 10, cell.frame.size.width-50, cell.frame.size.height-20);
// 		[segmentedControl addTarget:self action:@selector(segmentPressed:) forControlEvents:UIControlEventValueChanged];
// 		segmentedControl.selectedSegmentIndex = 0;
// 		[cell addSubview:segmentedControl];
// 		[segmentedControl release];
//
// 		if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
// 			   [cell setSeparatorInset:UIEdgeInsetsZero];
// 		}
//
// 		// Explictly set your cell's layout margins
// 		if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
// 			[cell setLayoutMargins:UIEdgeInsetsZero];
// 		}
//
// 		// Prevent the cell from inheriting the Table View's margin settings
// 		if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
// 			[cell setPreservesSuperviewLayoutMargins:NO];
// 		}
//
// 		return cell;
// 	} elif (arg2.section == 0 && arg2.row == oldIndex-1) {
// 		UITableViewCell* cell = %orig;
// 		if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
// 	           [cell setSeparatorInset:UIEdgeInsetsZero];
// 	    }
//
// 	    // Explictly set your cell's layout margins
// 	    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
// 	        [cell setLayoutMargins:UIEdgeInsetsZero];
// 	    }
//
// 	    // Prevent the cell from inheriting the Table View's margin settings
// 	    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
// 	        [cell setPreservesSuperviewLayoutMargins:NO];
// 	    }
// 		return cell;
// 	}
//
// 	if ([%orig isKindOfClass:[%c(CKTranscriptAddRecipientCell) class]]) {
// 		HBLogInfo(@"%ld, %ld", (long)arg2.row, (long)arg2.section);
// 	}

	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"bgCell"];
}

-(void)tableView:(UITableView *)arg1 willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)arg2
{
	// %orig(); return;
	if (arg2.section == 0) {
		return;
	}
	%orig(arg1, cell, [NSIndexPath indexPathForRow:arg2.row inSection:arg2.section-1]);
	// if (indexPath.section == 0 && indexPath.row >= oldIndex-1 && indexPath.row < oldIndex+3) {
	//     if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
	//            [cell setSeparatorInset:UIEdgeInsetsZero];
	//     }
	//
	//     // Explictly set your cell's layout margins
	//     if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
	//         [cell setLayoutMargins:UIEdgeInsetsZero];
	//     }
	//
	//     // Prevent the cell from inheriting the Table View's margin settings
	//     if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
	//         [cell setPreservesSuperviewLayoutMargins:NO];
	//     }
	//
	// }
}

-(double)tableView:(id)arg1 heightForRowAtIndexPath:(NSIndexPath*)arg2 {
	// if (arg2.section == 0 && arg2.row == oldIndex) {
	// 	return [self tableView:arg1 heightForHeaderInSection:(moreThan ? 2 : 1)];
	// } elif (arg2.section == 0 && arg2.row >= oldIndex+1) {
	// 	return %orig(arg1, [NSIndexPath indexPathForRow:0 inSection:2]);
	// }
	// return %orig();
	OSLog(@"height for %@", arg2);
	if (arg2.section == 0) {
		return 20;
	}
	return %orig(arg1, [NSIndexPath indexPathForRow:arg2.row inSection:arg2.section-1]);
}

%end

%end

%ctor {
	NSOperatingSystemVersion os = [NSProcessInfo processInfo].operatingSystemVersion;
    if (os.majorVersion == 10) {
        %init(Great10);
    } else {
        %init(Less10);
    }
	%init();
}
