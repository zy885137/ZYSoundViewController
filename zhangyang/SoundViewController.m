//
//  SoundViewController.m
//  Sound
//
//  Created by 张杨 on 13-4-10.
//  Copyright (c) 2013年 张杨. All rights reserved.
//

#import "SoundViewController.h"
#import "lame.h"
#import "AFNetworking.h"
#import "FileSizeAtPath.h"

@interface SoundViewController ()
{
    // AFN的客户端，使用基本地址初始化，同时会实例化一个操作队列，以便于后续的多线程处理
    AFHTTPClient        *_httpClient;
    NSOperationQueue    *_queue;
    NSString            *_mp3FilePath;
}
@end

@implementation SoundViewController
@synthesize player;
@synthesize recordedFile;

-(void)dealloc
{
    [player release];
    [recordedFile release];
    [super dealloc];
}

- (void)audio_PCMtoMP3
{
    NSString *cafFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
        
    _mp3FilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.mp3"];
 
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if([fileManager removeItemAtPath:_mp3FilePath error:nil])
    {
        NSLog(@"删除");
    }
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([_mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 8000.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        [playButton setEnabled:YES];
        NSError *playerError;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[[NSURL alloc] initFileURLWithPath:_mp3FilePath] autorelease] error:&playerError];
        self.player = audioPlayer;
        player.volume = 1.0f;
        if (player == nil)
        {
            NSLog(@"ERror creating player: %@", [playerError description]);
        }
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
        player.delegate = self;
        [audioPlayer release];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"http://api.starapp.ifensi.com/index.php/Fensinews/addtucao/"];
    _httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    _queue = [[NSOperationQueue alloc] init];
    
    UIButton *makeSoundButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 100, 200, 50)];
    makeSoundButton.backgroundColor = [UIColor blueColor];
    [makeSoundButton setTitle:@"按下录音" forState:UIControlStateNormal];
    [makeSoundButton setTitle:@"松开录制完成" forState:UIControlStateHighlighted];
    [makeSoundButton addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
    [makeSoundButton addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:makeSoundButton];
    [makeSoundButton release];
    
    UIButton *pButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 160, 150, 50)];
    playButton = pButton;
    [playButton setEnabled:NO];
    playButton.backgroundColor = [UIColor greenColor];
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    [pButton release];
    
    UIButton *zButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 230, 100, 50)];
    zButton.backgroundColor = [UIColor blackColor];
    [zButton setTitle:@"转mp3" forState:UIControlStateNormal];
    [zButton addTarget:self action:@selector(audio_PCMtoMP3) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:zButton];
    [zButton release];
    
    UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 200, 50)];
    deleteBtn.backgroundColor = [UIColor redColor];
    [deleteBtn setTitle:@"删除缓存" forState:UIControlStateNormal];
    [deleteBtn addTarget:self action:@selector(deleteDataCache) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteBtn];
    [deleteBtn release];
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/downloadFile.caf"];
    self.recordedFile = [[[NSURL alloc] initFileURLWithPath:path] autorelease];
//    NSLog(@"%@",recordedFile);
    

}
#pragma mark 清理缓存
- (void)deleteDataCache
{
    dispatch_async(
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                   , ^{
                       NSString *cachPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                       FileSizeAtPath *fileSize = [[FileSizeAtPath alloc]init];
//                       NSString *cachPath = NSHomeDirectory();
                       NSLog(@"cachPath :%f",[fileSize folderSizeAtPath:cachPath]);
                       
                       NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:cachPath];
//                       NSLog(@"files :%d",[files count]);
                       for (NSString *p in files) {
                           NSError *error;
                           NSString *path = [cachPath stringByAppendingPathComponent:p];
                           if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                               [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                           }
                       }
                       [self performSelectorOnMainThread:@selector(clearCacheSuccess) withObject:nil waitUntilDone:YES];});
    
}

-(void)clearCacheSuccess
{
    NSLog(@"清理成功");
}
- (void)playPause
{
    //If the track is playing, pause and achange playButton text to "Play"
    if([player isPlaying])
    {
        [player pause];
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    //If the track is not player, play the track and change the play button to "Pause"
    else
    {
        [player play];
        [playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

-(void)touchDown
{
    [playButton setEnabled:NO];
    
    session = [AVAudioSession sharedInstance];

    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
    
    //录音设置
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [settings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [settings setValue :[NSNumber numberWithFloat:8000.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [settings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [settings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    
    recorder = [[AVAudioRecorder alloc] initWithURL:recordedFile settings:settings error:nil];
    [recorder prepareToRecord];
    [recorder record];
    [settings release];
}
-(void)touchUp
{
    [recorder stop];
    
    if(recorder)
    {
        [self audio_PCMtoMP3];
        NSLog(@"---mp3FilePath----%@",_mp3FilePath);
        NSLog(@"-----总时间--%.1f", self.player.duration);
    
        NSString * durations = [NSString stringWithFormat:@"%.1f",self.player.duration];
        // . 上传请求POST
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setObject:@"147" forKey:@"uid"];
        [param setObject:@"1475955" forKey:@"articleid"];
        [param setObject:durations forKey:@"audiolength"];
        
        NSURLRequest *request = [_httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:param constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            
            NSData *data = [NSData dataWithContentsOfFile:_mp3FilePath];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            // 设置时间格式
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            NSString *fileName = [NSString stringWithFormat:@"%@.mp3", str];
            
            [formData appendPartWithFileData:data name:@"audio" fileName:fileName mimeType:@"audio/basic"];
        }];
        
        // 3. operation包装的urlconnetion
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"上传完成");
            NSLog(@"resault = %@",responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"上传失败->%@", error);
        }];
        
        [_httpClient.operationQueue addOperation:op];
        [recorder release];
        recorder = nil;
    }
    
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [playButton setTitle:@"Play" forState:UIControlStateNormal];
}
@end
