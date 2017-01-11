//
//  ViewController.m
//  YYMapNavi
//
//  Created by apple on 17/1/9.
//  Copyright © 2017年 yizooo. All rights reserved.
//

#import "ViewController.h"
#import <AMapNaviKit/AMapNaviKit.h>
#import "SpeechSynthesizer.h"
#import "MoreMenuView.h"
#import <AMapLocationKit/AMapLocationKit.h>
@interface ViewController ()<AMapNaviDriveManagerDelegate,AMapNaviDriveViewDelegate,MoreMenuViewDelegate,AMapLocationManagerDelegate>
//定位管理类
@property (nonatomic,strong) AMapLocationManager *locationManager;
//导航视图
@property (nonatomic,strong) AMapNaviDriveView *driveView;

//路线规划计算，导航类
@property (nonatomic,strong) AMapNaviDriveManager *driveManager;

@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;

@property (nonatomic, strong) MoreMenuView *moreMenu;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.locationManager = [[AMapLocationManager alloc] init];
    
    [self.locationManager setDelegate:self];
     [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    
    // 带逆地理信息的一次定位（返回坐标和地址信息）
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //   定位超时时间，最低2s，此处设置为2s
    self.locationManager.locationTimeout =2;
    //   逆地理请求超时时间，最低2s，此处设置为2s
    self.locationManager.reGeocodeTimeout = 2;
    [self startSerialLocation];
    
    [self initDriveView];
    
    [self initDriveManager];
    
    [self initMoreMenu];
    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
  
}
#pragma mark - Route Plan

- (void)calculateRoute
{
    //进行路径规划
    [self.driveManager calculateDriveRouteWithStartPoints:@[self.startPoint]
                                                endPoints:@[self.endPoint]
                                                wayPoints:nil
                                          drivingStrategy:AMapNaviDrivingStrategySingleDefault];
}
- (void)initDriveView
{
    if (self.driveView == nil)
    {
        self.driveView = [[AMapNaviDriveView alloc] initWithFrame:self.view.bounds];
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.driveView setDelegate:self];
        
        [self.view addSubview:self.driveView];
    }
}
- (void)initDriveManager
{
    if (self.driveManager == nil)
    {
        self.driveManager = [[AMapNaviDriveManager alloc] init];
        [self.driveManager setDelegate:self];
        
        [self.driveManager setAllowsBackgroundLocationUpdates:YES];
        [self.driveManager setPausesLocationUpdatesAutomatically:NO];
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        [self.driveManager addDataRepresentative:self.driveView];
    }
}
- (void)initMoreMenu
{
    if (self.moreMenu == nil)
    {
        self.moreMenu = [[MoreMenuView alloc] init];
        self.moreMenu.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        [self.moreMenu setDelegate:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
}

//初始化用户的位置和终点位置
- (void)initPropertiesWith:(CLLocation *)location
{
    //为了方便展示,选择了固定的起终点
    self.startPoint = [AMapNaviPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    self.endPoint   = [AMapNaviPoint locationWithLatitude:39.908791 longitude:116.321257];
}


#pragma mark  基础定位
- (void)startSerialLocation
{
    //开始定位
    [self.locationManager startUpdatingLocation];
}

- (void)stopSerialLocation
{
    //停止定位
    [self.locationManager stopUpdatingLocation];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error
{
    //定位错误
    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location
{
    //定位结果
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    [self initPropertiesWith:location];
      [self calculateRoute];
}
#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManager:(AMapNaviDriveManager *)driveManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //算路成功后开始GPS导航
    [self.driveManager startGPSNavi];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)driveManagerNeedRecalculateRouteForYaw:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForYaw");
}

- (void)driveManagerNeedRecalculateRouteForTrafficJam:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForTrafficJam");
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onArrivedWayPoint:(int)wayPointIndex
{
    NSLog(@"onArrivedWayPoint:%d", wayPointIndex);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)driveManagerDidEndEmulatorNavi:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"didEndEmulatorNavi");
}

- (void)driveManagerOnArrivedDestination:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onArrivedDestination");
}

#pragma mark - AMapNaviWalkViewDelegate

- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView
{
    //停止导航
    [self.driveManager stopNavi];
    [self.driveManager removeDataRepresentative:self.driveView];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)driveViewMoreButtonClicked:(AMapNaviDriveView *)driveView
{
    //配置MoreMenu状态
    [self.moreMenu setTrackingMode:self.driveView.trackingMode];
    [self.moreMenu setShowNightType:self.driveView.showStandardNightType];
    
    [self.moreMenu setFrame:self.view.bounds];
    [self.view addSubview:self.moreMenu];
}

- (void)driveViewTrunIndicatorViewTapped:(AMapNaviDriveView *)driveView
{
    NSLog(@"TrunIndicatorViewTapped");
}

- (void)driveView:(AMapNaviDriveView *)driveView didChangeShowMode:(AMapNaviDriveViewShowMode)showMode
{
    NSLog(@"didChangeShowMode:%ld", (long)showMode);
}

#pragma mark - MoreMenu Delegate

- (void)moreMenuViewFinishButtonClicked
{
    [self.moreMenu removeFromSuperview];
}

- (void)moreMenuViewNightTypeChangeTo:(BOOL)isShowNightType
{
    [self.driveView setShowStandardNightType:isShowNightType];
}

- (void)moreMenuViewTrackingModeChangeTo:(AMapNaviViewTrackingMode)trackingMode
{
    [self.driveView setTrackingMode:trackingMode];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
