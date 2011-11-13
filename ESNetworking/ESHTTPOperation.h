#import "ESRunLoopOperation.h"
#import "ESNetworkError.h"
#import "NSMutableURLRequest+ESNetworking.h"

// Shared concurrent dispatch queue for work block processing
DISPATCH_EXPORT DISPATCH_WARN_RESULT 
dispatch_queue_t 
dispatch_get_processing_queue(void);

@class ESHTTPOperation;
typedef id<NSObject> (^ESHTTPOperationWorkBlock)(ESHTTPOperation *op, NSError **error);
typedef void (^ESHTTPOperationCompletionBlock)(ESHTTPOperation *op);
typedef void (^ESHTTPOperationUploadBlock)(NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite);
typedef void (^ESHTTPOperationDownloadBlock)(NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead);

/**
 `ESHTTPOperation` is an `NSOperation` that wraps an NSURLConnection that is executed asynchronously on a persistent network thread.
 
 @see NSOperation
 @see ESRunLoopOperation
 */

@interface ESHTTPOperation : ESRunLoopOperation

///--------------------------
/// @name Creating Operations
///--------------------------

/**
 Creates and returns an `ESHTTPOperation` object and sets the specified work and completion callbacks.
 
	typedef id<NSObject> (^ESHTTPOperationWorkBlock)(ESHTTPOperation *op, NSError **error);
 
	typedef void (^ESHTTPOperationCompletionBlock)(ESHTTPOperation *op);
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param work ESHTTPOperationWorkBlock that will be dispatched on shared processing queue
 @param completion ESHTTPOperationCompletionBlock that will be dispatched on main queue
 
 @return A new HTTP request operation
 */
+ (id)newHTTPOperationWithRequest:(NSURLRequest *)request work:(ESHTTPOperationWorkBlock)work completion:(ESHTTPOperationCompletionBlock)completion;

/**
 Creates and returns an `ESHTTPOperation` object and sets the specified work and completion callbacks.
 
	typedef id<NSObject> (^ESHTTPOperationWorkBlock)(ESHTTPOperation *op, NSError **error);
 
	typedef void (^ESHTTPOperationCompletionBlock)(ESHTTPOperation *op);
 
 @param urlRequest The request object to be loaded asynchronously during execution of the operation
 @param work ESHTTPOperationWorkBlock that will be dispatched on shared processing queue
 @param completion ESHTTPOperationCompletionBlock that will be dispatched on main queue
 
 @return An initialized HTTP request operation
 */
- (id)initWithRequest:(NSURLRequest *)request work:(ESHTTPOperationWorkBlock)work completion:(ESHTTPOperationCompletionBlock)completion; // designated initializer

///-------------------------
/// @name Configured at init
///-------------------------

/**
 * NSURLRequest used by NSURLConnection. Request is copied and cannot be modified after init.
 * 
 * @see URL
 */
@property (copy, readonly) NSURLRequest *request;
/**
 * URL associated with initial NSURLRequest
 *
 * @see request
 */
@property (copy, readonly) NSURL *URL;
/**
 Block that accepts the operation after it's finished it's network processing and returns an id that's been processed, usually parsed
 
 This block is executed on a concurrent dispatch queue reserved for CPU bound processing
 
 Passing nil causes the work block step to be skipped
 
	typedef id<NSObject> (^ESHTTPOperationWorkBlock)(ESHTTPOperation *op, NSError **error);
 */
@property (copy, readonly) ESHTTPOperationWorkBlock work;
/**
 Block that accepts completed operation and is dispatched on main queue
 
 Passing nil is acceptable
 
	typedef void (^ESHTTPOperationCompletionBlock)(ESHTTPOperation *op);
 */
@property (copy, readonly) ESHTTPOperationCompletionBlock completion;
@property (assign, readonly) NSInteger operationID;

///-----------------------------------------
/// @name Configure before queuing operation
///-----------------------------------------

// runLoopThread and runLoopModes inherited from ESRunLoopOperation
/**
 * Acceptable status codes returned by NSHTTPURLResponse
 * 
 * http://www.ietf.org/rfc/rfc2616.txt
 * 
 * Default is nil, implying 200..299
 * 
 * @see cancelOnStatusCodeError
 */
@property (copy, readwrite) NSIndexSet *acceptableStatusCodes;
/**
 Returns an `NSIndexSet` object containing the ranges of acceptable HTTP status codes (http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)
 
 By default, this is the range 200 to 299, inclusive.
 */
+ (NSIndexSet *)defaultAcceptableStatusCodes;
/**
 * Acceptable content types
 * 
 * http://www.ietf.org/rfc/rfc2616.txt
 * 
 * Default is nil, implying any content type is acceptable
 * 
 * @see cancelOnContentTypeError
 */
@property (copy, readwrite) NSSet *acceptableContentTypes;
/**
 Returns an `NSSet` object containing the acceptable HTTP content type (http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.17)
 
 By default, this is nil, implying any content type is acceptable
 */
+ (NSSet *)defaultAcceptableContentTypes;
/**
 * Determines is NSURLConnection will cancel on -connection:didReceiveResponse: is responses status code is not in acceptableStatusCodes
 * 
 * Default is NO
 * 
 * @see acceptableStatusCodes
 */
@property (assign, readwrite) BOOL cancelOnStatusCodeError;
/**
 * Determines is NSURLConnection will cancel on -connection:didReceiveResponse: is responses mime type is not in acceptableContentTypes
 * 
 * Default is NO
 * 
 * @see acceptableContentTypes
 */
@property (assign, readwrite) BOOL cancelOnContentTypeError; // default is NO

///--------------------------------------
/// @name Configure before receiving data
///--------------------------------------

// Typically you would change these in -connection:didReceiveResponse:, but 
// it is possible to change them up to the point where -connection:didReceiveData: 
// is called for the first time (that is, you could override -connection:didReceiveData: 
// and change these before calling super).

/**
 * NSOutputStream used to write out data returned by connection. Useful for downloading large files directly to disk, etc.
 * 
 * Defaults to nil, which puts response into responseBody
 * 
 * @warning If you set a response stream, ESHTTPOperation calls the response 
 * stream synchronously.  This is fine for file and memory streams, but it would 
 * not work well for other types of streams (like a bound pair).
 */
@property (strong, readwrite) NSOutputStream *outputStream;
/**
 * Used for hinting capacity on data accumulator used by connection.
 *
 * This value is ignored if outputStream is set
 * 
 * Default is 1MB.
 */
@property (assign, readwrite) NSUInteger defaultResponseSize;
/**
 * Used by connection to prevent unbounded memory consumption during download.
 * 
 * This value is ignored if outputStream is set
 * 
 * Default is 4MB.
 */
@property (assign, readwrite) NSUInteger maximumResponseSize;

///--------------------------
/// @name Response validation
///--------------------------

/**
 * Validates that status code returned in lastResponse is contained in acceptableStatusCodes
 */
@property (assign, readonly, getter=isStatusCodeAcceptable) BOOL statusCodeAcceptable;
/**
 * Validates that MIMEType returned in lastResponse is contained in acceptableContentTypes
 */
@property (assign, readonly, getter=isContentTypeAcceptable) BOOL contentTypeAcceptable;

///--------------------------------------
/// @name Response
///--------------------------------------

// error property inherited from ESRunLoopOperation
/**
 * 
 */
@property (copy, readonly) NSURLRequest *lastRequest;
/**
 * 
 */
@property (copy, readonly) NSHTTPURLResponse *lastResponse;
/**
 * 
 */
@property (strong, readonly) NSData *responseBody;
/**
 * 
 */
@property (strong, readonly) id processedResponse;

///---------------
/// @name Progress
///---------------

/**
 * 
 */
- (void)setUploadProgressBlock:(ESHTTPOperationUploadBlock)uploadProgress;
/**
 * 
 */
- (void)setDownloadProgressBlock:(ESHTTPOperationDownloadBlock)downloadProgress;

@end

@interface ESHTTPOperation () // For Subclasses

// Read/write versions of public properties

@property (copy, readwrite) NSURLRequest* lastRequest;
@property (copy, readwrite) NSHTTPURLResponse* lastResponse;

// Internal properties

@property (strong, readwrite) NSURLConnection* connection;
@property (assign, readwrite) BOOL firstData;
@property (strong, readwrite) NSMutableData* dataAccumulator;

@end

/*
 File:       QHTTPOperation.h
 
 Contains:   An NSOperation that runs an HTTP request.
 
 Written by: DTS
 
 Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.
 
 Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of
 these terms.  If you do not agree with these terms, please do
 not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following
 terms, and subject to these terms, Apple grants you a personal,
 non-exclusive license, under Apple's copyrights in this
 original Apple software (the "Apple Software"), to use,
 reproduce, modify and redistribute the Apple Software, with or
 without modifications, in source and/or binary forms; provided
 that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the
 following text and disclaimers in all such redistributions of
 the Apple Software. Neither the name, trademarks, service marks
 or logos of Apple Inc. may be used to endorse or promote
 products derived from the Apple Software without specific prior
 written permission from Apple.  Except as expressly stated in
 this notice, no other rights or licenses, express or implied,
 are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or
 by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis. 
 APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
 WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
 THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
 INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
 OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
 OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
 OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.
 
 */

//
//  ESHTTPOperation.h
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