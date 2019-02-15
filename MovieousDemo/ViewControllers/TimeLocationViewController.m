//
//  TimeLocationViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/1.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "TimeLocationViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "UIView+Movieous.h"
#import "MSVEditor+Extentions.h"

@interface TimeLocationViewController ()
<
CLLocationManagerDelegate
>

@property (strong, nonatomic) IBOutlet UILabel *timeLocationALabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLocationBLabel;

@end

@implementation TimeLocationViewController {
    CLLocationManager *_locationManager;
    CLGeocoder *_geoC;
    MSVEditor *_editor;
}

- (void)viewWillAppear:(BOOL)animated {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;   //10米 精度
    _geoC = [CLGeocoder new];
    _editor = [MSVEditor sharedInstance];
    [self startLocating];
}

-(void)startLocating {
    if([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
        
        [_locationManager requestWhenInUseAuthorization];
    }
    
    [_locationManager startUpdatingLocation];   //开始定位
}

- (NSString *)translationArabicNum:(NSInteger)arabicNum {
    NSString *arabicNumStr = [NSString stringWithFormat:@"%ld",(long)arabicNum];
    NSArray *arabicNumeralsArray = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"0"];
    NSArray *chineseNumeralsArray = @[@"一",@"二",@"三",@"四",@"五",@"六",@"七",@"八",@"九",@"零"];
    NSArray *digits = @[@"个",@"十",@"百",@"千",@"万",@"十",@"百",@"千",@"亿",@"十",@"百",@"千",@"兆"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:chineseNumeralsArray forKeys:arabicNumeralsArray];
    if (arabicNum < 20 && arabicNum > 9) {
        if (arabicNum == 10) {
            return @"十";
        } else {
            NSString *subStr1 = [arabicNumStr substringWithRange:NSMakeRange(1, 1)];
            NSString *a1 = [dictionary objectForKey:subStr1];
            NSString *chinese1 = [NSString stringWithFormat:@"十%@",a1];
            return chinese1;
        }
    } else {
        NSMutableArray *sums = [NSMutableArray array];
        for (int i = 0; i < arabicNumStr.length; i ++) {
            NSString *substr = [arabicNumStr substringWithRange:NSMakeRange(i, 1)];
            NSString *a = [dictionary objectForKey:substr];
            NSString *b = digits[arabicNumStr.length -i-1];
            NSString *sum = [a stringByAppendingString:b];
            if ([a isEqualToString:chineseNumeralsArray[9]]) {
                if([b isEqualToString:digits[4]] || [b isEqualToString:digits[8]]) {
                    sum = b;
                    if ([[sums lastObject] isEqualToString:chineseNumeralsArray[9]]) {
                        [sums removeLastObject];
                    }
                } else {
                    sum = chineseNumeralsArray[9];
                }
                if ([[sums lastObject] isEqualToString:sum]) {
                    continue;
                }
            }
            [sums addObject:sum];
        }
        NSString *sumStr = [sums  componentsJoinedByString:@""];
        NSString *chinese = [sumStr substringToIndex:sumStr.length-1];
        return chinese;
    }
}

/* 定位完成后 回调 */
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    [_geoC reverseGeocodeLocation:[locations lastObject] completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MM.dd"];
            self->_timeLocationALabel.text = [NSString stringWithFormat:@"%@ · %@", [formatter stringFromDate:date], placemarks[0].locality];
            [formatter setDateFormat:@"MM.dd · HH:mm"];
            self->_timeLocationBLabel.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];
        });
    }];
    [manager stopUpdatingLocation];   //停止定位
}

/* 定位失败后 回调 */
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if (error) {
        SHOW_ERROR_ALERT;
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusDenied) {
        SHOW_ALERT(@"错误", @"定位服务关闭，无法获取位置信息", @"好的");
    }
}

- (IBAction)formatAButtonPressed:(UIButton *)sender {
    CGRect previeousFrame = _timeLocationALabel.frame;
    UIFont *previeousFont = _timeLocationALabel.font;
    CGFloat width = _editor.draft.videoSize.width * 0.3;
    CGFloat height = width * previeousFrame.size.height / previeousFrame.size.width;
    _timeLocationALabel.frame = CGRectMake(0, 0, width, height);
    _timeLocationALabel.font = [UIFont fontWithName:previeousFont.fontName size:previeousFont.pointSize * width / previeousFrame.size.width];
    UIImage *labelImage = [_timeLocationALabel convertToImage];
    _timeLocationALabel.frame = previeousFrame;
    _timeLocationALabel.font = previeousFont;
    MSVImageStickerEffect *effect = [[MSVImageStickerEffect alloc] initWithImage:labelImage];
    effect.ID = @"TimeLocation";
    effect.destRect = CGRectMake(20, _editor.draft.videoSize.height - height - 20, width, height);
    NSError *error;
    NSMutableArray *effects = [NSMutableArray array];
    for (id obj in _editor.draft.effects) {
        if ([obj isKindOfClass:MSVImageStickerEffect.class] && [((MSVImageStickerEffect *)obj).ID isEqualToString:@"TimeLocation"]) {
            continue;
        }
        [effects addObject:obj];
    }
    [effects addObject:effect];
    if (![_editor.draft updateEffects:effects error:&error]) {
        SHOW_ERROR_ALERT;
    }
}

- (IBAction)formatBButtonPressed:(UIButton *)sender {
    CGRect previeousFrame = _timeLocationBLabel.frame;
    UIFont *previeousFont = _timeLocationBLabel.font;
    CGFloat width = _editor.draft.videoSize.width * 0.3;
    CGFloat height = width * previeousFrame.size.height / previeousFrame.size.width;
    _timeLocationBLabel.frame = CGRectMake(0, 0, width, height);
    _timeLocationBLabel.font = [UIFont fontWithName:previeousFont.fontName size:previeousFont.pointSize * width / previeousFrame.size.width];
    UIImage *labelImage = [_timeLocationBLabel convertToImage];
    _timeLocationBLabel.frame = previeousFrame;
    _timeLocationBLabel.font = previeousFont;
    MSVImageStickerEffect *effect = [[MSVImageStickerEffect alloc] initWithImage:labelImage];
    effect.ID = @"TimeLocation";
    effect.destRect = CGRectMake(20, _editor.draft.videoSize.height - height - 20, width, height);
    NSError *error;
    NSMutableArray *effects = [NSMutableArray array];
    for (id obj in _editor.draft.effects) {
        if ([obj isKindOfClass:MSVImageStickerEffect.class] && [((MSVImageStickerEffect *)obj).ID isEqualToString:@"TimeLocation"]) {
            continue;
        }
        [effects addObject:obj];
    }
    [effects addObject:effect];
    if (![_editor.draft updateEffects:effects error:&error]) {
        SHOW_ERROR_ALERT;
    }
}

@end
