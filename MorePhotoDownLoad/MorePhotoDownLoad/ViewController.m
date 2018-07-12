//
//  ViewController.m
//  MorePhotoDownLoad
//
//  Created by FortyZhang on 2018/7/5.
//  Copyright © 2018年 FortyZhang. All rights reserved.
//

#import "ViewController.h"
#import "myImageCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSArray *urlArray;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableDictionary *operationsDic;
@property (nonatomic, strong) NSCache *imagesCache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myTableView.delegate = self;
    self.myTableView.dataSource = self;
    self.myTableView.estimatedRowHeight = 100;
    UINib *nib = [UINib nibWithNibName:@"myImageCell" bundle:nil];
    [self.myTableView registerNib:nib forCellReuseIdentifier:@"myImageCell"];
    
    NSString *imageStr0 = @"https://ss3.baidu.com/9fo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=f60add2afc1f3a2945c8d3cea924bce3/fd039245d688d43ffdcaed06711ed21b0ff43be6.jpg";
    NSString *imageStr1 = @"https://ss3.baidu.com/9fo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=2f65b68d9e58d109dbe3afb2e159ccd0/b7fd5266d0160924592977e8d80735fae6cd3431.jpg";
    NSString *imageStr2 = @"https://ss3.baidu.com/-fo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=fb8af6169d2397ddc9799e046983b216/0823dd54564e92584fbb491f9082d158cdbf4eb0.jpg";
    NSString *imageStr3 = @"https://ss0.baidu.com/-Po3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=61c889fe00d79123ffe092749d355917/48540923dd54564e39103dcfbfde9c82d0584fcb.jpg";
    NSString *imageStr4 = @"https://ss1.baidu.com/9vo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=ff1d01f98b94a4c21523e12b3ef51bac/a8773912b31bb051d18c53de3a7adab44bede098.jpg";
    NSString *imageStr5 = @"https://ss1.baidu.com/9vo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=d31d7aca77f40ad10ae4c1e3672d1151/d439b6003af33a8730364de8ca5c10385243b5ed.jpg";
    NSString *imageStr6 = @"https://ss3.baidu.com/-fo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=0236ec87e7f81a4c3932eac9e72b6029/2e2eb9389b504fc2db67eef6e9dde71190ef6d0c.jpg";
    NSString *imageStr7 = @"https://ss1.baidu.com/9vo3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=82503949dd58ccbf04bcb33a29d9bcd4/aa18972bd40735fad743de4292510fb30e24089d.jpg";
    NSString *imageStr8 = @"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2459584015,600700003&fm=27&gp=0.jpg";

    
    self.urlArray = @[imageStr0,imageStr1,imageStr2,imageStr3,imageStr4,imageStr5,imageStr6,imageStr7,imageStr8];
    self.operationsDic = [[NSMutableDictionary alloc] init];
    self.imagesCache = [[NSCache alloc] init];
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue setMaxConcurrentOperationCount:3];
    
}
    
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.urlArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    myImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myImageCell" forIndexPath:indexPath];
    [self downLoadImageIndexPath:indexPath.row cell:cell];
    return cell;
}

- (void)downLoadImageIndexPath:(NSInteger)integer cell:(myImageCell *)cell{
    
    //先判断内存是否有图片
    NSString *imageID = self.urlArray[integer];
    UIImage *image = [self.imagesCache objectForKey:imageID];
    
    if (image) {
        cell.imageV.image = image;
        NSLog(@"有缓存，直接调用-------%ld",integer);
        return;
    }
    else{
        
        //获取沙盒路径
        NSString *caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        //NSString *fileName = [imageID lastPathComponent]; 获取url最后一个path
        NSArray *fileNameArray = [imageID componentsSeparatedByString:@".com"];
        NSString *strurl = [fileNameArray lastObject];
        NSString *fileName = [strurl stringByReplacingOccurrencesOfString:@"/" withString:@"TY"];//将/替换成TY
        
        //拼接图片地址
        NSString *imagePath = [caches stringByAppendingPathComponent:fileName];
        //NSLog(@"获取沙盒路径为:%@",imagePath);
        NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
        //如果有，使用本地缓存
        if (imageData) {
            UIImage *myImage = [UIImage imageWithData:imageData];
            [self.imagesCache setObject:myImage forKey:imageID];
            cell.imageV.image = myImage;
            NSLog(@"沙盒中有，直接调用------%ld",integer);
            return;
        }
        
        //如果没有,调用网络
        NSBlockOperation *blockOperation = self.operationsDic[imageID];
        //判断图片下载任务是否已经在队列中,防止重复添加任务
        if (blockOperation){
            NSLog(@"下载任务已经在队列中-----%ld",integer);
            return;
        }
        else{
            //异步下载
            blockOperation = [NSBlockOperation blockOperationWithBlock:^{
                
                NSLog(@"开始下载～～～～～～---%ld",integer);
                NSURL *url = [NSURL URLWithString:imageID];
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *nowImage = [UIImage imageWithData:data];
                
                //下载成功
                if (nowImage) {
                    //存到内存字典中
                    [self.imagesCache setObject:nowImage forKey:imageID];
                    NSLog(@"成功downLoad··--%ld",integer);
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //在主线程中，刷新当前cell
                        NSIndexPath *myPath = [NSIndexPath indexPathForRow:integer inSection:0];
                        [self.myTableView reloadRowsAtIndexPaths:@[myPath] withRowAnimation:UITableViewRowAnimationFade];
                    }];
                    //存到沙盒中
                    [data writeToFile:imagePath atomically:YES];
                    //下载完成，将任务移除
                    [self.operationsDic removeObjectForKey:imageID];
                }
                else{
                    //下载失败，把任务移除，为了可以进行重新下载
                    [self.operationsDic removeObjectForKey:imageID];
                }
            }];
            
            //将当前下载操作添加到下载操作缓存中 (为了解决重复下载)
            [self.operationsDic setObject:blockOperation forKey:imageID];
            //添加下载操作到队列
            [self.queue addOperation:blockOperation];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
