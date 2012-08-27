//
//  HierarchyViewController.m
//  Hierarchy
//
//  Created by Kris Fields on 8/25/12.
//  Copyright (c) 2012 Kris Fields. All rights reserved.
//

#import "HierarchyViewController.h"

@interface HierarchyViewController ()


@end

@implementation HierarchyViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    textInputField.delegate = self;
    [GCTurnBasedMatchHelper sharedInstance].delegate = self;
    textInputField.enabled = NO;
    statusLabel.text = @"Welcome.  Press Game Center to get started";
}

- (void)viewDidUnload
{
    mainTextController = nil;
    inputView = nil;
    textInputField = nil;
    characterCountLabel = nil;
    statusLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
    NSLog(@"text view up");
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 210; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    
    int textFieldMovement = movement * 0.75;
    inputView.frame = CGRectOffset(inputView.frame, 0, movement);
    mainTextController.frame = CGRectMake(mainTextController.frame.origin.x, mainTextController.frame.origin.y, mainTextController.frame.size.width, mainTextController.frame.size.height + textFieldMovement);
    [UIView commitAnimations];
    NSLog(@"%f", mainTextController.frame.size.height);
}

- (IBAction)updateCount:(id)sender {
    UITextField *tf = (UITextField *)sender;
    int len = [tf.text length];
    int remain = 250 - len;
    characterCountLabel.text = [NSString stringWithFormat:@"%d", remain];
    if (remain < 0) {
        characterCountLabel.textColor = [UIColor redColor];
    } else {
        characterCountLabel.textColor = [UIColor blackColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)sendTurn:(id)sender {
    GKTurnBasedMatch *currentMatch =
    [[GCTurnBasedMatchHelper sharedInstance] currentMatch];
    NSString *newStoryString;
    if ([textInputField.text length] > 250) {
        newStoryString = [textInputField.text substringToIndex:249];
    } else {
        newStoryString = textInputField.text;
    }
    
    NSString *sendString = [NSString stringWithFormat:@"%@ %@",
                            mainTextController.text, newStoryString];
    NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding ];
    mainTextController.text = sendString;
    
    NSUInteger currentIndex = [currentMatch.participants
                               indexOfObject:currentMatch.currentParticipant];
    GKTurnBasedParticipant *nextParticipant;
    
    NSUInteger nextIndex = (currentIndex + 1) %
    [currentMatch.participants count];
    nextParticipant = [currentMatch.participants objectAtIndex:nextIndex];
    
    for (int i = 0; i < [currentMatch.participants count]; i++) {
        nextParticipant = [currentMatch.participants
                           objectAtIndex:((currentIndex + 1 + i) %
                                          [currentMatch.participants count ])];
        if (nextParticipant.matchOutcome != GKTurnBasedMatchOutcomeQuit) {
            NSLog(@"isnt' quit %@", nextParticipant);
            break;
        } else {
            NSLog(@"nex part %@", nextParticipant);
        }
    }
    
    if ([data length] > 3800) {
        for (GKTurnBasedParticipant *part in currentMatch.participants) {
            part.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        [currentMatch endMatchInTurnWithMatchData:data
                                completionHandler:^(NSError *error) {
                                    if (error) {
                                        NSLog(@"%@", error);
                                    }
                                }];
        statusLabel.text = @"Game has ended";
    } else {
        
        [currentMatch endTurnWithNextParticipant:nextParticipant
                                       matchData:data completionHandler:^(NSError *error) {
                                           if (error) {
                                               NSLog(@"%@", error);
                                               statusLabel.text =
                                               @"Oops, there was a problem.  Try that again.";
                                           } else {
                                               statusLabel.text = @"Your turn is over.";
                                               textInputField.enabled = NO;
                                           }
                                       }];
    }
    NSLog(@"Send Turn, %@, %@", data, nextParticipant);
    textInputField.text = @"";
    characterCountLabel.text = @"250";
    characterCountLabel.textColor = [UIColor blackColor];
}

- (IBAction)presentGCTurnViewController:(id)sender {
    [[GCTurnBasedMatchHelper sharedInstance]
     findMatchWithMinPlayers:2 maxPlayers:12 viewController:self];
}

#pragma mark - GCTurnBasedMatchHelperDelegate

-(void)enterNewGame:(GKTurnBasedMatch *)match {
    NSLog(@"Entering new game...");
    statusLabel.text = @"Player 1's Turn (that's you)";
    textInputField.enabled = YES;
    mainTextController.text = @"Once upon a time";
}

-(void)takeTurn:(GKTurnBasedMatch *)match {
    NSLog(@"Taking turn for existing game...");
    int playerNum = [match.participants
                     indexOfObject:match.currentParticipant] + 1;
    NSString *statusString = [NSString stringWithFormat:
                              @"Player %d's Turn (that's you)", playerNum];
    statusLabel.text = statusString;
    textInputField.enabled = YES;
    if ([match.matchData bytes]) {
        NSString *storySoFar = [NSString stringWithUTF8String:
                                [match.matchData bytes]];
        mainTextController.text = storySoFar;
        [self checkForEnding:match.matchData];
    }
}

-(void)layoutMatch:(GKTurnBasedMatch *)match {
    NSLog(@"Viewing match where it's not our turn...");
    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        statusString = @"Match Ended";
    } else {
        int playerNum = [match.participants
                         indexOfObject:match.currentParticipant] + 1;
        statusString = [NSString stringWithFormat:
                        @"Player %d's Turn", playerNum];
    }
    statusLabel.text = statusString;
    textInputField.enabled = NO;
    NSString *storySoFar = [NSString stringWithUTF8String:
                            [match.matchData bytes]];
    mainTextController.text = storySoFar;
    [self checkForEnding:match.matchData];
}


-(void)sendNotice:(NSString *)notice forMatch:
(GKTurnBasedMatch *)match {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:
                       @"Another game needs your attention!" message:notice
                                                delegate:self cancelButtonTitle:@"Sweet!"
                                       otherButtonTitles:nil];
    [av show];
}
-(void)checkForEnding:(NSData *)matchData {
    if ([matchData length] > 3000) {
        statusLabel.text = [NSString stringWithFormat:
                            @"%@, only about %d letter left", statusLabel.text,
                            4000 - [matchData length]];
    }
}

-(void)recieveEndGame:(GKTurnBasedMatch *)match {
    [self layoutMatch:match];
}
@end

