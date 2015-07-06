//
//  main.m
//  ImiPhone_CFSocketServer
//
//  Created by  on 12/2/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CFSocket.h>
#include <sys/socket.h>
#include <netinet/in.h>

void receiveData(CFSocketRef s, 
                 CFSocketCallBackType type, 
                 CFDataRef address, 
                 const void *data, 
                 void *info);

void sendData(CFSocketRef s,
                 CFSocketCallBackType type,
                 CFDataRef address,
                 const void *data,
                 void *info);

void acceptConnection(CFSocketRef s, 
                      CFSocketCallBackType type, 
                      CFDataRef address, 
                      const void *data, 
                      void *info);
void broadcast(NSString* message, CFDataRef address);
NSString* sendPrivate(NSString* message, CFDataRef address, NSString* sender_name,CFSocketRef);
void sendMemberList(CFDataRef);
bool checkPrivate(NSString *mes);
CFSocketRef getReceiveSocket(NSString *name);
NSMutableArray *socketArray;
NSMutableArray *addressArray;


int main (int argc, const char * argv[])
{

    @autoreleasepool {
        struct sockaddr_in sin;
        int sock, yes = 1;
        CFSocketRef s;
        CFRunLoopSourceRef source;
        socketArray = [[NSMutableArray alloc] init];
        
        //create a new socket
        sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        memset(&sin, 0, sizeof(sin));
        sin.sin_family = AF_INET;
        sin.sin_port = htons(6666); //port number
        
        //re-use the port or address when rerun the socket without error message
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, 
                   &yes, sizeof(yes));
        setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, 
                   &yes, sizeof(yes));

        //Check if the port is available
        if( bind(sock, (struct sockaddr *)&sin, sizeof(sin)) == -1){
            perror("bind");
            exit(1);
        }
        
        //Check if there is connection. limit 5 connection in listenning queue 
        listen(sock, 5);
        
        //Create a CFSocket object along with acceptConnection callback function
        s = CFSocketCreateWithNative(NULL, sock, 
                                     kCFSocketAcceptCallBack, 
                                     acceptConnection, 
                                     NULL);
        
        //Wait Message ...
        NSLog(@"socket %d Waiting for connection",sock);
        // Your code
        
        
        //Create a Run Loop source for CFSocket, and add it in the Current Run Loop
        source = CFSocketCreateRunLoopSource(NULL, s, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source,
                           kCFRunLoopDefaultMode);
        CFRelease(source);
        CFRelease(s);
        CFRunLoopRun();
        
    }
    return 0;
}

void receiveData(CFSocketRef s, 
                 CFSocketCallBackType type, 
                 CFDataRef address, 
                 const void *data, 
                 void *info)  
{
    CFDataRef df = (CFDataRef) data;
    int len = (int)CFDataGetLength(df);
    
    // Socket close handler
    if(len <= 0) {
        int sock = CFSocketGetNative(s);
        NSString *str = [[NSString alloc]initWithFormat:@"%d just leave the chat room.\n",sock];
        broadcast(str, address);
        for(int i=0;i<[socketArray count];i++)
        {
            CFSocketRef sn_temp = (CFSocketRef)[[socketArray objectAtIndex:i] pointerValue];
            int sock1 = CFSocketGetNative(sn_temp);
            if(sock == sock1){
                [socketArray removeObjectAtIndex:i];
                sendMemberList(address);
                break;
            }
        }
        return;
    }
    
    UInt8 buffer[len];
    for (int i=0; i<len; i++) {
        buffer[i]=0;
    }
    CFRange range = CFRangeMake(0,len);
    
    //Receiving Message...
    // Your code
    
    
    
    
    CFDataGetBytes(df, range, buffer);
    NSLog(@"Server received: %s from %d  \n", buffer, CFSocketGetNative(s) );   //print in console

    NSString* mes = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
    if(checkPrivate(mes))
    {
        NSString *receiver_name=[[NSString alloc] init];
        mes = [mes substringFromIndex:2];
        NSRange r = [mes rangeOfString:@" "];
        receiver_name = [mes substringToIndex:r.location];
        mes = [mes substringFromIndex:r.location];
        CFSocketRef receiver_socket = getReceiveSocket(receiver_name);
        if(receiver_socket != nil)
        {
            NSString* sender_name = [[NSString alloc]  initWithFormat:@"%d",CFSocketGetNative(s)];
            mes = sendPrivate(mes, address, sender_name ,receiver_socket);
            NSData *echo_message = [mes dataUsingEncoding:NSUTF8StringEncoding];
            CFDataRef message_data = CFDataCreate(NULL, [echo_message bytes], [echo_message length]);
            CFSocketSendData(s, address, message_data, 0);
        }
        else
        {
            NSString *cannot_find_mes = [[NSString alloc] initWithFormat:@"Can't find user %@", receiver_name];
            NSData *message = [cannot_find_mes dataUsingEncoding:NSUTF8StringEncoding];
            CFDataRef message_data = CFDataCreate(NULL, [message bytes], [message length]);
            CFSocketSendData(s, address, message_data, 0);
            NSLog(@"Can't find socket....");
        }
    }
    else
    {
        mes = [[NSString alloc] initWithFormat:@"%d:%@",CFSocketGetNative(s),mes];
        broadcast(mes, address);
    }
}

CFSocketRef getReceiveSocket(NSString *name)
{
    for(int i=0;i<[socketArray count];i++)
    {
        CFSocketRef s = (CFSocketRef)[[socketArray objectAtIndex:i] pointerValue];
        int k = CFSocketGetNative(s);
        if([[[NSString alloc]initWithFormat:@"%d",k] isEqualToString:name])
        {
            return s;
        }
    }
    return nil;
}



bool checkPrivate(NSString* mes)
{
    NSString* str = [[NSString alloc]init];
    if(mes.length > 2)
    {
        str = [mes substringToIndex:2];
        if([str isEqualToString:@"//"])
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
    return false;
    }
}


NSString* sendPrivate(NSString* mes, CFDataRef address, NSString* sender_name,CFSocketRef receiver)
{
    mes = [[NSString alloc] initWithFormat:@"(PRIVATE)%@:%@",sender_name,mes];
    NSData *message = [mes dataUsingEncoding:NSUTF8StringEncoding];
    CFDataRef message_data = CFDataCreate(NULL, [message bytes], [message length]);
    CFSocketSendData(receiver, address, message_data, 0);
    return mes;
}

void broadcast(NSString* mes, CFDataRef address)
{
    NSData *message = [mes dataUsingEncoding:NSUTF8StringEncoding];
    CFDataRef message_data = CFDataCreate(NULL, [message bytes], [message length]);
    for(int i=0;i<[socketArray count];i++)
    {
        CFSocketRef sn_temp = (CFSocketRef)[[socketArray objectAtIndex:i] pointerValue];
        CFSocketSendData(sn_temp, address, message_data, 0);
    }
    CFRelease(message_data);
}

void acceptConnection(CFSocketRef s, 
                      CFSocketCallBackType type, 
                      CFDataRef address, 
                      const void *data, 
                      void *info)  
{
    //retieve child socket
    CFSocketNativeHandle csock = *(CFSocketNativeHandle *)data;
    CFSocketRef sn;
    CFRunLoopSourceRef source;  
    
    //Accepting Message ...
    // Your code
    NSLog(@"socket %d Received connection socket %d",CFSocketGetNative(s),csock);

    //Create a CFSopcket object along with receiveData call back function
    sn = CFSocketCreateWithNative(NULL, csock,
                                  kCFSocketDataCallBack,
                                  receiveData, 
                                  NULL);
    int senderId = CFSocketGetNative(sn);
    NSValue *Id = [NSValue valueWithPointer:sn];
    [socketArray addObject:Id];
    NSString *str = [[NSString alloc]initWithFormat:@"%d just entered the chat room.\n",senderId];
    broadcast(str, address);
        sendMemberList(address);
    
    //[addressArray addObject:(__bridge id)(address)];
    //Registor the source to Run Loop
    source = CFSocketCreateRunLoopSource(NULL, sn, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source,
                       kCFRunLoopDefaultMode);
    //release
    CFRelease(source);
    CFRelease(sn);
}

void sendMemberList(CFDataRef address)
{
    NSString *mes = [[NSString alloc] initWithFormat:@"*#"];
    NSString *mes_temp = [[NSString alloc] init];
    for (int i=0; i<[socketArray count]; i++) {
        CFSocketRef sn_temp = (CFSocketRef)[[socketArray objectAtIndex:i] pointerValue];
        mes_temp =  [[NSString alloc] initWithFormat:@"%d$",CFSocketGetNative(sn_temp)];
        mes = [[NSString alloc] initWithFormat:@"%@%@",mes,mes_temp];
    
    }
    broadcast(mes, address);
}
