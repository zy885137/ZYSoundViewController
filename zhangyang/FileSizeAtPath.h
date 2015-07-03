//
//  FileSizeAtPath.h
//  zhangyang
//
//  Created by zhangyang@ifensi.com on 14-6-6.
//  Copyright (c) 2014年 zhangyang@ifensi.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileSizeAtPath : NSObject
/**
 * 单个文件的大小
 */
- (long long) fileSizeAtPath:(NSString*) filePath;
/**
 * 遍历文件夹获得文件夹大小，返回多少M
 */
- (float) folderSizeAtPath:(NSString*) folderPath;
@end
