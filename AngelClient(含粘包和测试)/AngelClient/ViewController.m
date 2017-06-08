//
//  ViewController.m
//  AngelClient
//
//  Created by lby on 16/12/29.
//  Copyright © 2016年 lby. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
// 客户端socket
@property (strong, nonatomic) GCDAsyncSocket *clientSocket;
@property (weak, nonatomic) IBOutlet UITextField *addressTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;
@property (weak, nonatomic) IBOutlet UITextView *showMessageTF;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) NSTimer *connectTimer; // 计时器
@property (nonatomic, assign) double startCreateTime; // 开始创建时间
@property (nonatomic, assign) double createdTime; // 完成创建的时间
@property (nonatomic, assign) double startConnectTime; // 准备连接的时间
@property (nonatomic, assign) double connectedTime; // 成功连接的时间
@property (nonatomic, copy) NSString *time1; // 准备创建客户端socket的时间
@property (nonatomic, copy) NSString *time2; // 完成创建的时间
@property (nonatomic, copy) NSString *time3; // 准备连接的时间
@property (nonatomic, copy) NSString *time4; // 成功连接的时间
@property (nonatomic, copy) NSString *timeBeat;// 心跳时间
@property (nonatomic, copy) NSString *receiveTime; // 收到的时间
@property (nonatomic, copy) NSString *separatedTime;// 拆分的时间
@property (nonatomic, copy) NSString *circulateTime;// 循环遍历的时间
@property (nonatomic, copy) NSString *stopTime;// 停止的时间
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// 开始连接
- (IBAction)connectAction:(id)sender
{
    // 连接服务器
    if (!self.connected)
    {
        self.time1 = [self getCurrentSecond];
        NSLog(@"准备创建客户端socket:%@",self.time1);
        self.startCreateTime = [self strToDouble:self.time1];
        // 准备创建客户端socket
        NSError *error = nil;
        self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.time2 = [self getCurrentSecond];
        NSLog(@"完成创建:%@",self.time2);
        self.createdTime = [self strToDouble:self.time2];
        
        self.time3 = [self getCurrentSecond];
        NSLog(@"准备连接:%@",self.time3);
        self.startConnectTime = [self strToDouble:self.time3];
        // 开始连接服务器
        self.connected = [self.clientSocket connectToHost:self.addressTF.text onPort:self.portTF.text.integerValue viaInterface:nil withTimeout:-1 error:&error];
        if(self.connected)
        {
            [self showMessageWithStr:@"客户端尝试连接"];
        }
        else
        {
            self.connected = NO;
            [self showMessageWithStr:@"客户端未创建连接"];
        }
    }
    else
    {
        [self showMessageWithStr:@"与服务器连接已建立"];
    }
}

// 发送消息
- (IBAction)sendMessageAction:(id)sender
{
//    NSLog(@"客户端开始发送的时间%@",[self getCurrentSecond]);
    NSString *allMes = [NSString stringWithFormat:@"ab%@",self.messageTF.text];
    
    NSData *data = [allMes dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

- (void)addTimer
{
    //    NSLog(@"定时器开启时间%@",[self getCurrentSecond]);
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

// 心跳连接
- (void)longConnectToSocket
{
    NSLog(@"心跳发送%s",__func__);
    NSString *strName = [self getDeviceName];
    NSString *longConnect = [NSString stringWithFormat:@"ab%@",strName];
    
    NSData  *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

#pragma mark - GCDAsyncSocketDelegate
//连接主机对应端口
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    self.time4 = [self getCurrentSecond];
    NSLog(@"准备连接:%@",self.time4);
    self.connectedTime = [self strToDouble:self.time4];
    // 连接上服务器
    [self showMessageWithStr:@"连接成功"];
    
    // 发送给服务器 time1
    NSString *createStr = [NSString stringWithFormat:@"abLink-设备:%@-客户端准备创建:%@",[self getDeviceName],self.time1];
    NSData *createData = [createStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:createData withTimeout:- 1 tag:0];
    
    // 发送给服务器 time2
    NSString *createdStr = [NSString stringWithFormat:@"abLink-设备:%@-客户端完成创建:%@",[self getDeviceName],self.time2];
    NSData *createdData = [createdStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:createdData withTimeout:- 1 tag:0];
    
    // 发送给服务器 客户端创建socket耗时
    NSString *createDuringStr = [NSString stringWithFormat:@"abLink-设备:%@-创建socket耗时:%.0f毫秒",[self getDeviceName],(self.createdTime - self.startCreateTime) * 1000];
    NSData *createDuringData = [createDuringStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:createDuringData withTimeout:- 1 tag:0];
    
    // 发送给服务器 time3
    NSString *starConnectStr = [NSString stringWithFormat:@"abLink-设备:%@-客户端准备连接:%@",[self getDeviceName],self.time3];
    NSData *starConnectData = [starConnectStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:starConnectData withTimeout:- 1 tag:0];
    
    // 发送给服务器 time4
    NSString *connectedStr = [NSString stringWithFormat:@"abLink-设备:%@-成功连接%@",[self getDeviceName],self.time4];
    NSData *connectedData = [connectedStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:connectedData withTimeout:- 1 tag:0];
    
    // 发送给服务器 客户端连接上服务器socket耗时
    NSString *connectDuringStr = [NSString stringWithFormat:@"abLink-设备:%@-连上服务器socket耗时:%.0f毫秒",[self getDeviceName],(self.connectedTime - self.startConnectTime) * 1000];
    NSData *connectDuringData = [connectDuringStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:connectDuringData withTimeout:- 1 tag:0];
    
    [self addTimer];
//    连接后,可读取服务器端的数据
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
    self.connected = YES;
}

// 收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    self.receiveTime = [self getCurrentSecond];
    NSLog(@"客户端接收到数据的时间%@",self.receiveTime);
    
    NSString *getMessage = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray *messageArr = [getMessage componentsSeparatedByString:@"ab"];
    self.separatedTime = [self getCurrentSecond];
//    NSLog(@"根据ab拆分完数据的时间%@",self.separatedTime);
    for (int i = 1; i < messageArr.count; i++)
    {
        //测试
        self.circulateTime = [self getCurrentSecond];
//        NSLog(@"遍历解析完的数据%ld的时间%@",(long)i,self.circulateTime);
        
        NSString *allMes = [NSString stringWithFormat:@"abtime-设备:%@-客户端收到数据:%@",[self getDeviceName],self.receiveTime];
        NSData *dataTime = [allMes dataUsingEncoding:NSUTF8StringEncoding];
        [self.clientSocket writeData:dataTime withTimeout:- 1 tag:0];
    }
    // 读取到服务器数据值后也能再读取
    [self.clientSocket readDataWithTimeout:-1 tag:0];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
// 信息展示
- (void)showMessageWithStr:(NSString *)str
{
//    self.showMessageTF.text = [self.showMessageTF.text stringByAppendingFormat:@"%@\n", str];
        self.showMessageTF.text = str;
}

// 客户端socket
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    self.stopTime = [self getCurrentSecond];
    NSLog(@"客户端断开的时间%@",self.stopTime);
    [self showMessageWithStr:@"断开连接"];
//    NSLog(@"断开的sock:%@",self.clientSocket);
    self.clientSocket.delegate = nil;
//    [self.clientSocket disconnect];
    self.clientSocket = nil;
    self.connected = nil;
    [self.connectTimer invalidate];
}
- (NSString *)getCurrentTime    
{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTime = [date timeIntervalSince1970];
    NSString *currentTimeStr = [NSString stringWithFormat:@"%.3f", currentTime];
    return currentTimeStr;
}
- (NSString *)getCurrentSecond
{
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //    df.dateFormat = @"yyyy/MM/dd HH:mm:ss.SSS";
    df.dateFormat = @"HH:mm:ss.SSS";
    NSString *str = [df stringFromDate:date];
    return str;
}

// 获取设备名
- (NSString *)getDeviceName
{
    return [UIDevice currentDevice].name;
}

// 字符串转double
- (double)strToDouble:(NSString *)str
{
    return [[str substringWithRange:NSMakeRange(str.length - 6, 6)] doubleValue];
}

@end
