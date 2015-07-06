//
//  ViewController.h
//  EchoClient
//
//  Created by Lee Joe on 5/11/15.
//  Copyright (c) 2015 Lee Joe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CFSocket.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

@interface ViewController : UIViewController
@property (nonatomic,strong) IBOutlet UITextView *myTextView;
@property (nonatomic,strong) IBOutlet UIScrollView *onlineMemberView;
@property (nonatomic,strong) IBOutlet UITextField *myTextField;
-(IBAction) connectClicked:(id)sender;
-(IBAction)sendClicked:(id)sender;
-(void)memberButtonClicked:(id)sender;

void receiveData(CFSocketRef s,CFSocketCallBackType type,CFDataRef address,const void *data,void *info);

@end

