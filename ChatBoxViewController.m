//
//  ChatBoxViewController.m
//  PubChatter
//
//  Created by Richard Fellure on 6/16/14.
//  Copyright (c) 2014 Naomi Himley. All rights reserved.
//

#import "ChatBoxViewController.h"
#import "AppDelegate.h"
#import "Peer.h"
#import "Message.h"
#import "SWRevealViewController.h"
#import "UIColor+DesignColors.h"


@interface ChatBoxViewController ()<UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
@property (weak, nonatomic) IBOutlet UITextView *chatTextView;
@property PFUser *chatingUser;
@property MCPeerID *chattingUserPeerID;
@property AppDelegate *appDelegate;

-(void)didReceiveDataWithNotification: (NSNotification *)notification;
-(void)sendMyMessage;

@end

@implementation ChatBoxViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.chatTextView.backgroundColor = [UIColor pubChatPurple];
    self.chatTextView.editable = NO;
    self.fetchedResultsController.delegate = self;
    self.fetchedResultsController = [[NSFetchedResultsController alloc]init];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePeerToChatWithNotification:)
                                                 name:@"PeerToChatWith"
                                               object:nil];
    self.chatTextField.delegate = self;
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    [self.view resignFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


#pragma mark - TextField Delegate method

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendMyMessage];
    return YES;
}

#pragma mark - Notification Methods
//notification for receiving a text
- (void)didReceiveDataWithNotification:(NSNotification *)notification
{
    NSString *notificationDisplayName =[[[notification userInfo]objectForKey:@"peerID"] displayName];
    //if the data is coming from the person you're chatting with then add it to the text view
    if ([self.chattingUserPeerID.displayName isEqual:notificationDisplayName]) {
        NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
        NSString *receivedText = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSString *chatString = [NSString stringWithFormat:@"%@:%@\n", [self.chatingUser objectForKey:@"name"], receivedText];
        [self.chatTextView performSelectorOnMainThread:@selector(setText:) withObject:[self.chatTextView.text stringByAppendingString:chatString] waitUntilDone:NO];
    }
}

//notification from when you click the "CHAT" button in the drawer
- (void)didReceivePeerToChatWithNotification: (NSNotification *)notification
{
    self.chattingUserPeerID = [[notification userInfo]objectForKey:@"peerID"];
    self.chatingUser = [[notification userInfo]objectForKey:@"user"];
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"Peer"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"peerID" ascending:YES]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerID == %@", self.chattingUserPeerID.displayName];
    request.predicate = predicate;
    self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController performFetch:nil];

    NSMutableArray *array = (NSMutableArray *)[self.fetchedResultsController fetchedObjects];
    Peer *peer = [array firstObject];
    NSSet *messagesSet = peer.messages;
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    NSArray *sortedMessages = [[messagesSet allObjects] sortedArrayUsingDescriptors:@[sorter]];
    NSLog(@"sorted messages array: %@", sortedMessages);
    //load the tableView here!
}

#pragma mark - Helper method implementations


- (void)sendMyMessage
{
        NSString *userInput = self.chatTextField.text;
        NSData *dataToSend = [userInput dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *peerToSendTo = @[self.chattingUserPeerID];
        NSError *error;
        [self.appDelegate.mcManager.session sendData:dataToSend
                                             toPeers:peerToSendTo
                                            withMode:MCSessionSendDataReliable
                                               error:&error];
        if (error)
        {
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Connection to User has been lost"
                                                               message:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil, nil];
            [alertView show];
        }

        else
        {
//            [self.chatTextView setText:[self.chatTextView.text stringByAppendingString:chatString]];
            if ([self doesConversationExist:self.chattingUserPeerID] == NO)
            {
                Peer *peer = [NSEntityDescription insertNewObjectForEntityForName:@"Peer" inManagedObjectContext:moc];
                Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:moc];
                message.text = userInput;
                message.isMyMessage = @1;
                message.timeStamp = [NSDate date];
                peer.peerID = self.chattingUserPeerID.displayName;
                [peer addMessagesObject:message];
                [moc save:nil];
                NSLog(@"CHATBOX creating new Peer and Message in sendMyMessage");
            }
            else
            {
                NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"Peer"];
                request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"peerID" ascending:YES]];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerID == %@", self.chattingUserPeerID.displayName];
                request.predicate = predicate;
                self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
                [self.fetchedResultsController performFetch:nil];
                NSMutableArray *array = (NSMutableArray *)[self.fetchedResultsController fetchedObjects];
                Peer *peer = [array firstObject];
                Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:moc];
                message.text = userInput;
                message.isMyMessage = @1;
                message.timeStamp = [NSDate date];
                [peer addMessagesObject:message];
                [moc save:nil];
                NSLog(@"CHATBOX adding message in sendMyMessage: %@", message.text);
            }

            self.chatTextField.text = @"";
        }
    [self.chatTextField resignFirstResponder];
}


- (BOOL)doesConversationExist :(MCPeerID *)peerID
{
    if (peerID)
    {
        NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"Peer"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"peerID" ascending:YES]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerID == %@", peerID.displayName];
        request.predicate = predicate;

        self.fetchedResultsController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
        [self.fetchedResultsController performFetch:nil];
        NSMutableArray *array = (NSMutableArray *)[self.fetchedResultsController fetchedObjects];
        if (array.count < 1)
        {
            NSLog(@"not returning any fetched results in CHATBOX");
            return NO;
        }
        NSLog(@"the fetch returned something in CHATBOX");
        return YES;
    }
    else
    {
        NSLog(@"the peer id was null IN CHATBOX");
        return NO;
    }
}

# pragma mark - Button Actions

- (IBAction)onButtonPressedEndSession:(id)sender
{
    //should remove the current convo from moc
    self.chatTextView.text = @"";
    self.chatTextField.text = @"";
    //should only disconnect user from the current chatting peer

    if (self.appDelegate.mcManager.session.connectedPeers.count > 0)
    {
        [[self.appDelegate.mcManager.session.connectedPeers objectAtIndex:0] disconnect];
    }
}
- (IBAction)onButtonPressedCancelSendingChat:(id)sender
{
    self.chatTextField.text = @"";
    [self.chatTextField resignFirstResponder];
}

- (IBAction)onButtonPressedSendChat:(id)sender
{
    if (self.appDelegate.mcManager.session.connectedPeers.count > 0) {
        if(self.chattingUserPeerID)
        {
            [self sendMyMessage];
        }
        else
        {
            self.chattingUserPeerID = self.appDelegate.mcManager.session.connectedPeers[0];
            [self sendMyMessage];
        }
    }
    else
    {
        //user not connected to anyone
    }
}
@end
