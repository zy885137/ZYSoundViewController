//
//  SoundViewController.h
//  Sound
//
//  Created by 张杨 on 13-4-10.
//  Copyright (c) 2013年 张杨. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SoundViewController : UIViewController<AVAudioPlayerDelegate,AVAudioSessionDelegate>
{
    UIButton        *playButton;
    AVAudioSession  *session;
    NSURL           *recordedFile;
    AVAudioPlayer   *player;
    AVAudioRecorder *recorder;
}
@property (nonatomic , retain) AVAudioPlayer    *player;
@property (nonatomic , retain) NSURL            *recordedFile;
@end
