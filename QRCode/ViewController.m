//
//  ViewController.m
//  QRCode
//
//  Created by Nikolay on 03.03.16.
//  Copyright © 2016 Nikolay. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic) BOOL isReading;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

-(BOOL)startReading;

-(void)stopReading;
-(void)loadBeepSound;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isReading =NO;
    self.captureSession = nil;

    [self loadBeepSound];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

-(IBAction)startStopReading:(id)sender{
    if (!self.isReading) {
        if ([self startReading]) {
            [self.buttonStart setTitle:@"Stop"];
            [self.lblStatus setText:@"Scanning for QR Code..."];
        }
    } else {
        [self stopReading];
        [self.buttonStart setTitle:@"Start"];
    }
    
    self.isReading =!self.isReading;
}

-(BOOL)startReading{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                        error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    self.captureSession = [[AVCaptureSession alloc]init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self
                                                queue:dispatchQueue];
    
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, nil]];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.viewPerview.layer.bounds];
    [self.viewPerview.layer addSublayer:self.videoPreviewLayer];
    
    [self.captureSession startRunning];
    
    return YES;
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self.lblStatus performSelectorOnMainThread:@selector(setText:)
                                         withObject:[metadataObj stringValue]
                                          waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(stopReading)
                                   withObject:nil
                                waitUntilDone:NO];
            [self.buttonStart performSelectorOnMainThread:@selector(setTitle:)
                                               withObject:@"Start"
                                            waitUntilDone:NO];
            self.isReading = NO;
            
            if (self.audioPlayer) {
                [self.audioPlayer play];
            }
        }
    }
}

-(void)stopReading{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    [self.videoPreviewLayer removeFromSuperlayer];
}

-(void)loadBeepSound{
    NSString *beepFilePath = [[NSBundle mainBundle]pathForResource:@"beep" ofType:@"mp3"];
    NSURL *beepURL = [NSURL URLWithString:beepFilePath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL
                                                              error:&error];
    if (error) {
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    } else {
        [self.audioPlayer prepareToPlay];
    }
}
@end
