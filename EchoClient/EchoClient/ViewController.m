//
//  ViewController.m
//  EchoClient
//
//  Created by Lee Joe on 5/11/15.
//  Copyright (c) 2015 Lee Joe. All rights reserved.
//

#import "ViewController.h"

UITextView *mTextViewAlias;
UIScrollView *onlineMemberViewAlias;

CFSocketRef s;

NSString* chatLog;
NSMutableArray* onlineMemList;
UIViewController* vc;

void updateMemberListView()
{
    for(UIView *view in [onlineMemberViewAlias subviews])
    {
        [view removeFromSuperview];
    }
    NSString *memberList=[[NSString alloc]init];
    for (int i=0; i<[onlineMemList count]; i++) {
        memberList = [[NSString alloc] initWithFormat:@"%@\n%@",memberList,[onlineMemList objectAtIndex:i]];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake( 0 , i*16, 15, 30);
        button.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [button setTitle:[NSString stringWithFormat:@"%@",[onlineMemList objectAtIndex:i]] forState:normal];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        [button addTarget:vc action: @selector(memberButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        //[self.question_button_list addObject:button];
        [onlineMemberViewAlias addSubview:button];
        
        
    }
    //onlineMemberViewAlia = memberList;
}




NSString* getMemberList(NSString *str)
{
    onlineMemList = [[NSMutableArray alloc]init];
    NSString *str_left;
    if([str rangeOfString:@"*#"].location != NSNotFound)
    {
        NSRange range1 = [str rangeOfString:@"*#"];
        str_left = [str substringToIndex:range1.location];
        str = [str substringFromIndex:range1.location+2];
        
        while ([str rangeOfString:@"$"].location != NSNotFound) {
            
            NSRange range = [str rangeOfString:@"$"];
            NSString *str1 = [[NSString alloc] init];
            str1 = [str substringToIndex:range.location];
            [onlineMemList addObject:str1];
            NSLog(@"%@",str1);
            str = [str substringFromIndex:range.location+1];
            NSLog(@"%@",str);
        }
        updateMemberListView();
        return str_left;
    }
    else
    {
        return str;
    }
}



void chatLogUpdate(NSString* str)
{
    chatLog = [[NSString alloc] initWithFormat:@"%@%@",chatLog,str];
}



void receiveData(CFSocketRef s,
                 CFSocketCallBackType type,
                 CFDataRef address,
                 const void *data,
                 void *info)
{
    CFDataRef df = (CFDataRef) data;
    int len =  (int)CFDataGetLength(df);
    if(len <= 0){
        NSLog(@"Can not Connect to Server for any reason.");
        return;
    };
    
    CFRange range = CFRangeMake(0,len);
    UInt8 buffer[len];
    
    //recv message
    NSLog(@"Received %d bytes from socket %d\n",
          len, CFSocketGetNative(s));
    
    CFDataGetBytes(df, range, buffer);
    NSLog(@"Client received: %s\n", buffer);
    NSString *mes = [[NSString alloc] initWithFormat:@"%s\n",buffer];
        chatLogUpdate(getMemberList(mes));

    mTextViewAlias.text = chatLog;
}



@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    chatLog = [[NSString alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




-(IBAction) connectClicked:(id)sender{
    UIButton *uiButton = (UIButton *) sender;
    [uiButton setEnabled: NO];
    
    mTextViewAlias = self.myTextView;    //point mTextViewAlias to myTextView
    onlineMemberViewAlias = self.onlineMemberView;
    vc = self;
    
    s = CFSocketCreate(NULL, PF_INET,
                       SOCK_STREAM, IPPROTO_TCP,
                       kCFSocketDataCallBack,
                       receiveData,
                       NULL);
    
    struct sockaddr_in      sin;
    struct hostent          *host;
    
    memset(&sin, 0, sizeof(sin));
    host = gethostbyname("localhost");
    memcpy(&(sin.sin_addr), host->h_addr,host->h_length);
    
    sin.sin_family = AF_INET;
    sin.sin_port = htons(6666);
    
    CFDataRef address;
    CFRunLoopSourceRef source;
    
    address = CFDataCreate(NULL, (UInt8 *)&sin, sizeof(sin));
    CFSocketConnectToAddress(s, address, 0);
    
    // Connecting message
    printf("Connect to socket %d\n",CFSocketGetNative(s));
    mTextViewAlias.text = @"You just enter the chat room.";
    
    
    CFRelease(address);
    
    source = CFSocketCreateRunLoopSource(NULL, s, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       source,
                       kCFRunLoopDefaultMode);
    CFRelease(source);
    CFRunLoopRun();
}

-(IBAction) sendClicked:(id)sender{
    //    UInt8 message[] = "Hello world";
    NSData *message = [self.myTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    CFDataRef message_data = CFDataCreate(NULL, [message bytes], [message length]);
    CFSocketSendData(s, NULL, message_data, 0);
    CFRelease(message_data);
}

-(void)memberButtonClicked:(UIButton*)sender
{
    self.myTextField.text = [NSString stringWithFormat:@"//%@ ",[[sender titleLabel]text]];
}
@end


