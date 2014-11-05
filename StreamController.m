//
//  StreamController.m
//  flood
//
//  Created by b123400 on 2/11/14.
//
//

#import "StreamController.h"
#import <Social/Social.h>
#import <STTwitter/STTwitter.h>
#import "Status.h"

@interface StreamController()

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) ACAccountType *accountType;
@property (nonatomic, strong) ACAccount *account;
@property (nonatomic, strong) STTwitterAPI *twitter;

@property (nonatomic, strong) NSURLConnection *streamConnection;

@end

@implementation StreamController

+ (instancetype)shared {
    return [[StreamController alloc] init];
}

- (id)initWithAccount:(ACAccount*)account {
    self = [super init];
    
    self.accountStore = [[ACAccountStore alloc] init];
    self.accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    self.account = account;
    self.twitter = [STTwitterAPI twitterAPIOSWithAccount:self.account];
    
    return self;
}

- (void)setSearchTerm:(NSString*)searchTerm {
    _searchTerm = searchTerm;
}

- (void)startStreaming {
    [self reconnect];
}

- (void)reconnect {
    [self.streamConnection cancel];
    self.streamConnection = [self.twitter
                             getUserStreamDelimited:nil
                             stallWarnings:nil
                             includeMessagesFromFollowedAccounts:nil
                             includeReplies:nil
                             keywordsToTrack:self.searchTerm?@[self.searchTerm]:nil
                             locationBoundingBoxes:nil
                             progressBlock:^(id response) {
                                 if (response && [response isKindOfClass:[NSDictionary class]]) {
                                         Status *status = [[Status alloc] initWithDictionary:response];
                                      if (status && [self.delegate respondsToSelector:@selector(streamController:didReceivedTweet:)]) {
                                         [self.delegate streamController:self didReceivedTweet:status];
                                     }
                                 }
                             }
                             stallWarningBlock:^(NSString *code, NSString *message, NSUInteger percentFull) {
                                 NSLog(@"stall warning %@", message);
                             }
                             errorBlock:^(NSError *error) {
                                 NSLog(@"stream controller error: %@", error.description);
                                 [self reconnect];
                             }];
}

@end