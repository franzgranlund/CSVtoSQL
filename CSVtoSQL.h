//
//  CSVtoSQL.h
//  CSVtoSQL
//
//  Created by Franz Granlund on 2010-07-13.
//  Copyright (c) 2010 Franz Granlund, All Rights Reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface CSVtoSQL : AMBundleAction 
{
	IBOutlet NSTextView *sqlTextView;
}

- (id) runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;
- (IBAction) insertSnippet: (id) sender;

@end
