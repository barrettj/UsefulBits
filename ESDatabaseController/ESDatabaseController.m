//
//  ESDatabaseController.m
//
//  Created by Doug Russell
//  Copyright (c) 2011 Doug Russell. All rights reserved.
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

#if !__has_feature(objc_arc)
#error THIS FILE REQUIRES ARC
#endif

#import "ESDatabaseController.h"
#import <libkern/OSAtomic.h>
#include <sys/xattr.h>

@interface ESDatabaseController ()
@end

@implementation ESDatabaseController
{
	OSSpinLock _momSpinlock;
	OSSpinLock _pscSpinlock;
}

@synthesize mainThreadManagedObjectContext = _mainThreadManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Setup/Cleanup
+ (id)sharedDatabase
{
	static id sharedDatabase = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDatabase = [[self class] new];
	});
	return sharedDatabase;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		_momSpinlock = OS_SPINLOCK_INIT;
		_pscSpinlock = OS_SPINLOCK_INIT;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NSManagedObjectContextObjectsDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications
- (void)NSManagedObjectContextObjectsDidChangeNotification:(NSNotification *)notification
{
	if ([NSThread isMainThread])
		[self.mainThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
	else
		[self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
}

#pragma mark - Public
- (void)saveMainThreadContext
{
	[self saveContext:self.mainThreadManagedObjectContext];
}

- (void)saveContext:(NSManagedObjectContext *)managedObjectContext
{
	NSError *error = nil;
	if (managedObjectContext != nil)
	{
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
		{
			[self handleSaveError:managedObjectContext error:error];
		} 
	}
}

- (NSManagedObjectContext *)mainThreadManagedObjectContext
{
	NSAssert([NSThread isMainThread], @"Accessed main thread MOC from invalid thread");
	if (_mainThreadManagedObjectContext != nil)
		return _mainThreadManagedObjectContext;
	_mainThreadManagedObjectContext = [self newManagedObjectContext];
	return _mainThreadManagedObjectContext;
}

- (NSManagedObjectContext *)newManagedObjectContext
{
	NSManagedObjectContext *managedObjectContext = nil;
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
	OSSpinLockLock(&_momSpinlock);
	if (_managedObjectModel == nil)
	{
		NSURL *modelURL = [self modelURL];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	}
	OSSpinLockUnlock(&_momSpinlock);
	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	OSSpinLockLock(&_pscSpinlock);
	if (_persistentStoreCoordinator == nil)
	{
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		[self configurePersistentStoreCoordinator:_persistentStoreCoordinator];
	}
	OSSpinLockUnlock(&_pscSpinlock);
	return _persistentStoreCoordinator;
}

- (NSURL *)databaseDirectory
{
	// Get director url (<application>/Library/PrivateDocuments )
	NSURL *directoryURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory 
																   inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"PrivateDocuments"];
	// Make sure the directory exists
	BOOL isDir;
	if (!([[NSFileManager defaultManager] fileExistsAtPath:[directoryURL path] isDirectory:&isDir] && isDir))
	{
		[[NSFileManager defaultManager] createDirectoryAtURL:directoryURL 
								 withIntermediateDirectories:NO
												  attributes:nil 
													   error:nil];
	}
	return directoryURL;
}

- (BOOL)checkStoreCompatibilityForStoreAtURL:(NSURL *)storeURL 
									withType:(NSString * const)storeType 
						   withConfiguration:(NSString *)configuration 
					  withManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
									   error:(NSError **)error
{
	// Sanity Check
	if ((storeURL == nil) || 
		(storeType == nil) ||
		(managedObjectModel == nil))
	{
		if (error != nil)
			*error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]; // Make a real error
		return NO;
	}
	
	// If store doesn't exist, compatibility isn't an issue
	if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]])
		return YES;
	
	NSDictionary *metadata;
	
	metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:storeType 
																		  URL:storeURL 
																		error:error];
	
	if (metadata)
		return [managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:metadata];
	return NO;
}

- (BOOL)checkCurrentStoreCompatibility:(NSError **)error
{
	return [self checkStoreCompatibilityForStoreAtURL:[self storeURL] 
											 withType:[self storeType] 
									withConfiguration:nil 
							   withManagedObjectModel:[self managedObjectModel]
												error:error];
}

- (BOOL)doNotBackupStore
{
	const char* filePath;
	const char* attrName;
	u_int8_t attrValue;
	int result;
	
	filePath = [[[self storeURL] path] fileSystemRepresentation];
	attrName = "com.apple.MobileBackup";
	result = getxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
	if ((result > 0) && (attrValue == 0))
		return YES;
	return NO;
}

- (void)setDoNotBackupStore:(BOOL)backup
{
	const char* filePath;
	const char* attrName;
	u_int8_t attrValue;
	
	filePath = [[[self storeURL] path] fileSystemRepresentation];
	attrName = "com.apple.MobileBackup";
	if (backup)
		attrValue = 0;
	else
		attrValue = 1;
	setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
}

#pragma mark - Subclasses
- (void)configurePersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	NSURL *storeURL = [self storeURL];
	NSError *error = nil;
	if (![persistentStoreCoordinator addPersistentStoreWithType:[self storeType] configuration:nil URL:storeURL options:nil error:&error])
		[NSException raise:NSGenericException format:@"Unresolved error %@, %@", error, [error userInfo]];
}

- (void)handleSaveError:(NSManagedObjectContext *)managedObjectContext error:(NSError *)error
{
	[NSException raise:NSGenericException format:@"Unresolved error %@, %@", error, [error userInfo]];
}

- (NSURL *)storeURL
{
	NSAssert(NO, @"Implement storeURL in subclass");
	//return [[self databaseDirectory] URLByAppendingPathComponent:[self storeName]];
	return nil;
}

- (NSURL *)modelURL
{
	NSAssert(NO, @"Implement modelURL in subclass");
	//return [[NSBundle mainBundle] URLForResource:@"ESDatabase" withExtension:@"momd"];
	return nil;
}

- (NSString * const)storeType
{
	return NSSQLiteStoreType;
}

@end
