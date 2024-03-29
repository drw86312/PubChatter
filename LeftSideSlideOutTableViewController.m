//
//  LeftSideSlideOutTableViewController.m
//  PubChatter
//
//  Created by Richard Fellure on 6/24/14.
//  Copyright (c) 2014 Naomi Himley. All rights reserved.
//

#import "LeftSideSlideOutTableViewController.h"
#import "ChatBoxViewController.h"
#import "AppDelegate.h"
#import "ListOfUsersTableViewCell.h"
#import "OPPViewController.h"
#import "SWRevealViewController.h"
#import "UIColor+DesignColors.h"

#import <Parse/Parse.h>

@interface LeftSideSlideOutTableViewController ()

@property AppDelegate *appDelegate;
@property NSMutableArray *cellArray;
@property NSMutableArray *users;
@property NSArray *parseUsers;
@property NSDictionary *userSendingInvitation;
@property UIButton *selectedChatButton;
@property NSString *barString;
@property BOOL isInviter;

@end

@implementation LeftSideSlideOutTableViewController

- (void)viewDidLoad
{

    [super viewDidLoad];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.users = [NSMutableArray array];

    self.cellArray = [NSMutableArray array];

    [self.appDelegate.mcManager setupPeerAndSessionWithDisplayName:[[PFUser currentUser]objectForKey:@"username"]];
    [self.appDelegate.mcManager advertiseSelf:YES];
    [self.appDelegate.mcManager startBrowsingForPeers];

    [self.tableView setBackgroundView: [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"river"]]];

    self.isInviter = YES;

    [self startListeningForNotificationsAndSendNotification];

    self.tableView.backgroundColor = [UIColor blackColor];

    self.navigationItem.title = @"Chatters Available";

     
}

-(void)dealloc
{
    self.users = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Make Accepter

-(void)makePeerAccepter
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isInviter = NO;
    });
    NSLog(@"Is now an acceptor");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return self.users.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListOfUsersTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *dictionary = [self.users objectAtIndex:indexPath.row];

    MCPeerID *peerID = [dictionary objectForKey:@"peerID"];

    PFUser *user = [dictionary objectForKey:@"user"];



    cell.userNameLabel.textColor = [UIColor nameColor];
    cell.genderLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = [[UIColor backgroundColor] colorWithAlphaComponent:0.5];
    cell.chatButton.backgroundColor = [UIColor buttonColor];

    cell.userNameLabel.text = [user objectForKey:@"name"];
    cell.chatButton.tag = indexPath.row;
    [self.cellArray addObject:cell];
    cell.tag = [self.users indexOfObject:dictionary];
    cell.cellUserDisplayName = peerID.displayName;
    [cell.chatButton setTitle:@"" forState:UIControlStateNormal];

    cell.chatButton.shouldInvite = YES;

    cell.chatButton.layer.masksToBounds = YES;
    cell.chatButton.layer.cornerRadius = 5.0f;

    cell.layer.masksToBounds = YES;
    cell.layer.borderWidth = 0.25f;
    cell.layer.borderColor = [[UIColor whiteColor]CGColor];

    cell.chatReceivedImage.image = [UIImage imageNamed:@"StartChatIcon"];


    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if ([user [@"gender"] isEqual:@0] && [user objectForKey:@"age"])
    {
        cell.genderLabel.text = [NSString stringWithFormat:@"%@, female", [user objectForKey:@"age"]];
        [cell.genderLabel sizeToFit];
    }
    else if ([user[@"gender"] isEqual:@1] && [user objectForKey:@"age"])
    {
        cell.genderLabel.text = [NSString stringWithFormat:@"%@, male", [user objectForKey:@"age"]];
        [cell.genderLabel sizeToFit];
    }
    else if ([user [@"gender"] isEqual:@2] && [user objectForKey:@"age"])
    {
        cell.genderLabel.text = [NSString stringWithFormat:@"%@, other", [user objectForKey:@"age"]];
        [cell.genderLabel sizeToFit];
    }
    else if ([user [@"gender"] isEqual:@0])
    {
        cell.genderLabel.text = @"female";
    }
    else if ([user [@"gender"] isEqual:@1])
    {
        cell.genderLabel.text = @"male";
    }
    else if ([user [@"gender"] isEqual:@2])
    {
        cell.genderLabel.text = @"other";
    }
    else if ([user objectForKey:@"age"])
    {
        cell.genderLabel.text = [NSString stringWithFormat:@"%@", [user objectForKey:@"age"]];
    }
    else
    {
        cell.genderLabel.text = @"No Info";
    }

    PFFile *imageFile = [user objectForKey:@"picture"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        cell.userImage.layer.masksToBounds = YES;
        cell.userImage.image = [UIImage imageWithData:data];
        cell.textLabel.text = @"";
    }];
    return cell;
}

#pragma mark - Handling new advertising user

-(void)receivedNotificationOfUserAdvertising:(NSNotification *)notification
{
    MCPeerID *peerID = [[notification userInfo]objectForKey:@"peerID"];
    NSLog(@"user found advertising %@", peerID.displayName);

    if (!self.parseUsers)
    {

        PFQuery *query = [PFQuery queryWithClassName:@"_User"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
            if (!error)
            {
                self.parseUsers = [NSArray arrayWithArray:objects];
            }
            else
            {
                NSLog(@"parseQuery error in listVC %@", error);
            }
            [self findUsers:peerID];

            [self.tableView reloadData];
        }];
    }
    else
    {
        [self findUsers: peerID];

        [self.tableView reloadData];
    }
}

# pragma mark - Finding active users

-(void)findUsers:(MCPeerID *)peerID
{
    for (NSDictionary *dictionary in self.parseUsers)
    {
        if ([[dictionary objectForKey:@"username"] isEqual:peerID.displayName])
        {
            if (self.users.count < self.appDelegate.mcManager.advertisingUsers.count)
            {
                NSDictionary *userDictionary = @{@"peerID": peerID,
                                                 @"user": dictionary};
                [self.users addObject:userDictionary];
            }
        }
    }
}

#pragma mark - Action for Button selecting peer to chat with

- (IBAction)onButtonTappedSelectPeerToChatWith:(id)sender
{
    ChatButton *button = (ChatButton *)sender;

    ListOfUsersTableViewCell *cell = (ListOfUsersTableViewCell *)[[[sender superview]superview]superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    NSDictionary *dictionary = [self.users objectAtIndex:indexPath.row];

    MCPeerID *peerID = [dictionary objectForKey:@"peerID"];

    if (self.isInviter == YES)
    {
        self.isInviter = NO;
        NSLog(@"This peer should now be the Inviter");
        
         [self.appDelegate.mcManager.browser invitePeer:peerID toSession:self.appDelegate.mcManager.session withContext:nil timeout:30.0];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MakeInviter" object:nil userInfo:nil];
    }

    self.selectedChatButton.backgroundColor = [UIColor buttonColor];
    self.selectedChatButton = nil;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"PeerToChatWith" object:nil userInfo:dictionary];
    cell.chatReceivedImage.image = [UIImage imageNamed:@"StartChatIcon"];
    self.selectedChatButton = button;
    self.selectedChatButton.backgroundColor = [UIColor accentColor];
}

#pragma mark - Private method for handling the changing of peer's state

-(void)peerDidChangeStateWithNotification:(NSNotification *)notification
{
    if ([[[notification userInfo]objectForKey:@"state"]intValue] != MCSessionStateConnecting)
    {
        if ([[[notification userInfo]objectForKey:@"state"]intValue] == MCSessionStateNotConnected)
        {
            MCPeerID *peerID = [[notification userInfo]objectForKey:@"peerID"];


            NSLog(@"peer changed state notification came through");
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userDictionary = [NSDictionary new];
                for (NSDictionary *dictionary in self.users)
                {
                    MCPeerID *peer = [dictionary objectForKey:@"peerID"];

                    if (peer.displayName == peerID.displayName)
                    {
                        NSLog(@"1.peerID of peer who lost connection %@", peerID.displayName);
                        userDictionary = dictionary;
                    }
                }
                [self.users removeObject:userDictionary];
                [self.appDelegate.mcManager.foundPeersArray removeObject:peerID.displayName];
                [self.tableView reloadData];
                NSLog(@"reload of tableView has went through after user went to not Connected");
            });


            if (self.appDelegate.mcManager.session.connectedPeers.count == 0)
            {
                self.isInviter = YES;
//                [self tearDownSession];
                [self becameActive:nil];
                NSLog(@"should be able to invite now, tearing down and rebuilding");
            }

            NSLog(@"Connect peers after changing state to notConnected %@", self.appDelegate.mcManager.session.connectedPeers);
        }
    }

    MCPeerID *peerID = [[notification userInfo]objectForKey:@"peerID"];

    NSDictionary *userDictionary = [NSDictionary new];

    for (NSDictionary *dictionary in self.users)
    {
        if ([[dictionary objectForKey:@"peerID"] isEqual:peerID])
        {
            userDictionary = dictionary;
        }
    }
}

# pragma mark - Stopped Advertising method catcher

-(void)peerStoppedAdvertising:(NSNotification *)notificaion
{
    MCPeerID *peerID = [[notificaion userInfo]objectForKey:@"peerID"];
    NSDictionary *userDictionary = [NSDictionary new];

    for (NSDictionary *dictionary in self.users)
    {
        if (![self.appDelegate.mcManager.connectedArray containsObject:peerID.displayName])
        {
            NSLog(@"should be moving towards removing a user");
            NSLog(@"displayname %@", peerID.displayName);
            MCPeerID *peer = [dictionary objectForKey:@"peerID"];

            if (peer.displayName == peerID.displayName)
            {
                NSLog(@"Should remove a user");
                userDictionary = dictionary;
            }
        }
    }
    [self.users removeObject:userDictionary];
    [self.tableView reloadData];
}

#pragma mark - Private method for handling a peer sending a text

-(void)receivedChatDataFromPeer: (NSNotification *)notification
{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];

    NSDictionary *userDictionary = [NSDictionary new];

    for (NSDictionary *dictionary in self.users)
    {
        if ([[dictionary objectForKey:@"peerID"] isEqual:peerID])
        {
            userDictionary = dictionary;
        }
    }

    for (ListOfUsersTableViewCell *userCell in self.cellArray)
    {
        if ([userCell.cellUserDisplayName isEqual:peerID.displayName])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                userCell.chatReceivedImage.image = [UIImage imageNamed:@"ReceivedChatIcon"];
            });
        }
    }
}

#pragma mark - Recreating the session after app has terminated

-(void)becameActive: (NSNotification *)notification
{
    if (self.appDelegate.mcManager.session == nil)
    {
        [self.appDelegate.mcManager setupPeerAndSessionWithDisplayName:[[PFUser currentUser]objectForKey:@"username"]];
        [self.appDelegate.mcManager advertiseSelf:YES];
        [self.appDelegate.mcManager.browser startBrowsingForPeers];
        self.isInviter = YES;
        [self.tableView reloadData];

        NSLog(@"Should have finished rebuilding the session %@", self.appDelegate.mcManager.session);
    }
    

}

//-(void)tearDownSession
//{
//    [self.appDelegate.mcManager.session disconnect];
//    self.appDelegate.mcManager.session.delegate = nil;
//    self.appDelegate.mcManager.session = nil;
//
//    [self.appDelegate.mcManager advertiseSelf:NO];
//    self.appDelegate.mcManager.advertiser.delegate = nil;
//    self.appDelegate.mcManager.advertiser = nil;
//
//    self.appDelegate.mcManager.browser.delegate = nil;
//    self.appDelegate.mcManager.browser = nil;
//
//    self.appDelegate.mcManager.peerID = nil;
//
//    self.appDelegate.mcManager.shouldInvite = NO;
//    [self.appDelegate.mcManager.foundPeersArray removeAllObjects];
//    [self.appDelegate.mcManager.connectedArray removeAllObjects];
//    [self.appDelegate.mcManager.advertisingUsers removeAllObjects];
//
//    NSLog(@"tearingDown session due to lack of no connected users %@", self.appDelegate.mcManager.session);
//}

#pragma mark - Prepare for segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    OPPViewController *oppVC = segue.destinationViewController;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    NSDictionary *dictionary = [self.users objectAtIndex:indexPath.row];
    PFUser *selectedUser = [dictionary objectForKey:@"user"];
    
    oppVC.user = selectedUser;
}

#pragma mark - Notification listeners

-(void)startListeningForNotificationsAndSendNotification
{
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(peerDidChangeStateWithNotification:) name:@"MCDidChangeStateNotification"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(receivedNotificationOfUserAdvertising:)
                                                name:@"MCFoundAdvertisingPeer"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(peerStoppedAdvertising:)
                                                name:@"MCPeerStopAdvertising"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(receivedChatDataFromPeer:) name:@"MCDidReceiveDataNotification"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(peerDidChangeStateWithNotification:) name:@"MCDidChangeStateNotification"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(makePeerAccepter)
                                                name:@"MCJustAccepts"
                                              object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becameActive:)
                                                name:@"UIApplicationBecameActive"
                                              object:nil];

}

@end