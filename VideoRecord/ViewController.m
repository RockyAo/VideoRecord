//
//  ViewController.m
//  VideoRecord
//
//  Created by ZCBL on 16/2/23.
//  Copyright © 2016年 ZCBL. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ASProgressPopUpView.h"
#import "ASPopUpView.h"
#import "RAFileManager.h"

#import <AssetsLibrary/AssetsLibrary.h>

#define TIMER_INTERVAL 0.05
#define VIDEO_RECORDER_MAX_TIME 10 //视频最大时长 (单位/秒)
#define VIDEO_RECORDER_MIN_TIME 1  //最短视频时长 (单位/秒)

#define KMainScreenW [UIScreen mainScreen].bounds.size.width
#define KMainScreenH [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate,ASProgressPopUpViewDataSource,ASProgressPopUpViewDelegate,ASPopUpViewDelegate>

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
 *  记录录制时间
 */
@property (nonatomic, strong) NSTimer* timer;
//进度条
@property (nonatomic, strong) ASProgressPopUpView* progressView;
@end

@implementation ViewController{

    //时间长度
    CGFloat timeLength;
}

#pragma mark - life circle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initAVCaptureSession];
    
    [self.backView addSubview:self.progressView];
}

- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:YES];
    
    [self startSession];
}

- (void)viewWillDisappear:(BOOL)animated{

    [super viewWillDisappear:YES];
    
    [self stopSession];
}

#pragma mark - 视频输出
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{

    if (CMTimeGetSeconds(captureOutput.recordedDuration) < VIDEO_RECORDER_MIN_TIME) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频时间过短" message:nil delegate:self
    cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    
     NSLog(@"%s-- url = %@ ,recode = %f , int %lld kb", __func__, outputFileURL, CMTimeGetSeconds(captureOutput.recordedDuration), captureOutput.recordedFileSize / 1024);
    
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
    }];
}

#pragma mark - ASProgressDelegate

- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress{
    
    NSString *result = [NSString stringWithFormat:@"%.1f秒",progress*10];
    //    result = [result stringByReplacingOccurrencesOfString:@"." withString:@""];
    return result;
}

#pragma mark - private mehtod
- (void)initAVCaptureSession{
    

    self.session = [[AVCaptureSession alloc] init];
    
    //这里根据需要设置  可以设置4K
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
    [self.backView.layer insertSublayer:self.previewLayer atIndex:0];
    
}

- (void)startSession{

    if (![self.session isRunning]) {
        
        [self.session startRunning];
    }
}

- (void)stopSession{

    if ([self.session isRunning]) {
        
        [self.session stopRunning];
    }
}

- (void)timerFired{
    
    timeLength = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerRecord) userInfo:nil repeats:YES];
}
- (void)timerStop{
    
    if ([self.timer isValid]) {
        
        [self.timer invalidate];
        self.timer = nil;
    }
}
#pragma 视频名以当前日期为名
- (NSString*)getVideoSaveFilePathString
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString* nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    return nowTimeStr;
}

#pragma mark 开始录制和结束录制
- (void)startVideoRecorder{
    
    AVCaptureConnection *movieConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation avcaptureOrientation = AVCaptureVideoOrientationPortrait;
    [movieConnection setVideoOrientation:avcaptureOrientation];
    [movieConnection setVideoScaleAndCropFactor:1.0];
     NSURL *url = [[RAFileManager defaultManager] filePathUrlWithUrl:[self getVideoSaveFilePathString]];
    [self.movieFileOutput startRecordingToOutputFileURL:url recordingDelegate:self];
    [self timerFired];

}

- (void)stopVideoRecorder{
    
    
    [self.movieFileOutput stopRecording];
    [self timerStop];
    [self.progressView hidePopUpViewAnimated:YES];
    [self.progressView setProgress:0.0 animated:YES];
     self.progressView.hidden = YES;

}

#pragma  截图方法
- (UIImage *)videoSnap:(NSString *)videoPath{
    
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    CMTime snaptime = CMTimeMake(10, 10);
    CMTime time2;
    
    CGImageRef cgImageRef = [generator copyCGImageAtTime:snaptime actualTime:&time2 error:nil];
    
    UIImage *tempImage = [UIImage imageWithCGImage:cgImageRef];
    
    return tempImage;
}


#pragma mark - response method
- (IBAction)takeVideoButtonPress:(UILongPressGestureRecognizer *)sender {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
    
        return;
    }
    
    //判断用户是否允许访问麦克风权限
    authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        //无权限
      
        return;
    }
    
    

    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            [self startVideoRecorder];
            break;
        case UIGestureRecognizerStateCancelled:
            [self stopVideoRecorder];
            break;
        case UIGestureRecognizerStateEnded:
            [self stopVideoRecorder];
            break;
        case UIGestureRecognizerStateFailed:
            [self stopVideoRecorder];
            break;
        default:
            break;
    }

}

- (void)timerRecord{
    
    timeLength += TIMER_INTERVAL;
    self.progressView.hidden = NO;
    [self.progressView showPopUpViewAnimated:YES];
    [self.progressView setProgress:timeLength/VIDEO_RECORDER_MAX_TIME animated:YES];
    //    ZLog(@"%zd",(NSInteger)timeLength/VIDEO_RECORDER_MAX_TIME);
    if (timeLength/VIDEO_RECORDER_MAX_TIME >= 1.0) {
        
        [self stopVideoRecorder];
        
        [self timerStop];
    }
}

#pragma mark - getter and setter
- (ASProgressPopUpView *)progressView{
    
    if (!_progressView) {
        
        _progressView = [[ASProgressPopUpView alloc] init];
        _progressView.font = [UIFont systemFontOfSize:14.0f];
        _progressView.dataSource = self;
        _progressView.popUpViewAnimatedColors = @[[UIColor orangeColor]];
        _progressView.hidden = YES;
        _progressView.frame = CGRectMake(0, KMainScreenH - 90, KMainScreenW, 2);
    }
    return _progressView;
}

@end
