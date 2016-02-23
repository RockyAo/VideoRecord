//
//  ViewController.m
//  VideoRecord
//
//  Created by ZCBL on 16/2/23.
//  Copyright © 2016年 ZCBL. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>


#define TIMER_INTERVAL 0.05
#define VIDEO_RECORDER_MAX_TIME 10
#define VIDEO_RECORDER_MIN_TIME 5
#define ANIMATION_TIME 0.25f
#define KMainScreenW [UIScreen mainScreen].bounds.size.width
#define KMainScreenH [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIButton *takeVideoButton;

@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  视频输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  声音输入
 */
@property (nonatomic, strong) AVCaptureDeviceInput* audioInput;
/**
 *  视频输出流
 */
@property(nonatomic,strong)AVCaptureMovieFileOutput *movieFileOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;
/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;
/**
 *  加速度管理者
 */
@property (nonatomic, strong) CMMotionManager* motionManager;
/**
 *  记录录制时间
 */
@property (nonatomic, strong) NSTimer* timer;
/**
 *  记录方向
 */
@property (nonatomic, assign) UIInterfaceOrientation cameraOrientation;
/**
 *  点击拍照或者录制的时候的屏幕方向
 */
@property(nonatomic,assign)UIInterfaceOrientation endCamerOrientation;


@end

@implementation ViewController

#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - private mehtod
- (void)initAVCaptureSession{
    

    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    
    if (error) {
        NSLog(@"%@",error);
    }

    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canAddInput:self.audioInput]) {
        
        [self.session addInput:self.audioInput];
    }
    
    if ([self.session canAddOutput:self.movieFileOutput]) {
        
        [self.session addOutput:self.movieFileOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    //    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    
    self.previewLayer.frame = CGRectMake(0, 0,KMainScreenW, KMainScreenH);
    self.backView.layer.masksToBounds = YES;
    [self.backView.layer addSublayer:self.previewLayer];
    
}



#pragma mark - response method
- (IBAction)takeVideoButtonPress:(UILongPressGestureRecognizer *)sender {
    
    
}

#pragma 缩放手势
- (IBAction)zoomControll:(UIPinchGestureRecognizer *)sender {
}

#pragma mark - getter and setter

@end
