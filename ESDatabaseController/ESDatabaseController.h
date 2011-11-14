//
//  ESDatabaseController.h
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

#import <Foundation/Foundation.h>

/**
 * Easy to subclass controller for a basic core data stack
 */

@interface ESDatabaseController : NSObject

/**
 * MOC created and safe for use on applications main thread
 * 
 * Lazily initialized
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *mainThreadManagedObjectContext;
/**
 * Lazily initialized object model
 */
@property (readonly, strong) NSManagedObjectModel *managedObjectModel;
/**
 * Lazily initialized store coordinator
 * 
 * Subclasses use storeName to initialize store from bundle and configurePersistentStoreCoordinator: to configure it (migrations, error handling, etc)
 */
@property (readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
/**
 * Configures whether store at [self storeURL] is marked to not be backed up to iCloud
 */
@property (assign, nonatomic) BOOL doNotBackupStore;
/**
 * ESDataBaseController static instance
 * 
 * @return static controller intance (Subclasses will return an instance of the subclass as static instance)
 */
+ (id)sharedDatabase;
/**
 * Perform save against mainThreadManagedObjectContext
 */
- (void)saveMainThreadContext;
/**
 * Perform save against given MOC
 * 
 * @param managedObjectContext MOC to perform save against
 */
- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;
/**
 * Newly initialized managedObjectContext configured with persistentStoreCoordinator
 */
- (NSManagedObjectContext *)newManagedObjectContext;
/**
 * Convenience method for preflighting compatibility in the event of migration
 */
- (BOOL)checkStoreCompatibilityForStoreAtURL:(NSURL *)storeURL 
									withType:(NSString * const)storeType 
						   withConfiguration:(NSString *)configuration 
					  withManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
									   error:(NSError **)error;
/**
 * Convenience method for preflighting compatibility of current store in the event of migration
 */
- (BOOL)checkCurrentStoreCompatibility:(NSError **)error;

@end

@interface ESDatabaseController (Subclasses)

/**
 * 
 */
- (void)configurePersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
/**
 * 
 */
- (void)handleSaveError:(NSManagedObjectContext *)managedObjectContext error:(NSError *)error;
/**
 * 
 */
- (NSURL *)storeURL;
/**
 * 
 */
- (NSURL *)modelURL;
/**
 * 
 */
- (NSString * const)storeType;
/**
 * 
 */
- (NSURL *)databaseDirectory;

@end
