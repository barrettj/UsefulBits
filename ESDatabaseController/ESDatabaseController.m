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
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ESDatabase" withExtension:@"momd"];
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

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Subclasses
- (void)configurePersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[self storeName]];
	NSError *error = nil;
	if (![persistentStoreCoordinator addPersistentStoreWithType:[self storeType] configuration:nil URL:storeURL options:nil error:&error])
		[NSException raise:NSGenericException format:@"Unresolved error %@, %@", error, [error userInfo]];
}

- (void)handleSaveError:(NSManagedObjectContext *)managedObjectContext error:(NSError *)error
{
	[NSException raise:NSGenericException format:@"Unresolved error %@, %@", error, [error userInfo]];
}

- (NSString *)storeName
{
	NSAssert(NO, @"Implement storeName in subclass");
	return nil;
}

- (NSString * const)storeType
{
	return NSSQLiteStoreType;
}

@end
