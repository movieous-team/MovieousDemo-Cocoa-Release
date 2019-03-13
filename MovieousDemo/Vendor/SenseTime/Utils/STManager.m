//
//  STManager.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/15.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "st_mobile_human_action.h"     //人脸、眼球、⼿手势、肢体、前后背景检测
#import "st_mobile_beautify.h"          //美化
#import "st_mobile_filter.h"            //滤镜
#import "st_mobile_common.h"            //SDK通⽤用参数定义
#import "st_mobile_face_attribute.h"    //⼈人脸属性检测
#import "st_mobile_license.h"           //人脸属性检测
#import "st_mobile_object.h"            //通⽤物体跟踪
#import "st_mobile_sticker.h"           //鉴权操作 //通⽤用物体跟踪 //贴纸
#import "STEffectsAudioPlayer.h"
#import <CoreMotion/CoreMotion.h>
#import "STParamUtil.h"
#import "STMobileLog.h"
#import <OpenGLES/ES2/glext.h>

#define DRAW_FACE_KEY_POINTS 0
#define ENABLE_DYNAMIC_ADD_AND_REMOVE_MODELS 0
#define ENABLE_FACE_ATTRIBUTE_DETECT 0
#define TEST_OUTPUT_BUFFER_INTERFACE 0
#define TEST_BODY_BEAUTY 0

@protocol STEffectsMessageDelegate <NSObject>

- (void)loadSound:(NSData *)soundData name:(NSString *)strName;
- (void)playSound:(NSString *)strName loop:(int)iLoop;
- (void)pauseSound:(NSString *)strName;
- (void)resumeSound:(NSString *)strName;
- (void)stopSound:(NSString *)strName;
- (void)unloadSound:(NSString *)strName;

@end

@interface STEffectsMessageManager : NSObject

@property (nonatomic, readwrite, weak) id<STEffectsMessageDelegate> delegate;
@end

@implementation STEffectsMessageManager

@end

STEffectsMessageManager *messageManager = nil;

@interface STManager ()
<
STEffectsAudioPlayerDelegate,
STEffectsMessageDelegate
>

@end

@implementation STManager {
    st_handle_t _hSticker;  // sticker句柄
    st_handle_t _hDetector; // detector句柄
    st_handle_t _hBeautify; // beautify句柄
    st_handle_t _hAttribute;// attribute句柄
    st_handle_t _hFilter;   // filter句柄
    st_handle_t _hTracker;  // 通用物体跟踪句柄
    
    st_rect_t _rect;  // 通用物体位置
    float _result_score; //通用物体置信度
    
    STEffectsAudioPlayer *_audioPlayer;
    CMMotionManager *_motionManager;
    
    CGFloat _scale;  //视频充满全屏的缩放比例
    int _margin;
    NSMutableArray *_faceArray;
    double _lastTimeAttrDetected;
    
    BOOL _commonObjectViewAdded;
    BOOL _commonObjectViewSetted;
    
    unsigned long long _iCurrentAction;
    
    EAGLContext *_glContext;
    
    CGFloat _imageWidth;
    CGFloat _imageHeight;
    
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    CVOpenGLESTextureRef _cvTextureOrigin;
    CVOpenGLESTextureRef _cvTextureBeautify;
    CVOpenGLESTextureRef _cvTextureSticker;
    CVOpenGLESTextureRef _cvTextureFilter;
    
    CVPixelBufferRef _cvBeautifyBuffer;
    CVPixelBufferRef _cvStickerBuffer;
    CVPixelBufferRef _cvFilterBuffer;
    
    GLuint _textureOriginInput;
    GLuint _textureBeautifyOutput;
    GLuint _textureStickerOutput;
    GLuint _textureFilterOutput;
    
    BOOL _isNullSticker;
    UIDeviceOrientation _deviceOrientation;
    
    NSString *_preFilterModelPath;
    NSString *_curFilterModelPath;
    
    CMFormatDescriptionRef _outputVideoFormatDescription;
    
    GLuint _beautifyClipFramebuffer;
    GLuint _beautifyClipProgram;
    
    dispatch_queue_t _changeStickerQueue;
    NSString *_strStickerPath;
    float _fFilterStrength;
    STCollectionViewDisplayModel *_currentModel;
    
    NSRecursiveLock *_lock;
}

+ (instancetype)sharedManager {
    static STManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [NSRecursiveLock new];
        [self setupSenseTime];
    }
    return self;
}

- (void)setupSenseTime {
    _changeStickerQueue = dispatch_queue_create("com.sensetime.changestickerqueue", NULL);
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_glContext];
    // 初始化结果纹理及纹理缓存
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_cvTextureCache);
    
    if (err) {
        
        NSLog(@"CVOpenGLESTextureCacheCreate %d" , err);
    }
    
    [self setupUtilTools];
    if ([self checkActiveCode]) {
        ///ST_MOBILE：初始化相关的句柄
        [self setupHandle];
    }
    [self initResource];
}

- (void)initResource
{
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    // 设置SDK OpenGL 环境 , 只有在正确的 OpenGL 环境下 SDK 才会被正确初始化 .
    
    [EAGLContext setCurrentContext:_glContext];
    
    // 初始化结纹理及纹理缓存
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_cvTextureCache);
    
    if (err) {
        
        NSLog(@"CVOpenGLESTextureCacheCreate %d" , err);
    }
    
    [self initResultTexture];
    
    [self resetSettings];
    
    ///ST_MOBILE：初始化句柄之前需要验证License
    if ([self checkActiveCode]) {
        ///ST_MOBILE：初始化相关的句柄
        [self setupHandle];
    }
    
    if ([_motionManager isAccelerometerAvailable]) {
        [_motionManager startAccelerometerUpdates];
    }
    
    if ([_motionManager isDeviceMotionAvailable]) {
        [_motionManager startDeviceMotionUpdates];
    }
}

- (void)resetSettings {
    _fFilterStrength = 0.65;
    
    
    self.fSmoothStrength = 0.74;
    self.fReddenStrength = 0.36;
    self.fWhitenStrength = 0.02;
    self.fEnlargeEyeStrength = 0.13;
    self.fShrinkFaceStrength = 0.11;
    self.fShrinkJawStrength = 0.10;
    self.fContrastStrength = 0.0;
    self.fSaturationStrength = 0.0;
    self.fDehighlightStrength = 0.0;
}

- (void)setupUtilTools {
    
    _audioPlayer = [[STEffectsAudioPlayer alloc] init];
    _audioPlayer.delegate = self;
    
    messageManager = [[STEffectsMessageManager alloc] init];
    messageManager.delegate = self;
    
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.accelerometerUpdateInterval = 0.5;
    _motionManager.deviceMotionUpdateInterval = 1 / 25.0;
}

//验证license
- (BOOL)checkActiveCode
{
    NSString *strLicensePath = [[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"];
    NSData *dataLicense = [NSData dataWithContentsOfFile:strLicensePath];
    
    NSString *strKeySHA1 = @"SENSEME";
    NSString *strKeyActiveCode = @"ACTIVE_CODE";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *strStoredSHA1 = [userDefaults objectForKey:strKeySHA1];
    NSString *strLicenseSHA1 = [self getSHA1StringWithData:dataLicense];
    
    st_result_t iRet = ST_OK;
    
    
    if (strStoredSHA1.length > 0 && [strLicenseSHA1 isEqualToString:strStoredSHA1]) {
        
        // Get current active code
        // In this app active code was stored in NSUserDefaults
        // It also can be stored in other places
        NSData *activeCodeData = [userDefaults objectForKey:strKeyActiveCode];
        
        // Check if current active code is available
#if CHECK_LICENSE_WITH_PATH
        
        // use file
        iRet = st_mobile_check_activecode(
                                          strLicensePath.UTF8String,
                                          (const char *)[activeCodeData bytes],
                                          (int)[activeCodeData length]
                                          );
        
#else
        
        // use buffer
        NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
        
        iRet = st_mobile_check_activecode_from_buffer(
                                                      [licenseData bytes],
                                                      (int)[licenseData length],
                                                      [activeCodeData bytes],
                                                      (int)[activeCodeData length]
                                                      );
#endif
        
        
        if (ST_OK == iRet) {
            
            // check success
            return YES;
        }
    }
    
    /*
     1. check fail
     2. new one
     3. update
     */
    
    char active_code[1024];
    int active_code_len = 1024;
    
    // generate one
#if CHECK_LICENSE_WITH_PATH
    
    // use file
    iRet = st_mobile_generate_activecode(
                                         strLicensePath.UTF8String,
                                         active_code,
                                         &active_code_len
                                         );
    
#else
    
    // use buffer
    NSData *licenseData = [NSData dataWithContentsOfFile:strLicensePath];
    
    iRet = st_mobile_generate_activecode_from_buffer(
                                                     [licenseData bytes],
                                                     (int)[licenseData length],
                                                     active_code,
                                                     &active_code_len
                                                     );
#endif
    
    if (ST_OK != iRet) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
        return NO;
        
    } else {
        
        // Store active code
        NSData *activeCodeData = [NSData dataWithBytes:active_code length:active_code_len];
        
        [userDefaults setObject:activeCodeData forKey:strKeyActiveCode];
        [userDefaults setObject:strLicenseSHA1 forKey:strKeySHA1];
        
        [userDefaults synchronize];
    }
    
    return YES;
}

- (void)setupHandle {
    
    st_result_t iRet = ST_OK;
    
    //初始化检测模块句柄
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Action_5.5.1" ofType:@"model"];
    
    uint32_t config = ST_MOBILE_HUMAN_ACTION_DEFAULT_CONFIG_VIDEO;
    
    
    iRet = st_mobile_human_action_create(strModelPath.UTF8String, config, &_hDetector);
    
    if (ST_OK != iRet || !_hDetector) {
        
        NSLog(@"st mobile human action create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"算法SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    } else {
        
        addSubModel(_hDetector, @"M_SenseME_Face_Extra_5.6.0");
        addSubModel(_hDetector, @"M_SenseME_Iris_1.11.1");
#if TEST_BODY_BEAUTY
        addSubModel(_hDetector, @"M_SenseME_Body_Contour_73_1.2.0");
#endif
    }
    
    //初始化贴纸模块句柄 , 默认开始时无贴纸 , 所以第一个路径参数传空
    iRet = st_mobile_sticker_create(&_hSticker);
    
    if (ST_OK != iRet || !_hSticker) {
        
        NSLog(@"st mobile sticker create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"贴纸SDK初始化失败 , SDK权限过期，或者与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    } else {
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_LOAD_FUNC_PTR, load_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set load sound func failed: %d", iRet);
        }
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_PLAY_FUNC_PTR, play_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set play sound func failed: %d", iRet);
        }
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_PAUSE_FUNC_PTR, pause_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set pause sound func failed: %d", iRet);
        }
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_RESUME_FUNC_PTR, resume_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set resume sound func failed: %d", iRet);
        }
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_STOP_FUNC_PTR, stop_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set stop sound func failed: %d", iRet);
        }
        
        iRet = st_mobile_sticker_set_param_ptr(_hSticker, -1, ST_STICKER_PARAM_SOUND_UNLOAD_FUNC_PTR, unload_sound);
        if (iRet != ST_OK) {
            NSLog(@"st mobile set unload sound func failed: %d", iRet);
        }
        
        NSString *strAvatarModelPath = [[NSBundle mainBundle] pathForResource:@"avatar_core" ofType:@"model"];
        iRet = st_mobile_sticker_load_avatar_model(_hSticker, strAvatarModelPath.UTF8String);
        if (iRet != ST_OK) {
            NSLog(@"load avatar model failed: %d", iRet);
        }
    }
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    //初始化人脸属性模块句柄
    NSString *strAttriModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Attribute_1.0.1" ofType:@"model"];
    
    iRet = st_mobile_face_attribute_create(strAttriModelPath.UTF8String, &_hAttribute);
    
    if (ST_OK != iRet || !_hAttribute) {
        
        NSLog(@"st mobile face attribute create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"属性SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
#endif
    
    
    //初始化美颜模块句柄
    iRet = st_mobile_beautify_create(&_hBeautify);
    
    if (ST_OK != iRet || !_hBeautify) {
        
        NSLog(@"st mobile beautify create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"美颜SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
        
    }else{
        
        // 设置默认红润参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_REDDEN_STRENGTH, self.fReddenStrength);
        
        // 设置默认磨皮参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_SMOOTH_STRENGTH, self.fSmoothStrength);
        
        // 设置默认大眼参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_ENLARGE_EYE_RATIO, self.fEnlargeEyeStrength);
        
        // 设置默认瘦脸参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_SHRINK_FACE_RATIO, self.fShrinkFaceStrength);
        
        // 设置小脸参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_SHRINK_JAW_RATIO, self.fShrinkJawStrength);
        
        // 设置美白参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_WHITEN_STRENGTH, self.fWhitenStrength);
        
        //设置对比度参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_CONTRAST_STRENGTH, self.fContrastStrength);
        
        //设置饱和度参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_SATURATION_STRENGTH, self.fSaturationStrength);
        
        //去高光参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_DEHIGHLIGHT_STRENGTH, self.fDehighlightStrength);
        
#if TEST_BODY_BEAUTY
        st_mobile_beautify_set_input_source(_hBeautify, ST_BEAUTIFY_PREVIEW);
        st_mobile_beautify_set_body_ref_type(_hBeautify, ST_BEAUTIFY_BODY_REF_HEAD);
        //设置瘦身参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_WHOLE_RATIO, 0.4);
        
        //设置瘦头参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_HEAD_RATIO, 0.4);
        
        //设置瘦肩参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_SHOULDER_RATIO, 0.4);
        
        //设置瘦腰参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_WAIST_RATIO, 0.4);
        
        //设置瘦臀参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_HIP_RATIO, 0.4);
        
        //设置瘦腿参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_LEG_RATIO, 0.4);
        
        //设置长腿参数
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_BODY_HEIGHT_RATIO, 0.4);
#endif
    }
    
    // 初始化滤镜句柄
    iRet = st_mobile_gl_filter_create(&_hFilter);
    
    if (ST_OK != iRet || !_hFilter) {
        
        NSLog(@"st mobile gl filter create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"滤镜SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
    
    // 初始化通用物体追踪句柄
    iRet = st_mobile_object_tracker_create(&_hTracker);
    
    if (ST_OK != iRet || !_hTracker) {
        
        NSLog(@"st mobile object tracker create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"通用物体跟踪SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
}

#pragma mark - sound
void load_sound(void* handle, void* sound, const char* sound_name, int length) {
    
    //    NSLog(@"STEffectsAudioPlayer load sound");
    
    if ([messageManager.delegate respondsToSelector:@selector(loadSound:name:)]) {
        
        NSData *soundData = [NSData dataWithBytes:sound length:length];
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        
        [messageManager.delegate loadSound:soundData name:strName];
    }
}

void play_sound(void* handle, const char* sound_name, int loop) {
    
    //    NSLog(@"STEffectsAudioPlayer play sound");
    
    if ([messageManager.delegate respondsToSelector:@selector(playSound:loop:)]) {
        
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        
        [messageManager.delegate playSound:strName loop:loop];
    }
}

void pause_sound(void *handle, const char *sound_name) {
    if ([messageManager.delegate respondsToSelector:@selector(pauseSound:)]) {
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        [messageManager.delegate pauseSound:strName];
    }
}

void resume_sound(void *handle, const char *sound_name) {
    if ([messageManager.delegate respondsToSelector:@selector(resumeSound:)]) {
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        [messageManager.delegate resumeSound:strName];
    }
}

void stop_sound(void* handle, const char* sound_name) {
    
    //    NSLog(@"STEffectsAudioPlayer stop sound");
    if ([messageManager.delegate respondsToSelector:@selector(stopSound:)]) {
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        [messageManager.delegate stopSound:strName];
    }
}

void unload_sound(void *handle, const char *sound_name) {
    if ([messageManager.delegate respondsToSelector:@selector(unloadSound:)]) {
        NSString *strName = [NSString stringWithUTF8String:sound_name];
        [messageManager.delegate unloadSound:strName];
    }
}

- (void)audioPlayerDidFinishPlaying:(STEffectsAudioPlayer *)player successfully:(BOOL)flag name:(NSString *)strName {
    
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [_lock lock];
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    unsigned char* pBGRAImageIn = (unsigned char*)CVPixelBufferGetBaseAddress(pixelBuffer);
    double dCost = 0.0;
    double dStart = CFAbsoluteTimeGetCurrent();
    
    int iBytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    size_t iTop , iBottom , iLeft , iRight;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    
    iWidth = iWidth + (int)iLeft + (int)iRight;
    iHeight = iHeight + (int)iTop + (int)iBottom;
    iBytesPerRow = iBytesPerRow + (int)iLeft + (int)iRight;
    
    _scale = MAX(SCREEN_HEIGHT / iHeight, SCREEN_WIDTH / iWidth);
    _margin = (iWidth * _scale - SCREEN_WIDTH) / 2;
    
    st_rotate_type stMobileRotate = [self getRotateType];
    
    st_result_t iRet = ST_OK;
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    int iFaceCount = 0;
#endif
    
    _faceArray = [NSMutableArray array];
    
    // 如果需要做属性,每隔一秒做一次属性
    double dTimeNow = CFAbsoluteTimeGetCurrent();
    BOOL isAttributeTime = (dTimeNow - _lastTimeAttrDetected) >= 1.0;
    
    if (isAttributeTime) {
        
        _lastTimeAttrDetected = dTimeNow;
    }
    
    ///ST_MOBILE 以下为通用物体跟踪部分
    if (_bTracker && _hTracker) {
        
        if (_commonObjectViewAdded) {
            
            if (!_commonObjectViewSetted) {
                
                iRet = st_mobile_object_tracker_set_target(_hTracker, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, &_rect);
                
                if (iRet != ST_OK) {
                    NSLog(@"st mobile object tracker set target failed: %d", iRet);
                    _rect.left = 0;
                    _rect.top = 0;
                    _rect.right = 0;
                    _rect.bottom = 0;
                } else {
                    _commonObjectViewSetted = YES;
                }
            }
            
            if (_commonObjectViewSetted) {
                
                TIMELOG(keyTracker);
                iRet = st_mobile_object_tracker_track(_hTracker, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, &_rect, &_result_score);
                //                NSLog(@"tracking, result_score: %f,rect.left: %d, rect.top: %d, rect.right: %d, rect.bottom: %d", _result_score, _rect.left, _rect.top, _rect.right, _rect.bottom);
                TIMEPRINT(keyTracker, "st_mobile_object_tracker_track time:");
                
                if (iRet != ST_OK) {
                    
                    NSLog(@"st mobile object tracker track failed: %d", iRet);
                    _rect.left = 0;
                    _rect.top = 0;
                    _rect.right = 0;
                    _rect.bottom = 0;
                }
                
                CGRect rectDisplay = CGRectMake(_rect.left * _scale - _margin,
                                                _rect.top * _scale,
                                                _rect.right * _scale - _rect.left * _scale,
                                                _rect.bottom * _scale - _rect.top * _scale);
                CGPoint center = CGPointMake(rectDisplay.origin.x + rectDisplay.size.width / 2,
                                             rectDisplay.origin.y + rectDisplay.size.height / 2);
                
                if ([_delegate respondsToSelector:@selector(manager:commonObjectCenterDidUpdated:)]) {
                    [_delegate manager:self commonObjectCenterDidUpdated:center];
                }
            }
        }
    }
    
    ///ST_MOBILE 人脸信息检测部分
    if (_hDetector) {
        
        BOOL needFaceDetection = ((self.fEnlargeEyeStrength > 0 || self.fShrinkFaceStrength > 0 || self.fShrinkJawStrength > 0 || self.fDehighlightStrength > 0) && _hBeautify) || (self.bAttribute && isAttributeTime && _hAttribute);
        
        if (needFaceDetection) {
            
            _iCurrentAction |= ST_MOBILE_FACE_DETECT;
            
        }
#if TEST_BODY_BEAUTY
        _iCurrentAction |= ST_MOBILE_BODY_KEYPOINTS | ST_MOBILE_BODY_CONTOUR;
#endif
        
        if (_iCurrentAction > 0) {
            
            TIMELOG(keyDetect);
            
            iRet = st_mobile_human_action_detect(_hDetector, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, stMobileRotate, _iCurrentAction, &detectResult);
            
            TIMEPRINT(keyDetect, "st_mobile_human_action_detect time:");
            
            if(iRet == ST_OK) {
                
#if ENABLE_FACE_ATTRIBUTE_DETECT
                
                iFaceCount = detectResult.face_count;
                
                if (iFaceCount > 0) {
                    _pFacesDetection = (st_mobile_106_t *)malloc(sizeof(st_mobile_106_t) * iFaceCount);
                    memset(_pFacesDetection, 0, sizeof(st_mobile_106_t) * iFaceCount);
                }
                
                //构造人脸信息数组
                for (int i = 0; i < iFaceCount; i++) {
                    
                    _pFacesDetection[i] = detectResult.p_faces[i].face106;
                }
                
#endif
                
            }else{
                STLog(@"st_mobile_human_action_detect failed %d" , iRet);
            }
        }
    }
    
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    ///ST_MOBILE 以下为attribute部分 , 当人脸数大于零且人脸信息数组不为空时每秒做一次属性检测.
    if (self.bAttribute && _hAttribute) {
        
        if (iFaceCount > 0 && _pFacesDetection && isAttributeTime) {
            
            TIMELOG(attributeKey);
            
            st_mobile_attributes_t *pAttrArray;
            
            // attribute detect
            iRet = st_mobile_face_attribute_detect(_hAttribute,
                                                   pBGRAImageIn,
                                                   ST_PIX_FMT_BGRA8888,
                                                   iWidth,
                                                   iHeight,
                                                   iBytesPerRow,
                                                   _pFacesDetection,
                                                   1, // 这里仅取一张脸也就是第一张脸的属性作为演示
                                                   &pAttrArray);
            if (iRet != ST_OK) {
                
                pFacesFinal = NULL;
                
                STLog(@"st_mobile_face_attribute_detect failed. %d" , iRet);
                
                goto unlockBufferAndFlushCache;
            }
            
            TIMEPRINT(attributeKey, "st_mobile_face_attribute_detect time: ");
            
            // 取第一个人的属性集合作为示例
            st_mobile_attributes_t attributeDisplay = pAttrArray[0];
            
            //获取属性描述
            NSString *strAttrDescription = [self getDescriptionOfAttribute:attributeDisplay];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.lblAttribute setText:[@"第一张人脸: " stringByAppendingString:strAttrDescription]];
                [self.lblAttribute setHidden:NO];
            });
        }
    }else{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.lblAttribute setText:@""];
            [self.lblAttribute setHidden:YES];
        });
    }
    
#endif
    
    
    // 设置 OpenGL 环境 , 需要与初始化 SDK 时一致
    if ([EAGLContext currentContext] != _glContext) {
        [EAGLContext setCurrentContext:_glContext];
    }
    
    // 当图像尺寸发生改变时需要对应改变纹理大小
    if (iWidth != _imageWidth || iHeight != _imageHeight) {
        
        [self releaseResultTexture];
        
        _imageWidth = iWidth;
        _imageHeight = iHeight;
        
        [self initResultTexture];
    }
    
    // 获取原图纹理
    BOOL isTextureOriginReady = [self setupOriginTextureWithPixelBuffer:pixelBuffer];
    
    GLuint textureResult = _textureOriginInput;
    
    CVPixelBufferRef resultPixelBufffer = pixelBuffer;
    
    if (isTextureOriginReady) {
        
        ///ST_MOBILE 以下为美颜部分
        if (_bBeauty && _hBeautify) {
            
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_SHRINK_FACE_RATIO, self.fShrinkFaceStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_ENLARGE_EYE_RATIO, self.fEnlargeEyeStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_SHRINK_JAW_RATIO, self.fShrinkJawStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_SMOOTH_STRENGTH, self.fSmoothStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_REDDEN_STRENGTH, self.fReddenStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_WHITEN_STRENGTH, self.fWhitenStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_CONTRAST_STRENGTH, self.fContrastStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_SATURATION_STRENGTH, self.fSaturationStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_DEHIGHLIGHT_STRENGTH, self.fDehighlightStrength);
            
            TIMELOG(keyBeautify);
            
#if TEST_OUTPUT_BUFFER_INTERFACE
            
            unsigned char * beautify_buffer_output = malloc(iWidth * iHeight * 4);
            
            iRet = st_mobile_beautify_process_and_output_texture(_hBeautify, _textureOriginInput, iWidth, iHeight, &detectResult, _textureBeautifyOutput, beautify_buffer_output, ST_PIX_FMT_RGBA8888, &detectResult);
            
            UIImage *beatifyImage = [self rgbaBufferConvertToImage:beautify_buffer_output width:iWidth height:iHeight];
            
            if (beautify_buffer_output) {
                free(beautify_buffer_output);
                beautify_buffer_output = NULL;
            }
            
#else
            iRet = st_mobile_beautify_process_texture(_hBeautify, _textureOriginInput, iWidth, iHeight, stMobileRotate, &detectResult, _textureBeautifyOutput, &detectResult);
            
#endif
            TIMEPRINT(keyBeautify, "st_mobile_beautify_process_texture time:");
            
            if (ST_OK != iRet) {
                
                STLog(@"st_mobile_beautify_process_texture failed %d" , iRet);
                
            } else {
                textureResult = _textureBeautifyOutput;
                resultPixelBufffer = _cvBeautifyBuffer;
            }
        }
        
    }
    
    if (_isNullSticker) {
        iRet = st_mobile_sticker_change_package(_hSticker, NULL, NULL);
        
        if (ST_OK != iRet) {
            NSLog(@"st_mobile_sticker_change_package error %d", iRet);
        }
    }
    
#if DRAW_FACE_KEY_POINTS
    
    [self drawKeyPoints:detectResult];
#endif
    
    
    ///ST_MOBILE 以下为贴纸部分
    if (_bSticker && _hSticker) {
        
        TIMELOG(stickerProcessKey);
        
#if TEST_OUTPUT_BUFFER_INTERFACE
        
        unsigned char * sticker_buffer_output = malloc(iWidth * iHeight * 4);
        
        iRet = st_mobile_sticker_process_and_output_texture(_hSticker, textureResult, iWidth, iHeight, stMobileRotate, ST_CLOCKWISE_ROTATE_0, false, &detectResult, item_callback, _textureStickerOutput, sticker_buffer_output, ST_PIX_FMT_RGBA8888);
        
        UIImage *stickerImage = [self rgbaBufferConvertToImage:sticker_buffer_output width:iWidth height:iHeight];
        
        if (sticker_buffer_output) {
            free(sticker_buffer_output);
            sticker_buffer_output = NULL;
        }
        
#else
        st_mobile_input_params_t inputEvent;
        memset(&inputEvent, 0, sizeof(st_mobile_input_params_t));
        
        int type = ST_INPUT_PARAM_NONE;
        iRet = st_mobile_sticker_get_needed_input_params(_hSticker, &type);
        
        if (CHECK_FLAG(type, ST_INPUT_PARAM_CAMERA_QUATERNION)) {
            
            CMDeviceMotion *motion = _motionManager.deviceMotion;
            inputEvent.camera_quaternion[0] = motion.attitude.quaternion.x;
            inputEvent.camera_quaternion[1] = motion.attitude.quaternion.y;
            inputEvent.camera_quaternion[2] = motion.attitude.quaternion.z;
            inputEvent.camera_quaternion[3] = motion.attitude.quaternion.w;
            
            if (self.devicePosition == AVCaptureDevicePositionBack) {
                inputEvent.is_front_camera = false;
            } else {
                inputEvent.is_front_camera = true;
            }
        } else {
            
            inputEvent.camera_quaternion[0] = 0;
            inputEvent.camera_quaternion[1] = 0;
            inputEvent.camera_quaternion[2] = 0;
            inputEvent.camera_quaternion[3] = 1;
        }
        
        iRet = st_mobile_sticker_process_texture(_hSticker, textureResult, iWidth, iHeight, stMobileRotate, ST_CLOCKWISE_ROTATE_0, false, &detectResult, &inputEvent, _textureStickerOutput);
        
#endif
        
        TIMEPRINT(stickerProcessKey, "st_mobile_sticker_process_texture time:");
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_sticker_process_texture %d" , iRet);
            
        }
        
        textureResult = _textureStickerOutput;
        resultPixelBufffer = _cvStickerBuffer;
    }
    
    
    ///ST_MOBILE 以下为滤镜部分
    if (_bFilter && _hFilter) {
        
        if (_curFilterModelPath != _preFilterModelPath) {
            iRet = st_mobile_gl_filter_set_style(_hFilter, _curFilterModelPath.UTF8String);
            if (iRet != ST_OK) {
                NSLog(@"st mobile filter set style failed: %d", iRet);
            }
            _preFilterModelPath = _curFilterModelPath;
        }
        
        TIMELOG(keyFilter);
        
#if TEST_OUTPUT_BUFFER_INTERFACE
        
        unsigned char * filter_buffer_output = malloc(iWidth * iHeight * 4);
        
        iRet = st_mobile_gl_filter_process_texture_and_output_buffer(_hFilter, textureResult, iWidth, iHeight, _textureFilterOutput, filter_buffer_output, ST_PIX_FMT_RGBA8888);
        
        UIImage *filterImage = [self rgbaBufferConvertToImage:filter_buffer_output width:iWidth height:iHeight];
        
        if (filter_buffer_output) {
            free(filter_buffer_output);
            filter_buffer_output = NULL;
        }
        
#else
        iRet = st_mobile_gl_filter_process_texture(_hFilter, textureResult, iWidth, iHeight, _textureFilterOutput);
        
#endif
        
        
        
        TIMEPRINT(keyFilter, "st_mobile_gl_filter_process_texture time:");
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_gl_filter_process_texture %d" , iRet);
            
        }
        
        textureResult = _textureFilterOutput;
        resultPixelBufffer = _cvFilterBuffer;
    }
    
    //对比
    if (self.isComparing) {
        
        textureResult = _textureOriginInput;
    }
    
    if (!_outputVideoFormatDescription) {
        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &(_outputVideoFormatDescription));
    }
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVOpenGLESTextureCacheFlush(_cvTextureCache, 0);
    
    if (_cvTextureOrigin) {
        
        CFRelease(_cvTextureOrigin);
        _cvTextureOrigin = NULL;
    }
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    if (_pFacesDetection) {
        free(_pFacesDetection);
        _pFacesDetection = NULL;
    }
#endif
    
    dCost = CFAbsoluteTimeGetCurrent() - dStart;
    
    TIMEPRINT(frameCostKey, "every frame cost time");
    [_lock unlock];
    return resultPixelBufffer;
}

- (void)initResultTexture {
    // 创建结果纹理
    [self setupTextureWithPixelBuffer:&_cvBeautifyBuffer
                                    w:_imageWidth
                                    h:_imageHeight
                            glTexture:&_textureBeautifyOutput
                            cvTexture:&_cvTextureBeautify];
    
    [self setupTextureWithPixelBuffer:&_cvStickerBuffer
                                    w:_imageWidth
                                    h:_imageHeight
                            glTexture:&_textureStickerOutput
                            cvTexture:&_cvTextureSticker];
    
    
    [self setupTextureWithPixelBuffer:&_cvFilterBuffer
                                    w:_imageWidth
                                    h:_imageHeight
                            glTexture:&_textureFilterOutput
                            cvTexture:&_cvTextureFilter];
}

- (BOOL)setupTextureWithPixelBuffer:(CVPixelBufferRef *)pixelBufferOut
                                  w:(int)iWidth
                                  h:(int)iHeight
                          glTexture:(GLuint *)glTexture
                          cvTexture:(CVOpenGLESTextureRef *)cvTexture {
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault,
                                               NULL,
                                               NULL,
                                               0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                             1,
                                                             &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn cvRet = CVPixelBufferCreate(kCFAllocatorDefault,
                                         iWidth,
                                         iHeight,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         pixelBufferOut);
    
    if (kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVPixelBufferCreate %d" , cvRet);
    }
    
    cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         _cvTextureCache,
                                                         *pixelBufferOut,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RGBA,
                                                         _imageWidth,
                                                         _imageHeight,
                                                         GL_BGRA,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         cvTexture);
    
    CFRelease(attrs);
    CFRelease(empty);
    
    if (kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d" , cvRet);
        
        return NO;
    }
    
    *glTexture = CVOpenGLESTextureGetName(*cvTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(*cvTexture), *glTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return YES;
}

- (BOOL)setupOriginTextureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVReturn cvRet = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                  _cvTextureCache,
                                                                  pixelBuffer,
                                                                  NULL,
                                                                  GL_TEXTURE_2D,
                                                                  GL_RGBA,
                                                                  _imageWidth,
                                                                  _imageHeight,
                                                                  GL_BGRA,
                                                                  GL_UNSIGNED_BYTE,
                                                                  0,
                                                                  &_cvTextureOrigin);
    
    if (!_cvTextureOrigin || kCVReturnSuccess != cvRet) {
        
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage %d" , cvRet);
        
        return NO;
    }
    
    _textureOriginInput = CVOpenGLESTextureGetName(_cvTextureOrigin);
    glBindTexture(GL_TEXTURE_2D , _textureOriginInput);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return YES;
}

- (void)releaseResultTexture {
    _textureBeautifyOutput = 0;
    _textureStickerOutput = 0;
    _textureFilterOutput = 0;
    
    if (_beautifyClipProgram) {
        glDeleteProgram(_beautifyClipProgram);
        _beautifyClipProgram = 0;
    }
    
    if (_beautifyClipFramebuffer) {
        glDeleteFramebuffers(1, &_beautifyClipFramebuffer);
        _beautifyClipFramebuffer = 0;
    }
    
    if (_cvTextureOrigin) {
        
        CFRelease(_cvTextureOrigin);
        _cvTextureOrigin = NULL;
    }
    
    if (_cvTextureBeautify) {
        CFRelease(_cvTextureBeautify);
        _cvTextureBeautify = NULL;
    }
    
    if (_cvTextureSticker) {
        CFRelease(_cvTextureSticker);
        _cvTextureSticker = NULL;
    }
    
    if (_cvTextureFilter) {
        CFRelease(_cvTextureFilter);
        _cvTextureFilter = NULL;
    }
    
    if (_cvBeautifyBuffer) {
        CVPixelBufferRelease(_cvBeautifyBuffer);
        _cvBeautifyBuffer = NULL;
    }
    
    if (_cvStickerBuffer) {
        CVPixelBufferRelease(_cvStickerBuffer);
        _cvStickerBuffer = NULL;
    }
    
    if (_cvFilterBuffer) {
        CVPixelBufferRelease(_cvFilterBuffer);
        _cvFilterBuffer = NULL;
    }
}

- (NSString *)getSHA1StringWithData:(NSData *)data
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *strSHA1 = [NSMutableString string];
    
    for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; i ++) {
        
        [strSHA1 appendFormat:@"%02x" , digest[i]];
    }
    
    return strSHA1;
}

#pragma mark - STEffectsMessageManagerDelegate

- (void)loadSound:(NSData *)soundData name:(NSString *)strName {
    
    if ([_audioPlayer loadSound:soundData name:strName]) {
        NSLog(@"STEffectsAudioPlayer load %@ successfully", strName);
    }
}

- (void)playSound:(NSString *)strName loop:(int)iLoop {
    
    if ([_audioPlayer playSound:strName loop:iLoop]) {
        NSLog(@"STEffectsAudioPlayer play %@ successfully", strName);
    }
}

- (void)pauseSound:(NSString *)strName {
    [_audioPlayer pauseSound:strName];
}

- (void)resumeSound:(NSString *)strName {
    [_audioPlayer resumeSound:strName];
}

- (void)stopSound:(NSString *)strName {
    
    [_audioPlayer stopSound:strName];
}

- (void)unloadSound:(NSString *)strName {
    [_audioPlayer unloadSound:strName];
}

- (void)commonObjectViewStartTrackingFrame:(CGRect)frame {
    
    _commonObjectViewAdded = YES;
    _commonObjectViewSetted = NO;
    
    CGRect rect = frame;
    _rect.left = (rect.origin.x + _margin) / _scale;
    _rect.top = rect.origin.y / _scale;
    _rect.right = (rect.origin.x + rect.size.width + _margin) / _scale;
    _rect.bottom = (rect.origin.y + rect.size.height) / _scale;
    
}

- (void)commonObjectViewFinishTrackingFrame:(CGRect)frame {
    _commonObjectViewAdded = NO;
}

- (st_rotate_type)getRotateType
{
    BOOL isFrontCamera = self.devicePosition == AVCaptureDevicePositionFront;
    BOOL isVideoMirrored = self.isVideoMirrored;
    
    [self getDeviceOrientation:_motionManager.accelerometerData];
    
    switch (_deviceOrientation) {
            
        case UIDeviceOrientationPortrait:
            return ST_CLOCKWISE_ROTATE_0;
            
        case UIDeviceOrientationPortraitUpsideDown:
            return ST_CLOCKWISE_ROTATE_180;
            
        case UIDeviceOrientationLandscapeLeft:
            return ((isFrontCamera && isVideoMirrored) || (!isFrontCamera && !isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_270 : ST_CLOCKWISE_ROTATE_90;
            
        case UIDeviceOrientationLandscapeRight:
            return ((isFrontCamera && isVideoMirrored) || (!isFrontCamera && !isVideoMirrored)) ? ST_CLOCKWISE_ROTATE_90 : ST_CLOCKWISE_ROTATE_270;
            
        default:
            return ST_CLOCKWISE_ROTATE_0;
    }
}

- (void)getDeviceOrientation:(CMAccelerometerData *)accelerometerData {
    if (accelerometerData.acceleration.x >= 0.75) {
        _deviceOrientation = UIDeviceOrientationLandscapeRight;
    } else if (accelerometerData.acceleration.x <= -0.75) {
        _deviceOrientation = UIDeviceOrientationLandscapeLeft;
    } else if (accelerometerData.acceleration.y <= -0.75) {
        _deviceOrientation = UIDeviceOrientationPortrait;
    } else if (accelerometerData.acceleration.y >= 0.75) {
        _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
    } else {
        _deviceOrientation = UIDeviceOrientationPortrait;
    }
}

#pragma mark - lazy load array

- (NSArray *)arrNewStickers {
    if (!_arrNewStickers) {
        _arrNewStickers = [self getStickerModelsByType:STEffectsTypeStickerNew];
    }
    return _arrNewStickers;
}

- (NSArray *)arr2DStickers {
    if (!_arr2DStickers) {
        _arr2DStickers = [self getStickerModelsByType:STEffectsTypeSticker2D];
    }
    return _arr2DStickers;
}

- (NSArray *)arrAvatarStickers {
    
    if (!_arrAvatarStickers) {
        _arrAvatarStickers = [self getStickerModelsByType:STEffectsTypeStickerAvatar];
    }
    return _arrAvatarStickers;
}

- (NSArray *)arr3DStickers {
    if (!_arr3DStickers) {
        _arr3DStickers = [self getStickerModelsByType:STEffectsTypeSticker3D];
    }
    return _arr3DStickers;
}

- (NSArray *)arrGestureStickers {
    if (!_arrGestureStickers) {
        _arrGestureStickers = [self getStickerModelsByType:STEffectsTypeStickerGesture];
    }
    return _arrGestureStickers;
}

- (NSArray *)arrSegmentStickers {
    if (!_arrSegmentStickers) {
        _arrSegmentStickers = [self getStickerModelsByType:STEffectsTypeStickerSegment];
    }
    return _arrSegmentStickers;
}

- (NSArray *)arrFacedeformationStickers {
    if (!_arrFacedeformationStickers) {
        _arrFacedeformationStickers = [self getStickerModelsByType:STEffectsTypeStickerFaceDeformation];
    }
    return _arrFacedeformationStickers;
}

- (NSArray *)arrObjectTrackers {
    if (!_arrObjectTrackers) {
        _arrObjectTrackers = [self getObjectTrackModels];
    }
    return _arrObjectTrackers;
}

- (NSArray *)arrFaceChangeStickers {
    
    if (!_arrFaceChangeStickers) {
        _arrFaceChangeStickers = [self getStickerModelsByType:STEffectsTypeStickerFaceChange];
    }
    return _arrFaceChangeStickers;
}

- (NSArray *)arrParticleStickers {
    
    if (!_arrParticleStickers) {
        _arrParticleStickers = [self getStickerModelsByType:STEffectsTypeStickerParticle];
    }
    return _arrParticleStickers;
}

- (NSArray *)getStickerModelsByType:(STEffectsType)type {
    
    NSArray *stickerZipPaths = [STParamUtil getStickerPathsByType:type];
    
    NSMutableArray *arrModels = [NSMutableArray array];
    
    for (int i = 0; i < stickerZipPaths.count; i ++) {
        
        STCollectionViewDisplayModel *model = [[STCollectionViewDisplayModel alloc] init];
        model.strPath = stickerZipPaths[i];
        
        UIImage *thumbImage = [UIImage imageWithContentsOfFile:[[model.strPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        model.image = thumbImage ? thumbImage : [UIImage imageNamed:@"none.png"];
        model.strName = @"";
        model.index = i;
        model.isSelected = NO;
        model.modelType = type;
        
        [arrModels addObject:model];
    }
    return [arrModels copy];
}

- (NSArray *)getObjectTrackModels {
    
    NSMutableArray *arrModels = [NSMutableArray array];
    
    NSArray *arrImageNames = @[@"object_track_happy", @"object_track_hi", @"object_track_love", @"object_track_star", @"object_track_sticker", @"object_track_sun"];
    
    for (int i = 0; i < arrImageNames.count; ++i) {
        
        STCollectionViewDisplayModel *model = [[STCollectionViewDisplayModel alloc] init];
        model.strPath = NULL;
        model.strName = @"";
        model.index = i;
        model.isSelected = NO;
        model.image = [UIImage imageNamed:arrImageNames[i]];
        model.modelType = STEffectsTypeObjectTrack;
        
        [arrModels addObject:model];
    }
    
    return [arrModels copy];
}

- (void)handleStickerChanged:(STCollectionViewDisplayModel *)model {
    [_lock lock];
    @try {
        self.bSticker = YES;
        _currentModel = model;
        
        if (_isNullSticker) {
            _isNullSticker = NO;
        }
        
        // 获取触发动作类型
        unsigned long long iAction = 0;
        
        const char *stickerPath = [model.strPath UTF8String];
        
        if (!model.isSelected) {
            stickerPath = NULL;
        }
        
        st_result_t iRet = ST_OK;
        iRet = st_mobile_sticker_change_package(_hSticker, stickerPath, NULL);
        
        if (iRet != ST_OK) {
            
            STLog(@"st_mobile_sticker_change_package error %d" , iRet);
        }else{
            
            // 需要在 st_mobile_sticker_change_package 之后调用才可以获取新素材包的 trigger action .
            iRet = st_mobile_sticker_get_trigger_action(_hSticker, &iAction);
            
            if (ST_OK != iRet) {
                
                STLog(@"st_mobile_sticker_get_trigger_action error %d" , iRet);
                
                return;
            }
            
            if (0 != iAction) {//有 trigger信息
                if (CHECK_FLAG(iAction, ST_MOBILE_BROW_JUMP)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeMoveEyebrow];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_EYE_BLINK)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeBlink];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_YAW)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeTurnHead];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_PITCH)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeNod];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_MOUTH_AH)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeOpenMouse];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_GOOD)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandGood];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PALM)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandPalm];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_LOVE)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandLove];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_HOLDUP)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandHoldUp];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_CONGRATULATE)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandCongratulate];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_HEART)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandFingerHeart];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_INDEX)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandFingerIndex];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_OK)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandOK];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_SCISSOR)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandScissor];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PISTOL)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandPistol];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_666)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHand666];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_BLESS)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandBless];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_ILOVEYOU)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandILoveYou];
                }
                if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FIST)) {
                    [self.triggerView showTriggerViewWithType:STTriggerTypeHandFist];
                }
            }
        }
        
        _iCurrentAction = iAction;
        
        _strStickerPath = model.strPath;
    } @finally {
        [_lock unlock];
    }
}

- (STTriggerView *)triggerView {
    
    if (!_triggerView) {
        
        _triggerView = [[STTriggerView alloc] init];
    }
    
    return _triggerView;
}

- (void)cancelStickerAndObjectTrack {
    if (_hSticker) {
        _isNullSticker = YES;
    }
    
    self.bTracker = NO;
    
}

@end
