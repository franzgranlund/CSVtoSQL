//
//  CSVtoSQL.m
//  CSVtoSQL
//
//  Created by Franz Granlund on 2010-07-13.
//  Copyright (c) 2010 Franz Granlund, All Rights Reserved.
//

#import "CSVtoSQL.h"

@implementation CSVtoSQL

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSMutableArray *returnArray = [[NSMutableArray alloc] init];
	NSString *fileName;
	NSEnumerator *enumerate = [input objectEnumerator];
	NSError *error;

	NSStringEncoding enc = NSUTF8StringEncoding;
	
	if([[[self parameters] objectForKey: @"encodingKey"] integerValue] == 0) {
		enc = NSUTF8StringEncoding;
	}
	else if([[[self parameters] objectForKey: @"encodingKey"] integerValue] == 1) {
		enc = NSISOLatin1StringEncoding;
	}
	
	NSString *delimiter = [[self parameters] objectForKey: @"delimiterField"];
	NSString *sql = [[self parameters] objectForKey: @"sqlField"];
	
	while (fileName = [enumerate nextObject]) {
		// Read the content of the file into a string
		NSString *content = [NSString stringWithContentsOfFile: fileName encoding: enc error: &error];		

		if (content == nil) {
			NSArray *objsArray = [NSArray arrayWithObjects: [NSNumber numberWithInt: errOSAGeneralError], [NSString stringWithFormat: @"Error reading file at %@ - %@", fileName, [error localizedFailureReason]], nil];
			NSArray *keysArray = [NSArray arrayWithObjects: NSAppleScriptErrorNumber, NSAppleScriptErrorMessage, nil];
			*errorInfo = [NSDictionary dictionaryWithObjects:objsArray forKeys:keysArray];
			return nil;
		}
		
		// Split the file-content into rows.
		NSArray *rows = [content componentsSeparatedByString: @"\n"];
		NSEnumerator *rowsEnum = [rows objectEnumerator];
		
		// Skip the first row if "First Row is Header" is checked.
		if ([[[self parameters] objectForKey: @"firstRowIsHeader"] integerValue] == 1) {
			[rowsEnum nextObject];
		}
		
		NSString *row;
		while (row = [rowsEnum nextObject]) {
			// Skip blank rows
			if ([row length] <= 1) {
				continue;
			}
			
			// Create mutable strings so we can use the replaceOccurrencesOfString-method.
			NSMutableString *modifiedSQL = [NSMutableString stringWithString: sql];
			NSMutableString *mutableRow = [NSMutableString stringWithString: row];

			// Escape special characters if the user wants to.
			if ([[[self parameters] objectForKey: @"escapeSpecialCharacters"] integerValue] == 1) {
				[mutableRow replaceOccurrencesOfString: @"\\" withString: @"\\\\" options: NSLiteralSearch range: NSMakeRange(0, [mutableRow length])];
				[mutableRow replaceOccurrencesOfString: @"\'" withString: @"\\\'" options: NSLiteralSearch range: NSMakeRange(0, [mutableRow length])];
				[mutableRow replaceOccurrencesOfString: @"\"" withString: @"\\\"" options: NSLiteralSearch range: NSMakeRange(0, [mutableRow length])];
			}
			
			// Split the row into fields
			NSArray *rowFields = [mutableRow componentsSeparatedByString: delimiter];
			NSEnumerator *rowFieldsEnum = [rowFields objectEnumerator];
			NSString *field;
			int columnIndex = 0;
			
			while (field = [rowFieldsEnum nextObject]) {
				NSString *tmpField;
				// If user checked Quote Fields
				if ([[[self parameters] objectForKey: @"quoteFields"] integerValue] == 1) {
					tmpField = [NSString stringWithFormat: @"'%@'", field];
				} else {
					tmpField = field;
				}

				NSString *replaceString = [NSString stringWithFormat: @"{$%d}", columnIndex++];
				[modifiedSQL replaceOccurrencesOfString: replaceString withString: tmpField options: NSLiteralSearch range: NSMakeRange(0, [modifiedSQL length])];
			}
			
			// Add our fresh SQL-row to the return-array.
			[returnArray addObject: modifiedSQL];
		}
	}

	return returnArray;
}

- (IBAction) insertSnippet: (id) sender {
	NSString *snippetString;
	
	if ([[[self parameters] objectForKey: @"snippetKey"] integerValue] == 0) {
		snippetString = [NSString stringWithString: @"INSERT INTO tableName (column0, column1, column2, column3) VALUES ({$0}, {$1}, {$2}, {$3})"];
	}

	if ([[[self parameters] objectForKey: @"snippetKey"] integerValue] == 1) {
		snippetString = [NSString stringWithString: @"UPDATE tableName SET column1={$1}, column2={$2}, column3={$3} WHERE column0={$0}"];
	}

	if ([[[self parameters] objectForKey: @"snippetKey"] integerValue] == 2) {
		snippetString = [NSString stringWithString: @"DELETE FROM tableName WHERE column1={$0} AND column2={$1}"];
	}
	
	// Append to the end of the textview
	[[[sqlTextView textStorage] mutableString] appendString: snippetString];
}

@end
