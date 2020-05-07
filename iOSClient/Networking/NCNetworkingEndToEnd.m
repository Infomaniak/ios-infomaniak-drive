//
//  NCNetworkingEndToEnd.m
//  Nextcloud
//
//  Created by Marino Faggiana on 29/10/17.
//  Copyright (c) 2017 Marino Faggiana. All rights reserved.
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

#import "NCNetworkingEndToEnd.h"
#import "OCNetworking.h"
#import "CCUtility.h"
#import "NCBridgeSwift.h"


/*********************************************************************************
 
 Netwok call synchronous mode, use this only from :
 
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 });
 
*********************************************************************************/

@implementation NCNetworkingEndToEnd

+ (NCNetworkingEndToEnd *)sharedManager {
    static NCNetworkingEndToEnd *sharedManager;
    @synchronized(self)
    {
        if (!sharedManager) {
            sharedManager = [NCNetworkingEndToEnd new];
        }
        return sharedManager;
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== End-to-End Encryption NETWORKING =====
#pragma --------------------------------------------------------------------------------------------

- (void)getEndToEndPublicKeyWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *publicKey, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, nil, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication getEndToEndPublicKeys:[tableAccount.url stringByAppendingString:@"/"] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *publicKey, NSString *redirectedServer) {
        
        completion(account, publicKey, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, nil, message, errorCode);
    }];
}

- (void)getEndToEndPrivateKeyCipherWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *privateKeyChiper, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, nil, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;
    
    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication getEndToEndPrivateKeyCipher:[tableAccount.url stringByAppendingString:@"/"] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *privateKeyChiper, NSString *redirectedServer) {
        
        completion(account, privateKeyChiper, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, nil, message, errorCode);
    }];
}

- (void)signEndToEndPublicKeyWithAccount:(NSString *)account publicKey:(NSString *)publicKey completion:(void (^)(NSString *account, NSString *publicKey, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, nil, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication signEndToEndPublicKey:[tableAccount.url stringByAppendingString:@"/"] publicKey:[CCUtility URLEncodeStringFromString:publicKey] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *publicKey, NSString *redirectedServer) {
        
        completion(account, publicKey, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, nil, message, errorCode);
    }];
}

- (void)storeEndToEndPrivateKeyCipherWithAccount:(NSString *)account privateKeyString:(NSString *)privateKeyString privateKeyChiper:(NSString *)privateKeyChiper completion:(void (^)(NSString *account, NSString *privateKeyString, NSString *privateKey, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, nil, nil, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication storeEndToEndPrivateKeyCipher:[tableAccount.url stringByAppendingString:@"/"] privateKeyChiper:[CCUtility URLEncodeStringFromString:privateKeyChiper] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *privateKey, NSString *redirectedServer) {
        
        completion(account, privateKeyString, privateKeyChiper, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, nil, nil, message, errorCode);
    }];
}

- (void)deleteEndToEndPublicKeyWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication deleteEndToEndPublicKey:[tableAccount.url stringByAppendingString:@"/"] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        completion(account, nil ,0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, message, errorCode);
    }];
}

- (void)deleteEndToEndPrivateKeyWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication deleteEndToEndPrivateKey:[tableAccount.url stringByAppendingString:@"/"] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        completion(account, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, message, errorCode);
    }];
}

- (void)getEndToEndServerPublicKeyWithAccount:(NSString *)account completion:(void (^)(NSString *account, NSString *publicKey, NSString *message, NSInteger errorCode))completion
{
    tableAccount *tableAccount = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account == %@", account]];
    if (tableAccount == nil) {
        completion(account, nil, NSLocalizedString(@"_error_user_not_available_", nil), k_CCErrorUserNotAvailble);
    }
    
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    [communication setCredentialsWithUser:tableAccount.user andUserID:tableAccount.userID andPassword:[CCUtility getPassword:account]];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication getEndToEndServerPublicKey:[tableAccount.url stringByAppendingString:@"/"] onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *publicKey, NSString *redirectedServer) {
        
        completion(account, publicKey, nil, 0);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        NSString *message = @"";
        NSInteger errorCode = response.statusCode;
        if (errorCode == 0 || (errorCode >= 200 && errorCode < 300))
            errorCode = error.code;
        
        // Error
        if (errorCode == 503) {
            message = NSLocalizedString(@"_server_error_retry_", nil);
        } else {
            message = [error.userInfo valueForKey:@"NSLocalizedDescription"];
        }
        
        completion(account, nil, message, errorCode);
    }];
}

- (void)createEndToEndFolder:(NSString *)folderPathName account:(NSString *)account user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url encrypted:(BOOL)encrypted ocId:(NSString **)ocId fileId:(NSString **)fileId error:(NSError **)error
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;
    __block NSString *returnFileId = nil;
    __block NSString *returnOcId = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication readFile:folderPathName onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        [communication createFolder:folderPathName onCommunication:communication withForbiddenCharactersSupported:YES successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            
            NSDictionary *fields = [response allHeaderFields];
            returnOcId = [CCUtility removeForbiddenCharactersFileSystem:[fields objectForKey:@"OC-FileId"]];
            NSArray *components = [returnOcId componentsSeparatedByString:@"oc"];
            NSInteger numFileId = [components.firstObject intValue];
            returnFileId = [@(numFileId) stringValue];
            
            if (encrypted) {
                
                // MARK
                [communication markEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:returnFileId onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                    
                    [[NCManageDatabase sharedInstance] clearDateReadWithServerUrl:[CCUtility deletingLastPathComponentFromServerUrl:folderPathName] account:account];
                    dispatch_semaphore_signal(semaphore);
                    
                } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                    
                    returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_mark_folder_"];
                    dispatch_semaphore_signal(semaphore);
                }];
                
            } else {
                
                [[NCManageDatabase sharedInstance] clearDateReadWithServerUrl:[CCUtility deletingLastPathComponentFromServerUrl:folderPathName] account:account];
                dispatch_semaphore_signal(semaphore);
            }
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            returnError = [self getError:response error:error descriptionDefault:@"_error_"];
            dispatch_semaphore_signal(semaphore);
            
        } errorBeforeRequest:^(NSError *error) {
            
            returnError = [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:response.description forKey:NSLocalizedDescriptionKey]];
            dispatch_semaphore_signal(semaphore);

        }];
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    *ocId = returnOcId;
    *fileId = returnFileId;
    *error = returnError;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ===== E2EE End-to-End Encryption =====
#pragma --------------------------------------------------------------------------------------------
// E2EE

- (NSError *)markEndToEndFolderEncryptedOnServerUrl:(NSString *)serverUrl fileId:(NSString *)fileId user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    // MARK
    [communication markEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_mark_folder_"];
        dispatch_semaphore_signal(semaphore);
        
    }];
      
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)deletemarkEndToEndFolderEncryptedOnServerUrl:(NSString *)serverUrl fileId:(NSString *)fileId user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];
        
    // LOCK
    [communication lockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:tableLock.e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *e2eToken, NSString *redirectedServer) {
        
        [[NCManageDatabase sharedInstance] setE2ETokenLockWithServerUrl:serverUrl fileId:fileId e2eToken:e2eToken];
        
        // DELETE MARK
        [communication deletemarkEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            
            // UNLOCK
            [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                dispatch_semaphore_signal(semaphore);
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                dispatch_semaphore_signal(semaphore);
            }];
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_delete_mark_folder_"];

            // UNLOCK
            [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                dispatch_semaphore_signal(semaphore);
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_lock_"];
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)getEndToEndMetadata:(NSString **)metadata fileId:(NSString *)fileId user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;
    __block NSString *returnMetadata = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    [communication getEndToEndMetadata:[url stringByAppendingString:@"/"] fileId:fileId onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *encryptedMetadata, NSString *redirectedServer) {
        
        returnMetadata = encryptedMetadata;
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_get_metadata_"];
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    *metadata = returnMetadata;
    return returnError;
}

- (NSError *)deleteEndToEndMetadataOnServerUrl:(NSString *)serverUrl fileId:(NSString *)fileId unlock:(BOOL)unlock user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];

    // LOCK
    [communication lockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:tableLock.e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *e2eToken, NSString *redirectedServer) {
            
        [[NCManageDatabase sharedInstance] setE2ETokenLockWithServerUrl:serverUrl fileId:fileId e2eToken:e2eToken];
            
        // DELETE METADATA
        [communication deleteEndToEndMetadata:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                
            // UNLOCK
            if (unlock) {
                [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                    [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                    dispatch_semaphore_signal(semaphore);
                } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                    returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                dispatch_semaphore_signal(semaphore);
            }
                
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                
            returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_delete_metadata_"];

            // UNLOCK
            [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                dispatch_semaphore_signal(semaphore);
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                dispatch_semaphore_signal(semaphore);
            }];
        }];
            
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_lock_"];
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)storeEndToEndMetadata:(NSString *)metadata serverUrl:(NSString *)serverUrl fileId:(NSString *)fileId unlock:(BOOL)unlock user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];

    // LOCK
    [communication lockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:tableLock.e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *e2eToken, NSString *redirectedServer) {
        
        [[NCManageDatabase sharedInstance] setE2ETokenLockWithServerUrl:serverUrl fileId:fileId e2eToken:e2eToken];
        
        // STORE METADATA
        [communication storeEndToEndMetadata:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken encryptedMetadata:metadata onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *encryptedMetadata, NSString *redirectedServer) {
            
            // UNLOCK
            if (unlock) {
                [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                    [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                    dispatch_semaphore_signal(semaphore);
                } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                    returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                dispatch_semaphore_signal(semaphore);
            }
                
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_store_metadata_"];

            // UNLOCK
            [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                dispatch_semaphore_signal(semaphore);
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_lock_"];
        dispatch_semaphore_signal(semaphore);
    }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)updateEndToEndMetadata:(NSString *)metadata serverUrl:(NSString *)serverUrl fileId:(NSString *)fileId unlock:(BOOL)unlock user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];

    // LOCK
    [communication lockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:tableLock.e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *e2eToken, NSString *redirectedServer) {
        
        [[NCManageDatabase sharedInstance] setE2ETokenLockWithServerUrl:serverUrl fileId:fileId e2eToken:e2eToken];
        
        // UPDATA METADATA
        [communication updateEndToEndMetadata:[url stringByAppendingString:@"/"] fileId:fileId encryptedMetadata:metadata e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *encryptedMetadata, NSString *redirectedServer) {
            
            // UNLOCK
            if (unlock) {
                [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                    [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                    dispatch_semaphore_signal(semaphore);
                } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                    returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                dispatch_semaphore_signal(semaphore);
            }
                
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
            returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_update_metadata_"];

            // UNLOCK
            [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
                dispatch_semaphore_signal(semaphore);
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_lock_"];
        dispatch_semaphore_signal(semaphore);
    }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)lockEndToEndFolderEncryptedOnServerUrl:(NSString *)serverUrl fileId:(NSString *)fileId user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    tableE2eEncryptionLock *tableLock = [[NCManageDatabase sharedInstance] getE2ETokenLockWithServerUrl:serverUrl];
    
    // LOCK
    [communication lockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:tableLock.e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *e2eToken, NSString *redirectedServer) {
        
        [[NCManageDatabase sharedInstance] setE2ETokenLockWithServerUrl:serverUrl fileId:fileId e2eToken:e2eToken];
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_lock_"];
        dispatch_semaphore_signal(semaphore);
    }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)unlockEndToEndFolderEncryptedOnServerUrl:(NSString *)serverUrl fileId:(NSString *)fileId e2eToken:(NSString *)e2eToken user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    OCCommunication *communication = [OCNetworking sharedManager].sharedOCCommunication;

    __block NSError *returnError = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [communication setCredentialsWithUser:user andUserID:userID andPassword:password];
    [communication setUserAgent:[CCUtility getUserAgent]];
    
    // UNLOCK
    [communication unlockEndToEndFolderEncrypted:[url stringByAppendingString:@"/"] fileId:fileId e2eToken:e2eToken onCommunication:communication successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        [[NCManageDatabase sharedInstance] deteleE2ETokenLockWithServerUrl:serverUrl];
        dispatch_semaphore_signal(semaphore);
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        returnError = [self getError:response error:error descriptionDefault:@"_e2e_error_unlock_"];
        dispatch_semaphore_signal(semaphore);
    }];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:k_timeout_webdav]];
    
    return returnError;
}

- (NSError *)sendEndToEndMetadataOnServerUrl:(NSString *)serverUrl fileNameRename:(NSString *)fileName fileNameNewRename:(NSString *)fileNameNew unlock:(BOOL)unlock account:(NSString *)account user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url 
{
    tableDirectory *directory = [[NCManageDatabase sharedInstance] getTableDirectoryWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", account, serverUrl]];
    
    NSString *metadata;
    NSError *error;
    
    // Enabled E2E
    if ([CCUtility isEndToEndEnabled:account] == NO)
        return [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:k_CCErrorInternalError userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"_e2e_error_not_enabled_", nil) forKey:NSLocalizedDescriptionKey]];
    
    // get Metadata for select updateEndToEndMetadata or storeEndToEndMetadata
    error = [self getEndToEndMetadata:&metadata fileId:directory.fileId user:user userID:userID password:password url:url];
    if (error.code != kOCErrorServerPathNotFound && error != nil) {
        return error;
    }
    
    // Rename
    if (fileName && fileNameNew)
        [[NCManageDatabase sharedInstance] renameFileE2eEncryptionWithServerUrl:serverUrl fileNameIdentifier:fileName newFileName:fileNameNew newFileNamePath:[CCUtility returnFileNamePathFromFileName:fileNameNew serverUrl:serverUrl activeUrl:url]];

    NSArray *tableE2eEncryption = [[NCManageDatabase sharedInstance] getE2eEncryptionsWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", account, serverUrl]];
    if (!tableE2eEncryption)
        return [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:k_CCErrorInternalError userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"_e2e_error_record_not_found_", nil) forKey:NSLocalizedDescriptionKey]];
    
    NSString *e2eMetadataJSON = [[NCEndToEndMetadata sharedInstance] encoderMetadata:tableE2eEncryption privateKey:[CCUtility getEndToEndPrivateKey:account] serverUrl:serverUrl];
    if (!e2eMetadataJSON)
        return [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:k_CCErrorInternalError userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"_e2e_error_encode_metadata_", nil) forKey:NSLocalizedDescriptionKey]];
    
    // send Metadata
    if (error == nil)
        error = [self updateEndToEndMetadata:e2eMetadataJSON serverUrl:serverUrl fileId:directory.fileId unlock:unlock user:user userID:userID password:password url:url];
    else if (error.code == kOCErrorServerPathNotFound)
        error = [self storeEndToEndMetadata:e2eMetadataJSON serverUrl:serverUrl fileId:directory.fileId unlock:unlock user:user userID:userID password:password url:url];
    
    return error;
}

- (NSError *)rebuildAndSendEndToEndMetadataOnServerUrl:(NSString *)serverUrl account:(NSString *)account user:(NSString *)user userID:(NSString *)userID password:(NSString *)password url:(NSString *)url
{
    NSError *error;
    NSString *e2eMetadataJSON;
    
    tableDirectory *directory = [[NCManageDatabase sharedInstance] getTableDirectoryWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", account, serverUrl]];
    if (directory.e2eEncrypted == NO)
        return nil;
    
    NSArray *tableE2eEncryption = [[NCManageDatabase sharedInstance] getE2eEncryptionsWithPredicate:[NSPredicate predicateWithFormat:@"account == %@ AND serverUrl == %@", account, serverUrl]];
    if (tableE2eEncryption) {
        
        e2eMetadataJSON = [[NCEndToEndMetadata sharedInstance] encoderMetadata:tableE2eEncryption privateKey:[CCUtility getEndToEndPrivateKey:account] serverUrl:serverUrl];
        if (!e2eMetadataJSON)
            return [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:k_CCErrorInternalError userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"_e2e_error_encode_metadata_", nil) forKey:NSLocalizedDescriptionKey]];
        
        error = [self updateEndToEndMetadata:e2eMetadataJSON serverUrl:serverUrl fileId:directory.fileId unlock:YES user:user userID:userID password:password url:url];
    
    } else {
    
        [self deleteEndToEndMetadataOnServerUrl:serverUrl fileId:directory.fileId unlock:YES user:user userID:userID password:password url:url];
    }
    
    return error;
}

- (NSError *)getError:(NSHTTPURLResponse *)response error:(NSError *)error descriptionDefault:(NSString *)descriptionDefault
{
    NSInteger errorCode = response.statusCode;
    NSString *errorDescription = response.description;
    
    if (errorDescription == nil || errorCode == 0) {
        errorCode = error.code;
        errorDescription = error.description;
        if (errorDescription == nil) errorDescription = NSLocalizedString(descriptionDefault, @"");
    }
    
    errorDescription = [NSString stringWithFormat:@"%@ [%ld] - %@", NSLocalizedString(descriptionDefault, @""), (long)errorCode, errorDescription];

    if (errorDescription.length >= 250) {
        errorDescription = [errorDescription substringToIndex:250];
        errorDescription = [errorDescription stringByAppendingString:@" ..."];
    }
    
    return [NSError errorWithDomain:@"com.infomaniak.nextcloud" code:errorCode userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedDescriptionKey]];
}

@end
