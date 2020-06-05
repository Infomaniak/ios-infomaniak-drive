//
//  OCnetworking.h
//  Nextcloud
//
//  Created by Marino Faggiana on 10/05/15.
//  Copyright (c) 2015 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import "OCCommunication.h"
@import AFNetworking;


@interface OCNetworking : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (OCNetworking *)sharedManager;

@property BOOL checkRemoteUserInProgress;

#pragma mark ===== OCCommunication =====

- (OCCommunication *)sharedOCCommunication;

#pragma mark ===== Share =====

- (void)readShareWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)readShareWithAccount:(NSString *)account path:(NSString *)path completion:(void (^)(NSString *account, NSArray *items, NSString *message, NSInteger errorCode))completion;
- (void)shareWithAccount:(NSString *)account fileName:(NSString *)fileName password:(NSString *)password permission:(NSInteger)permission hideDownload:(BOOL)hideDownload completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)shareUserGroupWithAccount:(NSString *)account userOrGroup:(NSString *)userOrGroup fileName:(NSString *)fileName permission:(NSInteger)permission shareeType:(NSInteger)shareeType completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)shareUpdateAccount:(NSString *)account shareID:(NSInteger)shareID password:(NSString *)password note:(NSString *)note permission:(NSInteger)permission expirationTime:(NSString *)expirationTime hideDownload:(BOOL)hideDownload completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)unshareAccount:(NSString *)account shareID:(NSInteger)shareID completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)getUserGroupWithAccount:(NSString *)account searchString:(NSString *)searchString completion:(void (^)(NSString *account, NSArray *item, NSString *message, NSInteger errorCode))completion;

#pragma mark ===== Third Parts =====

- (void)getHCUserProfileWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl completion:(void (^)(NSString *account, OCUserProfile *userProfile, NSString *message, NSInteger errorCode))completion;
- (void)putHCUserProfileWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl address:(NSString *)address businesssize:(NSString *)businesssize businesstype:(NSString *)businesstype city:(NSString *)city company:(NSString *)company  country:(NSString *)country displayname:(NSString *)displayname email:(NSString *)email phone:(NSString *)phone role_:(NSString *)role_ twitter:(NSString *)twitter website:(NSString *)website zip:(NSString *)zip completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion;
- (void)getHCFeaturesWithAccount:(NSString *)account serverUrl:(NSString *)serverUrl completion:(void (^)(NSString *account, HCFeatures *features, NSString *message, NSInteger errorCode))completion;

@end

@interface OCURLSessionManager : AFURLSessionManager

@end

