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
#import "st_mobile_makeup.h"
#import "STEffectsAudioPlayer.h"
#import <CoreMotion/CoreMotion.h>
#import "STParamUtil.h"
#import "STMobileLog.h"
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import "STLock.h"
#import "SenseArMaterialService.h"
#import "STCustomMemoryCache.h"
#import "EffectsCollectionViewCell.h"
#import "STBMPModel.h"

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
{
    st_handle_t _hSticker;  // sticker句柄
    st_handle_t _hDetector; // detector句柄
    st_handle_t _hBeautify; // beautify句柄
    st_handle_t _hAttribute;// attribute句柄
    st_handle_t _hFilter;   // filter句柄
    st_handle_t _animalHandle; //猫脸
    st_handle_t _hBmpHandle;
    
    st_mobile_animal_face_t *_detectResult1;
    
    st_rect_t _rect;  // 通用物体位置
    float _result_score; //通用物体置信度
    
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    st_mobile_106_t *_pFacesDetection; // 检测输出人脸信息数组
#endif
    
    CVOpenGLESTextureCacheRef _cvTextureCache;
    
    CVOpenGLESTextureRef _cvTextureOrigin;
    CVOpenGLESTextureRef _cvTextureBeautify;
    CVOpenGLESTextureRef _cvTextureSticker;
    CVOpenGLESTextureRef _cvTextureFilter;
    CVOpenGLESTextureRef _cvTextureMakeup;
    
    CVPixelBufferRef _cvBeautifyBuffer;
    CVPixelBufferRef _cvStickerBuffer;
    CVPixelBufferRef _cvFilterBuffer;
    CVPixelBufferRef _cvMakeUpBuffer;
    
    GLuint _textureOriginInput;
    GLuint _textureBeautifyOutput;
    GLuint _textureStickerOutput;
    GLuint _textureFilterOutput;
    GLuint _textureMakeUpOutput;
    
    
    st_mobile_human_action_t _detectResult;
}

@property (nonatomic, readwrite, assign) unsigned long long iCurrentAction;
@property (nonatomic, readwrite, assign) unsigned long long makeUpConf;
@property (nonatomic, readwrite, assign) unsigned long long stickerConf;

@property (nonatomic, assign) BOOL bMakeUp;

@property (nonatomic, readwrite, assign) CGFloat imageWidth;
@property (nonatomic, readwrite, assign) CGFloat imageHeight;

@property (nonatomic, strong) EAGLContext *glContext;

@property (nonatomic, assign) CGFloat scale;  //视频充满全屏的缩放比例
@property (nonatomic, assign) int margin;

@property (nonatomic, strong) NSMutableArray *arrPersons;
@property (nonatomic, strong) NSMutableArray *arrPoints;

@property (nonatomic, assign) double lastTimeAttrDetected;

//record
@property (nonatomic, readwrite, strong) dispatch_queue_t callBackQueue;

@property (nonatomic, readwrite, strong) STEffectsAudioPlayer *audioPlayer;

@property (nonatomic, readwrite, assign) BOOL isNullSticker;

@property (nonatomic, strong) NSMutableArray *faceArray;

@property (nonatomic) dispatch_queue_t changeStickerQueue;


@property (nonatomic, copy) NSString *preFilterModelPath;
@property (nonatomic, copy) NSString *curFilterModelPath;

@property (nonatomic, copy) NSString *strBodyAction;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic) UIDeviceOrientation deviceOrientation;

@property (nonatomic , strong) STLock *detectResultLock;

@property (nonatomic , strong) NSData *licenseData;

@property (nonatomic) dispatch_queue_t thumbDownlaodQueue;
@property (nonatomic, strong) NSOperationQueue *imageLoadQueue;
@property (nonatomic , strong) NSFileManager *fManager;
@property (nonatomic , copy) NSString *strThumbnailPath;

@property (nonatomic, assign) BOOL needDetectAnimal;
@property (nonatomic, assign) BOOL resourcesInited;
@property (nonatomic , strong) EffectsCollectionViewCellModel *prepareModel;

@property (nonatomic, strong) STBMPModel *bmp_Current_Model;
@property (nonatomic, strong) STBMPModel *bmp_Eye_Model;
@property (nonatomic, strong) STBMPModel *bmp_EyeLiner_Model;
@property (nonatomic, strong) STBMPModel *bmp_EyeLash_Model;
@property (nonatomic, strong) STBMPModel *bmp_Lip_Model;
@property (nonatomic, strong) STBMPModel *bmp_Brow_Model;
@property (nonatomic, strong) STBMPModel *bmp_Nose_Model;
@property (nonatomic, strong) STBMPModel *bmp_Face_Model;
@property (nonatomic, strong) STBMPModel *bmp_Blush_Model;
@property (nonatomic, strong) STBMPModel *bmp_Eyeball_Model;

@end

@implementation STManager

+ (instancetype)sharedManager {
    static STManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)createResources {
    [self setDefaultValue];
    [self setupUtilTools];
    [self setupThumbnailCache];
    [self setupSenseArService];
}

- (void)releaseResources {
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    if (_hSticker) {
        
        st_result_t iRet = ST_OK;
        iRet = st_mobile_sticker_remove_avatar_model(_hSticker);
        if (iRet != ST_OK) {
            NSLog(@"remove avatar model failed: %d", iRet);
        }
        st_mobile_sticker_destroy(_hSticker);
        _hSticker = NULL;
    }
    if (_hBeautify) {
        
        st_mobile_beautify_destroy(_hBeautify);
        _hBeautify = NULL;
    }
    
    if (_animalHandle) {
        st_mobile_tracker_animal_face_destroy(_animalHandle);
        _animalHandle = NULL;
    }
    
    if (_hDetector) {
        
        st_mobile_human_action_destroy(_hDetector);
        _hDetector = NULL;
    }
    
    if (_hAttribute) {
        
        st_mobile_face_attribute_destroy(_hAttribute);
        _hAttribute = NULL;
    }
    
    if (_hBmpHandle) {
        st_mobile_makeup_destroy(_hBmpHandle);
        _hBmpHandle = NULL;
    }
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    if (_pFacesDetection) {
        
        free(_pFacesDetection);
        _pFacesDetection = NULL;
    }
#endif
    
    if (_hFilter) {
        
        st_mobile_gl_filter_destroy(_hFilter);
        _hFilter = NULL;
    }
    
    [self releaseResultTexture];
    
    if (_cvTextureCache) {
        
        CFRelease(_cvTextureCache);
        _cvTextureCache = NULL;
    }
    
    //    glFinish();
    
    [EAGLContext setCurrentContext:nil];
    
    self.glContext = nil;
}

- (void)setDefaultValue {
    
    self.bAttribute = NO;
    self.bBeauty = YES;
    self.bFilter = NO;
    self.bSticker = NO;
    self.needDetectAnimal = NO;
    
    self.isNullSticker = NO;
    
    self.fFilterStrength = 0.65;
    
    self.iCurrentAction = 0;
    
    self.imageWidth = 720;
    self.imageHeight = 1280;
    
    self.changeStickerQueue = dispatch_queue_create("com.sensetime.changestickerqueue", NULL);
    
    self.preFilterModelPath = nil;
    self.curFilterModelPath = nil;
        
    self.microSurgeryModels = @[
                                getModel([UIImage imageNamed:@"zhailian"], [UIImage imageNamed:@"zhailian_selected"], @"瘦脸型", 0, NO, 0, STEffectsTypeBeautyMicroSurgery, STBeautyTypeThinFaceShape),
                                getModel([UIImage imageNamed:@"xiaba"], [UIImage imageNamed:@"xiaba_selected"], @"下巴", 0, NO, 1, STEffectsTypeBeautyMicroSurgery, STBeautyTypeChin),
                                getModel([UIImage imageNamed:@"etou"], [UIImage imageNamed:@"etou_selected"], @"额头", 0, NO, 2, STEffectsTypeBeautyMicroSurgery, STBeautyTypeHairLine),
                                getModel([UIImage imageNamed:@"苹果机-白"], [UIImage imageNamed:@"苹果机-紫"], @"苹果肌", 0, NO, 3, STEffectsTypeBeautyMicroSurgery, STBeautyTypeAppleMusle),
                                getModel([UIImage imageNamed:@"shoubiyi"], [UIImage imageNamed:@"shoubiyi_selected"], @"瘦鼻翼", 0, NO, 4, STEffectsTypeBeautyMicroSurgery, STBeautyTypeNarrowNose),
                                getModel([UIImage imageNamed:@"changbi"], [UIImage imageNamed:@"changbi_selected"], @"长鼻", 0, NO, 5, STEffectsTypeBeautyMicroSurgery, STBeautyTypeLengthNose),
                                getModel([UIImage imageNamed:@"侧脸隆鼻-白"], [UIImage imageNamed:@"侧脸隆鼻-紫"], @"侧脸隆鼻", 0, NO, 6, STEffectsTypeBeautyMicroSurgery, STBeautyTypeProfileRhinoplasty),
                                getModel([UIImage imageNamed:@"zuixing"], [UIImage imageNamed:@"zuixing_selected"], @"嘴形", 0, NO, 7, STEffectsTypeBeautyMicroSurgery, STBeautyTypeMouthSize),
                                getModel([UIImage imageNamed:@"suorenzhong"], [UIImage imageNamed:@"suorenzhong_selected"], @"缩人中", 0, NO, 8, STEffectsTypeBeautyMicroSurgery, STBeautyTypeLengthPhiltrum),
                                getModel([UIImage imageNamed:@"眼睛距离调整-白"], [UIImage imageNamed:@"眼睛距离调整-紫"], @"眼距", 0, NO, 9, STEffectsTypeBeautyMicroSurgery, STBeautyTypeEyeDistance),
                                getModel([UIImage imageNamed:@"眼睛角度微调-白"], [UIImage imageNamed:@"眼睛角度微调-紫"], @"眼睛角度", 0, NO, 10, STEffectsTypeBeautyMicroSurgery, STBeautyTypeEyeAngle),
                                getModel([UIImage imageNamed:@"开眼角-白"], [UIImage imageNamed:@"开眼角-紫"], @"开眼角", 0, NO, 11, STEffectsTypeBeautyMicroSurgery, STBeautyTypeOpenCanthus),
                                getModel([UIImage imageNamed:@"亮眼-白"], [UIImage imageNamed:@"亮眼-紫"], @"亮眼", 0, NO, 12, STEffectsTypeBeautyMicroSurgery, STBeautyTypeBrightEye),
                                getModel([UIImage imageNamed:@"去黑眼圈-白"], [UIImage imageNamed:@"去黑眼圈-紫"], @"祛黑眼圈", 0, NO, 13, STEffectsTypeBeautyMicroSurgery, STBeautyTypeRemoveDarkCircles),
                                getModel([UIImage imageNamed:@"去法令纹-白"], [UIImage imageNamed:@"去法令纹-紫"], @"祛法令纹", 0, NO, 14, STEffectsTypeBeautyMicroSurgery, STBeautyTypeRemoveNasolabialFolds),
                                getModel([UIImage imageNamed:@"牙齿美白-白"], [UIImage imageNamed:@"牙齿美白-紫"], @"白牙", 0, NO, 15, STEffectsTypeBeautyMicroSurgery, STBeautyTypeWhiteTeeth),
                                ];
    
    self.baseBeautyModels = @[
                              getModel([UIImage imageNamed:@"meibai"], [UIImage imageNamed:@"meibai_selected"], @"美白", 2, NO, 0, STEffectsTypeBeautyBase, STBeautyTypeWhiten),
                              getModel([UIImage imageNamed:@"hongrun"], [UIImage imageNamed:@"hongrun_selected"], @"红润", 36, NO, 1, STEffectsTypeBeautyBase, STBeautyTypeRuddy),
                              getModel([UIImage imageNamed:@"mopi"], [UIImage imageNamed:@"mopi_selected"], @"磨皮", 74, NO, 2, STEffectsTypeBeautyBase, STBeautyTypeDermabrasion),
                              getModel([UIImage imageNamed:@"qugaoguang"], [UIImage imageNamed:@"qugaoguang_selected"], @"去高光", 0, NO, 3, STEffectsTypeBeautyBase, STBeautyTypeDehighlight),
                              ];
    self.beautyShapeModels = @[
                               getModel([UIImage imageNamed:@"shoulian"], [UIImage imageNamed:@"shoulian_selected"], @"瘦脸", 11, NO, 0, STEffectsTypeBeautyShape, STBeautyTypeShrinkFace),
                               getModel([UIImage imageNamed:@"dayan"], [UIImage imageNamed:@"dayan_selected"], @"大眼", 13, NO, 1, STEffectsTypeBeautyShape, STBeautyTypeEnlargeEyes),
                               getModel([UIImage imageNamed:@"xiaolian"], [UIImage imageNamed:@"xiaolian_selected"], @"小脸", 10, NO, 2, STEffectsTypeBeautyShape, STBeautyTypeShrinkJaw),
                               getModel([UIImage imageNamed:@"zhailian2"], [UIImage imageNamed:@"zhailian2_selected"], @"窄脸", 0, NO, 3, STEffectsTypeBeautyShape, STBeautyTypeNarrowFace),
                               getModel([UIImage imageNamed:@"round"], [UIImage imageNamed:@"round_selected"], @"圆眼", 0, NO, 4, STEffectsTypeBeautyShape, STBeautyTypeRoundEye)
                               ];
    self.adjustModels = @[
                          getModel([UIImage imageNamed:@"contrast"], [UIImage imageNamed:@"contrast_selected"], @"对比度", 0, NO, 0, STEffectsTypeBeautyAdjust, STBeautyTypeContrast),
                          getModel([UIImage imageNamed:@"saturation"], [UIImage imageNamed:@"saturation_selected"], @"饱和度", 0, NO, 1, STEffectsTypeBeautyAdjust, STBeautyTypeSaturation),
                          ];
    
    _bmp_Eye_Value = _bmp_EyeLiner_Value = _bmp_EyeLash_Value = _bmp_Lip_Value = _bmp_Brow_Value = _bmp_Nose_Value = _bmp_Face_Value =_bmp_Blush_Value = _bmp_Eyeball_Value = 0.8;
}

- (void)setupThumbnailCache
{
    self.thumbDownlaodQueue = dispatch_queue_create("com.sensetime.thumbDownloadQueue", NULL);
    self.imageLoadQueue = [[NSOperationQueue alloc] init];
    self.imageLoadQueue.maxConcurrentOperationCount = 20;
    
    self.thumbnailCache = [[STCustomMemoryCache alloc] init];
    self.fManager = [[NSFileManager alloc] init];
    
    // 可以根据实际情况实现素材列表缩略图的缓存策略 , 这里仅做演示 .
    self.strThumbnailPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"senseme_thumbnail"];
    
    NSError *error = nil;
    BOOL bCreateSucceed = [self.fManager createDirectoryAtPath:self.strThumbnailPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error];
    if (!bCreateSucceed || error) {
        
        STLog(@"create thumbnail cache directory failed !");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"创建列表图片缓存文件夹失败" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        
        [alert show];
    }
}

- (void)resetSettings {
    self.fFilterStrength = 0.65;
    
    self.currentSelectedFilterModel.isSelected = NO;
    
    self.fSmoothStrength = 0.74;
    self.fReddenStrength = 0.36;
    self.fWhitenStrength = 0.02;
    self.fDehighlightStrength = 0.0;
    
    self.fEnlargeEyeStrength = 0.13;
    self.fShrinkFaceStrength = 0.11;
    self.fShrinkJawStrength = 0.10;
    self.fThinFaceShapeStrength = 0.0;
    
    self.fChinStrength = 0.0;
    self.fHairLineStrength = 0.0;
    self.fNarrowNoseStrength = 0.0;
    self.fLongNoseStrength = 0.0;
    self.fMouthStrength = 0.0;
    self.fPhiltrumStrength = 0.0;
    
    self.fEyeDistanceStrength = 0.0;
    self.fEyeAngleStrength = 0.0;
    self.fOpenCanthusStrength = 0.0;
    self.fProfileRhinoplastyStrength = 0.0;
    self.fBrightEyeStrength = 0.0;
    self.fRemoveDarkCirclesStrength = 0.0;
    self.fRemoveNasolabialFoldsStrength = 0.0;
    self.fWhiteTeethStrength = 0.0;
    self.fAppleMusleStrength = 0.0;
    
    self.fContrastStrength = 0.0;
    self.fSaturationStrength = 0.0;
    
    self.baseBeautyModels[0].beautyValue = 2;
    self.baseBeautyModels[0].selected = NO;
    self.baseBeautyModels[1].beautyValue = 36;
    self.baseBeautyModels[1].selected = NO;
    self.baseBeautyModels[2].beautyValue = 74;
    self.baseBeautyModels[2].selected = NO;
    self.baseBeautyModels[3].beautyValue = 0;
    self.baseBeautyModels[3].selected = NO;
    
    self.microSurgeryModels[0].beautyValue = 0;
    self.microSurgeryModels[0].selected = NO;
    self.microSurgeryModels[1].beautyValue = 0;
    self.microSurgeryModels[1].selected = NO;
    self.microSurgeryModels[2].beautyValue = 0;
    self.microSurgeryModels[2].selected = NO;
    self.microSurgeryModels[3].beautyValue = 0;
    self.microSurgeryModels[3].selected = NO;
    self.microSurgeryModels[4].beautyValue = 0;
    self.microSurgeryModels[4].selected = NO;
    self.microSurgeryModels[5].beautyValue = 0;
    self.microSurgeryModels[5].selected = NO;
    self.microSurgeryModels[6].beautyValue = 0;
    self.microSurgeryModels[6].selected = NO;
    self.microSurgeryModels[7].beautyValue = 0;
    self.microSurgeryModels[7].selected = NO;
    self.microSurgeryModels[8].beautyValue = 0;
    self.microSurgeryModels[8].selected = NO;
    self.microSurgeryModels[9].beautyValue = 0;
    self.microSurgeryModels[9].selected = NO;
    self.microSurgeryModels[10].beautyValue = 0;
    self.microSurgeryModels[10].selected = NO;
    self.microSurgeryModels[11].beautyValue = 0;
    self.microSurgeryModels[11].selected = NO;
    self.microSurgeryModels[12].beautyValue = 0;
    self.microSurgeryModels[12].selected = NO;
    self.microSurgeryModels[13].beautyValue = 0;
    self.microSurgeryModels[13].selected = NO;
    self.microSurgeryModels[14].beautyValue = 0;
    self.microSurgeryModels[14].selected = NO;
    self.microSurgeryModels[15].beautyValue = 0;
    self.microSurgeryModels[15].selected = NO;
    
    self.beautyShapeModels[0].beautyValue = 11;
    self.beautyShapeModels[0].selected = NO;
    self.beautyShapeModels[1].beautyValue = 13;
    self.beautyShapeModels[1].selected = NO;
    self.beautyShapeModels[2].beautyValue = 10;
    self.beautyShapeModels[2].selected = NO;
    
    self.adjustModels[0].beautyValue = 0;
    self.adjustModels[0].selected = NO;
    self.adjustModels[1].beautyValue = 0;
    self.adjustModels[1].selected = NO;
    
    self.preFilterModelPath = nil;
    self.curFilterModelPath = nil;
}

- (void)setupUtilTools {
    
    self.audioPlayer = [[STEffectsAudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    
    messageManager = [[STEffectsMessageManager alloc] init];
    messageManager.delegate = self;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.5;
    self.motionManager.deviceMotionUpdateInterval = 1 / 25.0;
}

- (void)setupCameraAndPreview {
    _result_score = 0.0;
    
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
}

- (void)setupSenseArService {
    
    STWeakSelf;
    [[SenseArMaterialService sharedInstance]
     authorizeWithAppID:@"6dc0af51b69247d0af4b0a676e11b5ee"
     appKey:@"e4156e4d61b040d2bcbf896c798d06e3"
     onSuccess:^{
         
#if USE_ONLINE_ACTIVATION
#else
         weakSelf.licenseData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SENSEME" ofType:@"lic"]];
#endif
         dispatch_async(dispatch_get_main_queue(), ^{
             
             [weakSelf initResourceAndStartPreview];
         });
         
         [[SenseArMaterialService sharedInstance] setMaxCacheSize:120000000];
         [weakSelf fetchLists];
     }
     onFailure:^(SenseArAuthorizeError iErrorCode) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
             
             switch (iErrorCode) {
                     
                 case AUTHORIZE_ERROR_KEY_NOT_MATCHED:
                 {
                     [alert setMessage:@"无效 AppID/SDKKey"];
                 }
                     break;
                     
                     
                 case AUTHORIZE_ERROR_NETWORK_NOT_AVAILABLE:
                 {
                     [alert setMessage:@"网络不可用"];
                 }
                     break;
                     
                 case AUTHORIZE_ERROR_DECRYPT_FAILED:
                 {
                     [alert setMessage:@"解密失败"];
                 }
                     break;
                     
                 case AUTHORIZE_ERROR_DATA_PARSE_FAILED:
                 {
                     [alert setMessage:@"解析失败"];
                 }
                     break;
                     
                 case AUTHORIZE_ERROR_UNKNOWN:
                 {
                     [alert setMessage:@"未知错误"];
                 }
                     break;
                     
                 default:
                     break;
             }
             
             [alert show];
         });
     }];
}

- (void)fetchLists
{
    self.effectsDataSource = [[STCustomMemoryCache alloc] init];
    
    NSString *strLocalBundlePath = [[NSBundle mainBundle] pathForResource:@"my_sticker" ofType:@"bundle"];
    
    if (strLocalBundlePath) {
        
        NSMutableArray *arrLocalModels = [NSMutableArray array];
        
        NSFileManager *fManager = [[NSFileManager alloc] init];
        
        NSArray *arrFiles = [fManager contentsOfDirectoryAtPath:strLocalBundlePath error:nil];
        
        int indexOfItem = 0;
        for (NSString *strFileName in arrFiles) {
            
            if ([strFileName hasSuffix:@".zip"]) {
                
                NSString *strMaterialPath = [strLocalBundlePath stringByAppendingPathComponent:strFileName];
                NSString *strThumbPath = [[strMaterialPath stringByDeletingPathExtension] stringByAppendingString:@".png"];
                UIImage *imageThumb = [UIImage imageWithContentsOfFile:strThumbPath];
                
                if (!imageThumb) {
                    
                    imageThumb = [UIImage imageNamed:@"none"];
                }
                
                EffectsCollectionViewCellModel *model = [[EffectsCollectionViewCellModel alloc] init];
                
                model.iEffetsType = STEffectsTypeStickerMy;
                model.state = Downloaded;
                model.indexOfItem = indexOfItem;
                model.imageThumb = imageThumb;
                model.strMaterialPath = strMaterialPath;
                
                [arrLocalModels addObject:model];
                
                indexOfItem ++;
            }
        }
        
        NSString *strDocumentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
        NSString *localStickerPath = [strDocumentsPath stringByAppendingPathComponent:@"local_sticker"];
        if (![fManager fileExistsAtPath:localStickerPath]) {
            [fManager createDirectoryAtPath:localStickerPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSArray *arrFileNames = [fManager contentsOfDirectoryAtPath:localStickerPath error:nil];
        
        for (NSString *strFileName in arrFileNames) {
            
            if ([strFileName hasSuffix:@"zip"]) {
                
                NSString *strMaterialPath = [localStickerPath stringByAppendingPathComponent:strFileName];
                NSString *strThumbPath = [[strMaterialPath stringByDeletingPathExtension] stringByAppendingString:@".png"];
                UIImage *imageThumb = [UIImage imageWithContentsOfFile:strThumbPath];
                
                if (!imageThumb) {
                    
                    imageThumb = [UIImage imageNamed:@"none"];
                }
                
                EffectsCollectionViewCellModel *model = [[EffectsCollectionViewCellModel alloc] init];
                
                model.iEffetsType = STEffectsTypeStickerMy;
                model.state = Downloaded;
                model.indexOfItem = indexOfItem;
                model.imageThumb = imageThumb;
                model.strMaterialPath = strMaterialPath;
                
                [arrLocalModels addObject:model];
                
                indexOfItem ++;
            }
        }
        
        [self.effectsDataSource setObject:arrLocalModels
                                   forKey:@(STEffectsTypeStickerMy)];
        
        if ([_delegate respondsToSelector:@selector(manager:fetchListDone:)]) {
            [_delegate manager:self fetchListDone:arrLocalModels];
        }
    }
    
    [self fetchMaterialsAndReloadDataWithGroupID:@"ff81fc70f6c111e899f602f2be7c2171"
                                            type:STEffectsTypeStickerNew];
    [self fetchMaterialsAndReloadDataWithGroupID:@"3cd2dae0f6c211e8877702f2beb67403"
                                            type:STEffectsTypeSticker2D];
    [self fetchMaterialsAndReloadDataWithGroupID:@"46028a20f6c211e888ea020d88863a42"
                                            type:STEffectsTypeStickerAvatar];
    [self fetchMaterialsAndReloadDataWithGroupID:@"4e869010f6c211e888ea020d88863a42"
                                            type:STEffectsTypeSticker3D];
    [self fetchMaterialsAndReloadDataWithGroupID:@"5aea6840f6c211e899f602f2be7c2171"
                                            type:STEffectsTypeStickerGesture];
    [self fetchMaterialsAndReloadDataWithGroupID:@"65365cf0f6c211e8877702f2beb67403"
                                            type:STEffectsTypeStickerSegment];
    [self fetchMaterialsAndReloadDataWithGroupID:@"6d036ef0f6c211e899f602f2be7c2171"
                                            type:STEffectsTypeStickerFaceDeformation];
    [self fetchMaterialsAndReloadDataWithGroupID:@"73bffb50f6c211e899f602f2be7c2171"
                                            type:STEffectsTypeStickerFaceChange];
    [self fetchMaterialsAndReloadDataWithGroupID:@"7c6089f0f6c211e8877702f2beb67403"
                                            type:STEffectsTypeStickerParticle];
}

- (void)fetchMaterialsAndReloadDataWithGroupID:(NSString *)strGroupID
                                          type:(STEffectsType)iType
{
    __weak typeof(self) weakSelf = self;
    
    [[SenseArMaterialService sharedInstance]
     fetchMaterialsWithUserID:@"testUserID"
     GroupID:strGroupID
     onSuccess:^(NSArray<SenseArMaterial *> *arrMaterials) {
         
         NSMutableArray *arrModels = [NSMutableArray array];
         
         for (int i = 0; i < arrMaterials.count; i ++) {
             
             SenseArMaterial *material = [arrMaterials objectAtIndex:i];
             
             EffectsCollectionViewCellModel *model = [[EffectsCollectionViewCellModel alloc] init];
             
             model.material = material;
             model.indexOfItem = i;
             model.state = [[SenseArMaterialService sharedInstance] isMaterialDownloaded:material] ? Downloaded : NotDownloaded;
             model.iEffetsType = iType;
             
             if (material.strMaterialPath) {
                 
                 model.strMaterialPath = material.strMaterialPath;
             }
             
             [arrModels addObject:model];
         }
         
         [weakSelf.effectsDataSource setObject:arrModels forKey:@(iType)];
         
         if ([weakSelf.delegate respondsToSelector:@selector(manager:fetchMaterialSuccess:)]) {
             [weakSelf.delegate manager:weakSelf fetchMaterialSuccess:iType];
         }
         
         for (EffectsCollectionViewCellModel *model in arrModels) {
             
             dispatch_async(weakSelf.thumbDownlaodQueue, ^{
                 
                 [weakSelf cacheThumbnailOfModel:model];
             });
         }
     } onFailure:^(int iErrorCode, NSString *strMessage)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
             
             //             [alert setMessage:[NSString stringWithFormat:@"获取贴纸列表失败 , %@" , strMessage]];
             [alert setMessage:@"获取贴纸列表失败"];
             
             [alert show];
         });
     }];
}

- (void)cacheThumbnailOfModel:(EffectsCollectionViewCellModel *)model
{
    NSString *strFileID = model.material.strMaterialFileID;
    
    id cacheObj = [self.thumbnailCache objectForKey:strFileID];
    
    if (!cacheObj || ![cacheObj isKindOfClass:[UIImage class]]) {
        
        NSString *strThumbnailImagePath = [self.strThumbnailPath stringByAppendingPathComponent:strFileID];
        
        if (![self.fManager fileExistsAtPath:strThumbnailImagePath]) {
            
            [self.thumbnailCache setObject:strFileID forKey:strFileID];
            
            __weak typeof(self) weakSelf = self;
            
            [weakSelf.imageLoadQueue addOperationWithBlock:^{
                
                UIImage *imageDownloaded = nil;
                
                if ([model.material.strThumbnailURL isKindOfClass:[NSString class]]) {
                    
                    NSError *error = nil;
                    
                    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:model.material.strThumbnailURL] options:NSDataReadingMappedIfSafe error:&error];
                    
                    imageDownloaded = [UIImage imageWithData:imageData];
                    
                    if (imageDownloaded) {
                        
                        if ([weakSelf.fManager createFileAtPath:strThumbnailImagePath contents:imageData attributes:nil]) {
                            
                            [weakSelf.thumbnailCache setObject:imageDownloaded forKey:strFileID];
                        }else{
                            
                            [weakSelf.thumbnailCache removeObjectForKey:strFileID];
                        }
                    }else{
                        
                        [weakSelf.thumbnailCache removeObjectForKey:strFileID];
                    }
                }else{
                    
                    [weakSelf.thumbnailCache removeObjectForKey:strFileID];
                }
                
                model.imageThumb = imageDownloaded;
                
                if ([weakSelf.delegate respondsToSelector:@selector(manager:cachedThumbnail:)]) {
                    [weakSelf.delegate manager:weakSelf cachedThumbnail:model];
                }
            }];
        }else{
            
            UIImage *image = [UIImage imageWithContentsOfFile:strThumbnailImagePath];
            
            if (image) {
                
                [self.thumbnailCache setObject:image forKey:strFileID];
                
            }else{
                
                [self.fManager removeItemAtPath:strThumbnailImagePath error:nil];
            }
        }
    }
}

- (void)initResourceAndStartPreview
{
    ///ST_MOBILE：设置预览时需要注意 EAGLContext 的初始化
    [self setupCameraAndPreview];
    
    // 设置SDK OpenGL 环境 , 只有在正确的 OpenGL 环境下 SDK 才会被正确初始化 .
    [EAGLContext setCurrentContext:self.glContext];
    
    // 初始化结果文理及纹理缓存
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_cvTextureCache);
    
    if (err) {
        
        NSLog(@"CVOpenGLESTextureCacheCreate %d" , err);
    }
    
    [self initResultTexture];
    
    [self resetSettings];
    
    ///ST_MOBILE：初始化句柄之前需要验证License
    if ([self checkActiveCodeWithData:self.licenseData]) {
        ///ST_MOBILE：初始化相关的句柄
        [self setupHandle];
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"使用 license 文件生成激活码时失败，可能是授权文件过期。" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
    
    if ([self.motionManager isAccelerometerAvailable]) {
        [self.motionManager startAccelerometerUpdates];
    }
    
    if ([self.motionManager isDeviceMotionAvailable]) {
        [self.motionManager startDeviceMotionUpdates];
    }
    _resourcesInited = YES;
}

- (BOOL)checkActiveCodeWithData:(NSData *)dataLicense
{
    NSString *strKeyActiveCode = @"ACTIVE_CODE_ONLINE";
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *strActiveCode = [userDefaults objectForKey:strKeyActiveCode];
    st_result_t iRet = ST_E_FAIL;
    
    iRet = st_mobile_check_activecode_from_buffer(
                                                  [dataLicense bytes],
                                                  (int)[dataLicense length],
                                                  strActiveCode.UTF8String,
                                                  (int)[strActiveCode length]
                                                  );
    
    if (ST_OK == iRet) {
        
        return YES;
    }
    
    char active_code[1024];
    int active_code_len = 1024;
    
    iRet = st_mobile_generate_activecode_from_buffer(
                                                     [dataLicense bytes],
                                                     (int)[dataLicense length],
                                                     active_code,
                                                     &active_code_len
                                                     );
    
    strActiveCode = [[NSString alloc] initWithUTF8String:active_code];
    
    
    if (iRet == ST_OK && strActiveCode.length) {
        
        [userDefaults setObject:strActiveCode forKey:strKeyActiveCode];
        [userDefaults synchronize];
        
        return YES;
    }
    
    return NO;
}

- (void)setupHandle {
    
    st_result_t iRet = ST_OK;
    
    //初始化检测模块句柄
    NSString *strModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Face_Video_5.3.3" ofType:@"model"];
    
    uint32_t config = ST_MOBILE_HUMAN_ACTION_DEFAULT_CONFIG_VIDEO;
    
    TIMELOG(key);
    
    iRet = st_mobile_human_action_create(strModelPath.UTF8String, config, &_hDetector);
    
    TIMEPRINT(key,"human action create time:");
    
    if (ST_OK != iRet || !_hDetector) {
        
        NSLog(@"st mobile human action create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"算法SDK初始化失败，可能是模型路径错误，SDK权限过期，与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    } else {
        
        addSubModel(_hDetector, @"M_SenseME_Face_Extra_5.23.0");
        addSubModel(_hDetector, @"M_SenseME_Iris_2.0.0");
        addSubModel(_hDetector, @"M_SenseME_Hand_5.4.0");
        addSubModel(_hDetector, @"M_SenseME_Segment_1.5.0");
        addSubModel(_hDetector, @"M_SenseME_Avatar_Help_new");
#if TEST_BODY_BEAUTY
        addSubModel(_hDetector, @"M_SenseME_Body_Contour_73_1.2.0");
#endif
    }
    
    //猫脸检测
    NSString *catFaceModel = [[NSBundle mainBundle] pathForResource:@"M_SenseME_CatFace_2.0.0" ofType:@"model"];
    
    TIMELOG(keyCat);
    
    iRet = st_mobile_tracker_animal_face_create(catFaceModel.UTF8String, ST_MOBILE_TRACKING_MULTI_THREAD, &_animalHandle);
    
    TIMEPRINT(keyCat, "cat handle create time:")
    
    if (iRet != ST_OK || !_animalHandle) {
        NSLog(@"st mobile tracker animal face create failed: %d", iRet);
    }
#if TEST_AVATAR_EXPRESSION
    //avatar expression
    //如要获取avatar表情信息，需创建avatar句柄
    NSString *strAvatarModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Avatar_Core_2.0.0" ofType:@"model"];
    iRet = st_mobile_avatar_create(&_avatarHandle, strAvatarModelPath.UTF8String);
    if (iRet != ST_OK) {
        NSLog(@"st mobile avatar create failed: %d", iRet);
    } else {
        //然后获取此功能需要human action检测的参数(即st_mobile_human_action_detect接口需要传入的config参数，例如avatar需要获取眼球关键点信息，st_mobile_avatar_get_detect_config就会返回眼球检测的config，通常会返回多个检测的`|`)
        self.avatarConfig = st_mobile_avatar_get_detect_config(_avatarHandle);
    }
#endif
    
    //初始化贴纸模块句柄 , 默认开始时无贴纸 , 所以第一个路径参数传空
    TIMELOG(keySticker);
    
    iRet = st_mobile_sticker_create(&_hSticker);
    
    TIMEPRINT(keySticker, "sticker create time:");
    
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
        
        NSString *strAvatarModelPath = [[NSBundle mainBundle] pathForResource:@"M_SenseME_Avatar_Core_2.0.0" ofType:@"model"];
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
        
        //        setBeautifyParam(_hBeautify, ST_BEAUTIFY_SMOOTH_MODE, 0.0);
        
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
        //瘦脸型
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_THIN_FACE_SHAPE_RATIO, self.fThinFaceShapeStrength);
        //窄脸
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_NARROW_FACE_STRENGTH, self.fNarrowFaceStrength);
        //圆眼
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_ROUND_EYE_RATIO, self.fRoundEyeStrength);
        //下巴
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_CHIN_LENGTH_RATIO, self.fChinStrength);
        //额头
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_HAIRLINE_HEIGHT_RATIO, self.fHairLineStrength);
        //瘦鼻翼
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_NARROW_NOSE_RATIO, self.fNarrowNoseStrength);
        //长鼻
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_NOSE_LENGTH_RATIO, self.fLongNoseStrength);
        //嘴形
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_MOUTH_SIZE_RATIO, self.fMouthStrength);
        //缩人中
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_PHILTRUM_LENGTH_RATIO, self.fPhiltrumStrength);
        
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_APPLE_MUSLE_RATIO, self.fAppleMusleStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_PROFILE_RHINOPLASTY_RATIO, self.fProfileRhinoplastyStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_EYE_DISTANCE_RATIO, self.fEyeDistanceStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_EYE_ANGLE_RATIO, self.fEyeAngleStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_OPEN_CANTHUS_RATIO, self.fOpenCanthusStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_BRIGHT_EYE_RATIO, self.fBrightEyeStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_REMOVE_DARK_CIRCLES_RATIO, self.fRemoveDarkCirclesStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_REMOVE_NASOLABIAL_FOLDS_RATIO, self.fRemoveNasolabialFoldsStrength);
        setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_WHITE_TEETH_RATIO, self.fWhiteTeethStrength);
        
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
    
    //create beautyMakeUp handle
    iRet = st_mobile_makeup_create(&_hBmpHandle);
    
    if (ST_OK != iRet || !_hBmpHandle) {
        
        NSLog(@"st mobile object makeup create failed: %d", iRet);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误提示" message:@"美妆SDK初始化失败，可能是SDK权限过期或与绑定包名不符" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil];
        
        [alert show];
    }
}

- (void)setFFilterStrength:(float)fFilterStrength {
    _fFilterStrength = fFilterStrength;
    if (_hFilter) {
        
        st_result_t iRet = ST_OK;
        iRet = st_mobile_gl_filter_set_param(_hFilter, ST_GL_FILTER_STRENGTH, fFilterStrength);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_gl_filter_set_param %d" , iRet);
        }
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
    if (!_resourcesInited) {
        return pixelBuffer;
    }
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
    
    st_mobile_human_action_t detectResult;
    memset(&detectResult, 0, sizeof(st_mobile_human_action_t));
    st_result_t iRet = ST_OK;
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    int iFaceCount = 0;
#endif
    
    _faceArray = [NSMutableArray array];
    
    // 如果需要做属性,每隔一秒做一次属性
    double dTimeNow = CFAbsoluteTimeGetCurrent();
    BOOL isAttributeTime = (dTimeNow - self.lastTimeAttrDetected) >= 1.0;
    
    if (isAttributeTime) {
        
        self.lastTimeAttrDetected = dTimeNow;
    }
    
    
    int catFaceCount = -1;
    ///cat face
    if (_needDetectAnimal && _animalHandle) {
        
        st_result_t iRet = st_mobile_tracker_animal_face_track(_animalHandle, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, stMobileRotate, &_detectResult1, &catFaceCount);
        
        if (iRet != ST_OK) {
            NSLog(@"st mobile animal face tracker failed: %d", iRet);
        } else {
            //            NSLog(@"cat face count: %d", catFaceCount);
        }
        
    }
    
    ///ST_MOBILE 人脸信息检测部分
    if (_hDetector) {
        
        BOOL needFaceDetection = ((self.fEnlargeEyeStrength != 0 || self.fShrinkFaceStrength != 0 || self.fShrinkJawStrength != 0 || self.fThinFaceShapeStrength != 0 || self.fNarrowFaceStrength != 0 || self.fRoundEyeStrength != 0 || self.fChinStrength != 0 || self.fHairLineStrength != 0 || self.fNarrowNoseStrength != 0 || self.fLongNoseStrength != 0 || self.fMouthStrength != 0 || self.fPhiltrumStrength != 0 || self.fEyeDistanceStrength != 0 || self.fEyeAngleStrength != 0 || self.fOpenCanthusStrength != 0 || self.fProfileRhinoplastyStrength != 0 || self.fBrightEyeStrength != 0 || self.fRemoveDarkCirclesStrength != 0 || self.fRemoveNasolabialFoldsStrength != 0 || self.fWhiteTeethStrength != 0 || self.fAppleMusleStrength != 0) && _hBeautify) || (self.bAttribute && isAttributeTime && _hAttribute);
        
        if (needFaceDetection) {
#if TEST_AVATAR_EXPRESSION
            self.iCurrentAction |= ST_MOBILE_FACE_DETECT | self.avatarConfig;
#else
            self.iCurrentAction = ST_MOBILE_FACE_DETECT | self.makeUpConf | self.stickerConf;
#endif
        } else {
            
            self.iCurrentAction = self.makeUpConf | self.stickerConf;
        }
        
        //        NSLog(@"current config: %llx", _iCurrentAction);
        
#if TEST_BODY_BEAUTY
        self.iCurrentAction |= ST_MOBILE_BODY_KEYPOINTS | ST_MOBILE_BODY_CONTOUR;
#endif
        
        if (self.iCurrentAction > 0) {
            
            TIMELOG(keyDetect);
            
            st_result_t iRet = st_mobile_human_action_detect(_hDetector, pBGRAImageIn, ST_PIX_FMT_BGRA8888, iWidth, iHeight, iBytesPerRow, stMobileRotate, self.iCurrentAction, &detectResult);
            
            TIMEPRINT(keyDetect, "st_mobile_human_action_detect time:");
            
            if(iRet == ST_OK) {
#if TEST_AVATAR_EXPRESSION
                //获取avatar表情参数，该接口只会处理一张人脸信息，结果信息会以数组形式返回，数组下标对应的表情在ST_AVATAR_EXPRESSION_INDEX枚举中
                if (detectResult.face_count > 0) {
                    float expression[ST_AVATAR_EXPRESSION_NUM] = {0.0};
                    iRet = st_mobile_avatar_get_expression(_avatarHandle, iWidth, iHeight, stMobileRotate, detectResult.p_faces, expression);
                    if (expression[0] == 1) {
                        NSLog(@"右眼闭");
                    }
                }
#endif
                
                
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
    
    CFRetain(pixelBuffer);
    
    __block st_mobile_human_action_t newDetectResult;
    memset(&newDetectResult, 0, sizeof(st_mobile_human_action_t));
    //    copyHumanAction(&detectResult, &newDetectResult);
    st_mobile_human_action_copy(&detectResult, &newDetectResult);
    
    int faceCount = catFaceCount;
    st_mobile_animal_face_t *newDetectResult1 = NULL;
    if (faceCount > 0) {
        newDetectResult1 = malloc(sizeof(st_mobile_animal_face_t) * faceCount);
        memset(newDetectResult1, 0, sizeof(st_mobile_animal_face_t) * faceCount);
        copyCatFace(_detectResult1, faceCount, newDetectResult1);
    }
    
    iRet = ST_E_FAIL;
    
    // 设置 OpenGL 环境 , 需要与初始化 SDK 时一致
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    // 当图像尺寸发生改变时需要对应改变纹理大小
    if (iWidth != self.imageWidth || iHeight != self.imageHeight) {
        
        [self releaseResultTexture];
        
        self.imageWidth = iWidth;
        self.imageHeight = iHeight;
        
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
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_NARROW_FACE_STRENGTH, self.fNarrowFaceStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_ROUND_EYE_RATIO, self.fRoundEyeStrength);
            
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_THIN_FACE_SHAPE_RATIO, self.fThinFaceShapeStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_CHIN_LENGTH_RATIO, self.fChinStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_HAIRLINE_HEIGHT_RATIO, self.fHairLineStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_NARROW_NOSE_RATIO, self.fNarrowNoseStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_NOSE_LENGTH_RATIO, self.fLongNoseStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_MOUTH_SIZE_RATIO, self.fMouthStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_PHILTRUM_LENGTH_RATIO, self.fPhiltrumStrength);
            
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_APPLE_MUSLE_RATIO, self.fAppleMusleStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_PROFILE_RHINOPLASTY_RATIO, self.fProfileRhinoplastyStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_EYE_DISTANCE_RATIO, self.fEyeDistanceStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_EYE_ANGLE_RATIO, self.fEyeAngleStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_OPEN_CANTHUS_RATIO, self.fOpenCanthusStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_BRIGHT_EYE_RATIO, self.fBrightEyeStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_REMOVE_DARK_CIRCLES_RATIO, self.fRemoveDarkCirclesStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_REMOVE_NASOLABIAL_FOLDS_RATIO, self.fRemoveNasolabialFoldsStrength);
            setBeautifyParam(_hBeautify, ST_BEAUTIFY_3D_WHITE_TEETH_RATIO, self.fWhiteTeethStrength);
            
            TIMELOG(keyBeautify);
            
#if TEST_OUTPUT_BUFFER_INTERFACE
            
            unsigned char * beautify_buffer_output = malloc(iWidth * iHeight * 4);
            
            iRet = st_mobile_beautify_process_and_output_texture(_hBeautify, _textureOriginInput, iWidth, iHeight, &newDetectResult, _textureBeautifyOutput, beautify_buffer_output, ST_PIX_FMT_RGBA8888, &newDetectResult);
            
            UIImage *beatifyImage = [self rgbaBufferConvertToImage:beautify_buffer_output width:iWidth height:iHeight];
            
            if (beautify_buffer_output) {
                free(beautify_buffer_output);
                beautify_buffer_output = NULL;
            }
            
#else
            iRet = st_mobile_beautify_process_texture(_hBeautify, _textureOriginInput, iWidth, iHeight, stMobileRotate, &newDetectResult, _textureBeautifyOutput, &newDetectResult);
            
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
    
    
    
#if DRAW_FACE_KEY_POINTS
    
    [self drawKeyPoints:newDetectResult];
#endif
    
    //makeup
    if (_hBmpHandle) {
        
        TIMELOG(bmpProcessKey);
        
        iRet = st_mobile_makeup_process_texture(_hBmpHandle, textureResult, iWidth, iHeight, stMobileRotate, &newDetectResult, _textureMakeUpOutput);
        if (iRet != ST_OK) {
            NSLog(@"st_mobile_makeup_process_texture failed: %d", iRet);
        } else {
            textureResult = _textureMakeUpOutput;
            resultPixelBufffer = _cvMakeUpBuffer;
        }
        
        TIMEPRINT(bmpProcessKey, "st_mobile_makeup_process_texture time:");
    }
    
    
    ///ST_MOBILE 以下为贴纸部分
    if (_bSticker && _hSticker) {
        
        TIMELOG(stickerProcessKey);
        
#if TEST_OUTPUT_BUFFER_INTERFACE
        
        unsigned char * sticker_buffer_output = malloc(iWidth * iHeight * 4);
        
        iRet = st_mobile_sticker_process_and_output_texture(_hSticker, textureResult, iWidth, iHeight, stMobileRotate, ST_CLOCKWISE_ROTATE_0, false, &newDetectResult, item_callback, _textureStickerOutput, sticker_buffer_output, ST_PIX_FMT_RGBA8888);
        
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
            
            CMDeviceMotion *motion = self.motionManager.deviceMotion;
            inputEvent.camera_quaternion[0] = motion.attitude.quaternion.x;
            inputEvent.camera_quaternion[1] = motion.attitude.quaternion.y;
            inputEvent.camera_quaternion[2] = motion.attitude.quaternion.z;
            inputEvent.camera_quaternion[3] = motion.attitude.quaternion.w;
            inputEvent.is_front_camera = _isFrontCamera;
        } else {
            
            inputEvent.camera_quaternion[0] = 0;
            inputEvent.camera_quaternion[1] = 0;
            inputEvent.camera_quaternion[2] = 0;
            inputEvent.camera_quaternion[3] = 1;
        }
        
        //            iRet = st_mobile_sticker_process_texture(_hSticker, textureResult, iWidth, iHeight, stMobileRotate, ST_CLOCKWISE_ROTATE_0, false, &detectResult1, &inputEvent, _textureStickerOutput);
        iRet = st_mobile_sticker_process_texture_both(_hSticker, textureResult, iWidth, iHeight, stMobileRotate, ST_CLOCKWISE_ROTATE_0, false, &newDetectResult, &inputEvent, newDetectResult1, catFaceCount, _textureStickerOutput);
        
#endif
        
        TIMEPRINT(stickerProcessKey, "st_mobile_sticker_process_texture time:");
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_sticker_process_texture %d" , iRet);
            
        }
        
        textureResult = _textureStickerOutput;
        resultPixelBufffer = _cvStickerBuffer;
    }
    
    if (self.isNullSticker && _hSticker) {
        iRet = st_mobile_sticker_change_package(_hSticker, NULL, NULL);
        
        if (ST_OK != iRet) {
            NSLog(@"st_mobile_sticker_change_package error %d", iRet);
        }
    }
    
    ///ST_MOBILE 以下为滤镜部分
    if (_bFilter && _hFilter) {
        
        if (self.curFilterModelPath != self.preFilterModelPath) {
            iRet = st_mobile_gl_filter_set_style(_hFilter, self.curFilterModelPath.UTF8String);
            if (iRet != ST_OK) {
                NSLog(@"st mobile filter set style failed: %d", iRet);
            }
            self.preFilterModelPath = self.curFilterModelPath;
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
    
    //        }
    
    //        freeHumanAction(&newDetectResult);
    st_mobile_human_action_delete(&newDetectResult);
    if (faceCount > 0) {
        freeCatFace(newDetectResult1, faceCount);
    }
    
    if (_cvTextureOrigin) {
        
        CFRelease(_cvTextureOrigin);
        _cvTextureOrigin = NULL;
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVOpenGLESTextureCacheFlush(_cvTextureCache, 0);
    
    CFRelease(pixelBuffer);
    
#if ENABLE_FACE_ATTRIBUTE_DETECT
    if (_pFacesDetection) {
        free(_pFacesDetection);
        _pFacesDetection = NULL;
    }
#endif
    
    return resultPixelBufffer;
}

void copyCatFace(st_mobile_animal_face_t *src, int faceCount, st_mobile_animal_face_t *dst) {
    memcpy(dst, src, sizeof(st_mobile_animal_face_t) * faceCount);
    for (int i = 0; i < faceCount; ++i) {
        
        size_t key_points_size = sizeof(st_pointf_t) * src[i].key_points_count;
        st_pointf_t *p_key_points = malloc(key_points_size);
        memset(p_key_points, 0, key_points_size);
        memcpy(p_key_points, src[i].p_key_points, key_points_size);
        
        dst[i].p_key_points = p_key_points;
    }
}

void freeCatFace(st_mobile_animal_face_t *src, int faceCount) {
    if (faceCount > 0) {
        for (int i = 0; i < faceCount; ++i) {
            if (src[i].p_key_points != NULL) {
                free(src[i].p_key_points);
                src[i].p_key_points = NULL;
            }
        }
        free(src);
        src = NULL;
    }
}

- (void)initResultTexture {
    // 创建结果纹理
    [self setupTextureWithPixelBuffer:&_cvBeautifyBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureBeautifyOutput
                            cvTexture:&_cvTextureBeautify];
    
    [self setupTextureWithPixelBuffer:&_cvStickerBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureStickerOutput
                            cvTexture:&_cvTextureSticker];
    
    [self setupTextureWithPixelBuffer:&_cvMakeUpBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
                            glTexture:&_textureMakeUpOutput
                            cvTexture:&_cvTextureMakeup];
    
    [self setupTextureWithPixelBuffer:&_cvFilterBuffer
                                    w:self.imageWidth
                                    h:self.imageHeight
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
    _textureMakeUpOutput = 0;
    
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
    
    if (_cvTextureMakeup) {
        
        CFRelease(_cvTextureMakeup);
        _cvTextureMakeup = NULL;
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
    if (_cvMakeUpBuffer) {
        CVPixelBufferRelease(_cvMakeUpBuffer);
        _cvMakeUpBuffer = NULL;
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

- (NSArray *)arrSceneryFilterModels {
    if (!_arrSceneryFilterModels) {
        _arrSceneryFilterModels = [self getFilterModelsByType:STEffectsTypeFilterScenery];
    }
    return _arrSceneryFilterModels;
}

- (NSArray *)arrPortraitFilterModels {
    if (!_arrPortraitFilterModels) {
        _arrPortraitFilterModels = [self getFilterModelsByType:STEffectsTypeFilterPortrait];
    }
    return _arrPortraitFilterModels;
}

- (NSArray *)arrStillLifeFilterModels {
    if (!_arrStillLifeFilterModels) {
        _arrStillLifeFilterModels = [self getFilterModelsByType:STEffectsTypeFilterStillLife];
    }
    return _arrStillLifeFilterModels;
}

- (NSArray *)arrDeliciousFoodFilterModels {
    if (!_arrDeliciousFoodFilterModels) {
        _arrDeliciousFoodFilterModels = [self getFilterModelsByType:STEffectsTypeFilterDeliciousFood];
    }
    return _arrDeliciousFoodFilterModels;
}

- (NSArray *)getFilterModelsByType:(STEffectsType)type {
    
    NSArray *filterModelPath = [STParamUtil getFilterModelPathsByType:type];
    
    NSMutableArray *arrModels = [NSMutableArray array];
    
    NSString *natureImageName = @"";
    switch (type) {
        case STEffectsTypeFilterDeliciousFood:
            natureImageName = @"nature_food";
            break;
            
        case STEffectsTypeFilterStillLife:
            natureImageName = @"nature_stilllife";
            break;
            
        case STEffectsTypeFilterScenery:
            natureImageName = @"nature_scenery";
            break;
            
        case STEffectsTypeFilterPortrait:
            natureImageName = @"nature_portrait";
            break;
            
        default:
            break;
    }
    
    STCollectionViewDisplayModel *model1 = [[STCollectionViewDisplayModel alloc] init];
    model1.strPath = NULL;
    model1.strName = @"original";
    model1.image = [UIImage imageNamed:natureImageName];
    model1.index = 0;
    model1.isSelected = NO;
    model1.modelType = STEffectsTypeNone;
    [arrModels addObject:model1];
    
    for (int i = 1; i < filterModelPath.count + 1; ++i) {
        
        STCollectionViewDisplayModel *model = [[STCollectionViewDisplayModel alloc] init];
        model.strPath = filterModelPath[i - 1];
        model.strName = [[model.strPath.lastPathComponent stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"filter_style_" withString:@""];
        
        UIImage *thumbImage = [UIImage imageWithContentsOfFile:[[model.strPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];
        
        model.image = thumbImage ?: [UIImage imageNamed:@"none"];
        model.index = i;
        model.isSelected = NO;
        model.modelType = type;
        
        [arrModels addObject:model];
    }
    return [arrModels copy];
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

- (void)handleStickerChanged:(EffectsCollectionViewCellModel *)model {
    
    self.prepareModel = model;
    
    if (STEffectsTypeStickerMy == model.iEffetsType) {
        
        [self setMaterialModel:model];
        
        return;
    }
    
    
    STWeakSelf;
    
    BOOL isMaterialExist = [[SenseArMaterialService sharedInstance] isMaterialDownloaded:model.material];
    BOOL isDirectory = YES;
    BOOL isFileAvalible = [[NSFileManager defaultManager] fileExistsAtPath:model.material.strMaterialPath
                                                               isDirectory:&isDirectory];
    
    ///TODO: 双页面共享 service  会造成 model & material 状态更新错误
    if (isMaterialExist && (isDirectory || !isFileAvalible)) {
        
        model.state = NotDownloaded;
        model.strMaterialPath = nil;
        isMaterialExist = NO;
    }
    
    if (model && model.material && !isMaterialExist) {
        
        model.state = IsDownloading;
        if ([_delegate respondsToSelector:@selector(manager:modelUpdated:)]) {
            [_delegate manager:self modelUpdated:model];
        }
        
        [[SenseArMaterialService sharedInstance]
         downloadMaterial:model.material
         onSuccess:^(SenseArMaterial *material)
         {
             
             model.state = Downloaded;
             model.strMaterialPath = material.strMaterialPath;
             
             if (model == weakSelf.prepareModel) {
                 
                 [weakSelf setMaterialModel:model];
             }else{
                 
                 if ([weakSelf.delegate respondsToSelector:@selector(manager:modelUpdated:)]) {
                     [weakSelf.delegate manager:weakSelf modelUpdated:model];
                 }
             }
         }
         onFailure:^(SenseArMaterial *material, int iErrorCode, NSString *strMessage) {
             
             model.state = NotDownloaded;
             if ([weakSelf.delegate respondsToSelector:@selector(manager:modelUpdated:)]) {
                 [weakSelf.delegate manager:weakSelf modelUpdated:model];
             }
         }
         onProgress:nil];
    }else{
        
        [self setMaterialModel:model];
    }
}

- (void)setMaterialModel:(EffectsCollectionViewCellModel *)targetModel
{
    self.bSticker = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.triggerView.hidden = YES;
    });
    
    const char *stickerPath = [targetModel.strMaterialPath UTF8String];
    
    if (!targetModel || IsSelected == targetModel.state) {
        
        stickerPath = NULL;
    }
    
    for (NSArray *arrModels in [self.effectsDataSource allValues]) {
        
        for (EffectsCollectionViewCellModel *model in arrModels) {
            
            if (model == targetModel) {
                
                if (IsSelected == model.state) {
                    
                    model.state = Downloaded;
                }else{
                    
                    model.state = IsSelected;
                }
            }else{
                
                if (IsSelected == model.state) {
                    
                    model.state = Downloaded;
                }
            }
        }
    }
    
    if ([_delegate respondsToSelector:@selector(manager:modelUpdated:)]) {
        [_delegate manager:self modelUpdated:targetModel];
    }
    
    if (self.isNullSticker) {
        self.isNullSticker = NO;
    }
    
    // 获取触发动作类型
    unsigned long long iAction = 0;
    
    st_result_t iRet = ST_OK;
    iRet = st_mobile_sticker_change_package(_hSticker, stickerPath, NULL);
    
    if (iRet != ST_OK && iRet != ST_E_PACKAGE_EXIST_IN_MEMORY) {
        
        STLog(@"st_mobile_sticker_change_package error %d" , iRet);
    } else {
        
        // 需要在 st_mobile_sticker_change_package 之后调用才可以获取新素材包的 trigger action .
        iRet = st_mobile_sticker_get_trigger_action(_hSticker, &iAction);
        
        if (ST_OK != iRet) {
            
            STLog(@"st_mobile_sticker_get_trigger_action error %d" , iRet);
            
            return;
        }
        
        NSString *triggerContent = @"";
        UIImage *image = nil;
        
        if (0 != iAction) {//有 trigger信息
            
            if (CHECK_FLAG(iAction, ST_MOBILE_BROW_JUMP)) {
                triggerContent = [NSString stringWithFormat:@"%@请挑挑眉~", triggerContent];
                image = [UIImage imageNamed:@"head_brow_jump"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_EYE_BLINK)) {
                triggerContent = [NSString stringWithFormat:@"%@请眨眨眼~", triggerContent];
                image = [UIImage imageNamed:@"eye_blink"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_YAW)) {
                triggerContent = [NSString stringWithFormat:@"%@请摇摇头~", triggerContent];
                image = [UIImage imageNamed:@"head_yaw"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HEAD_PITCH)) {
                triggerContent = [NSString stringWithFormat:@"%@请点点头~", triggerContent];
                image = [UIImage imageNamed:@"head_pitch"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_MOUTH_AH)) {
                triggerContent = [NSString stringWithFormat:@"%@请张张嘴~", triggerContent];
                image = [UIImage imageNamed:@"mouth_ah"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_GOOD)) {
                triggerContent = [NSString stringWithFormat:@"%@请比个赞~", triggerContent];
                image = [UIImage imageNamed:@"hand_good"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PALM)) {
                triggerContent = [NSString stringWithFormat:@"%@请伸手掌~", triggerContent];
                image = [UIImage imageNamed:@"hand_palm"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_LOVE)) {
                triggerContent = [NSString stringWithFormat:@"%@请双手比心~", triggerContent];
                image = [UIImage imageNamed:@"hand_love"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_HOLDUP)) {
                triggerContent = [NSString stringWithFormat:@"%@请托个手~", triggerContent];
                image = [UIImage imageNamed:@"hand_holdup"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_CONGRATULATE)) {
                triggerContent = [NSString stringWithFormat:@"%@请抱个拳~", triggerContent];
                image = [UIImage imageNamed:@"hand_congratulate"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_HEART)) {
                triggerContent = [NSString stringWithFormat:@"%@请单手比心~", triggerContent];
                image = [UIImage imageNamed:@"hand_finger_heart"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FINGER_INDEX)) {
                triggerContent = [NSString stringWithFormat:@"%@请伸出食指~", triggerContent];
                image = [UIImage imageNamed:@"hand_finger"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_OK)) {
                triggerContent = [NSString stringWithFormat:@"%@请亮出OK手势~", triggerContent];
                image = [UIImage imageNamed:@"hand_ok"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_SCISSOR)) {
                triggerContent = [NSString stringWithFormat:@"%@请比个剪刀手~", triggerContent];
                image = [UIImage imageNamed:@"hand_victory"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_PISTOL)) {
                triggerContent = [NSString stringWithFormat:@"%@请比个手枪~", triggerContent];
                image = [UIImage imageNamed:@"hand_gun"];
            }
            
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_666)) {
                triggerContent = [NSString stringWithFormat:@"%@请亮出666手势~", triggerContent];
                image = [UIImage imageNamed:@"666_selected"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_BLESS)) {
                triggerContent = [NSString stringWithFormat:@"%@请双手合十~", triggerContent];
                image = [UIImage imageNamed:@"bless_selected"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_ILOVEYOU)) {
                triggerContent = [NSString stringWithFormat:@"%@请亮出我爱你手势~", triggerContent];
                image = [UIImage imageNamed:@"love_selected"];
            }
            if (CHECK_FLAG(iAction, ST_MOBILE_HAND_FIST)) {
                triggerContent = [NSString stringWithFormat:@"%@请举起拳头~", triggerContent];
                image = [UIImage imageNamed:@"fist_selected"];
            }
            [self.triggerView showTriggerViewWithContent:triggerContent image:image];
        }
        //猫脸config
        unsigned long long animalConfig = 0;
        iRet = st_mobile_sticker_get_animal_detect_config(_hSticker, &animalConfig);
        if (iRet == ST_OK && animalConfig == ST_MOBILE_CAT_DETECT) {
            _needDetectAnimal = YES;
        } else {
            _needDetectAnimal = NO;
        }
        
    }
    
    self.iCurrentAction = iAction;
}

- (void)handleFilterChanged:(STCollectionViewDisplayModel *)model {
    
    if ([EAGLContext currentContext] != self.glContext) {
        [EAGLContext setCurrentContext:self.glContext];
    }
    
    self.currentSelectedFilterModel = model;
    
    self.bFilter = model.index > 0;
    
    // 切换滤镜
    if (_hFilter) {
        
        self.curFilterModelPath = model.strPath;
        st_result_t iRet = ST_OK;
        iRet = st_mobile_gl_filter_set_param(_hFilter, ST_GL_FILTER_STRENGTH, self.fFilterStrength);
        if (iRet != ST_OK) {
            STLog(@"st_mobile_gl_filter_set_param %d" , iRet);
        }
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
}

void copyHumanAction(st_mobile_human_action_t *src , st_mobile_human_action_t *dst) {
    
    memcpy(dst, src, sizeof(st_mobile_human_action_t));
    
    // copy faces
    if ((*src).face_count > 0) {
        
        size_t faces_size = sizeof(st_mobile_face_t) * (*src).face_count;
        st_mobile_face_t *p_faces = malloc(faces_size);
        memset(p_faces, 0, faces_size);
        memcpy(p_faces, (*src).p_faces, faces_size);
        (*dst).p_faces = p_faces;
        
        for (int i = 0; i < (*src).face_count; i ++) {
            
            st_mobile_face_t face = (*src).p_faces[i];
            
            // p_extra_face_points
            if (face.extra_face_points_count > 0 && face.p_extra_face_points != NULL) {
                
                size_t extra_face_points_size = sizeof(st_pointf_t) * face.extra_face_points_count;
                st_pointf_t *p_extra_face_points = malloc(extra_face_points_size);
                memset(p_extra_face_points, 0, extra_face_points_size);
                memcpy(p_extra_face_points, face.p_extra_face_points, extra_face_points_size);
                (*dst).p_faces[i].p_extra_face_points = p_extra_face_points;
            }
            
            // p_tongue_points & p_tongue_points_score
            if (   face.tongue_points_count > 0
                && face.p_tongue_points != NULL
                && face.p_tongue_points_score != NULL) {
                
                size_t tongue_points_size = sizeof(st_pointf_t) * face.tongue_points_count;
                st_pointf_t *p_tongue_points = malloc(tongue_points_size);
                memset(p_tongue_points, 0, tongue_points_size);
                memcpy(p_tongue_points, face.p_tongue_points, tongue_points_size);
                (*dst).p_faces[i].p_tongue_points = p_tongue_points;
                
                size_t tongue_points_score_size = sizeof(float) * face.tongue_points_count;
                float *p_tongue_points_score = malloc(tongue_points_score_size);
                memset(p_tongue_points_score, 0, tongue_points_score_size);
                memcpy(p_tongue_points_score, face.p_tongue_points_score, tongue_points_score_size);
                (*dst).p_faces[i].p_tongue_points_score = p_tongue_points_score;
            }
            
            // p_eyeball_center
            if (face.eyeball_center_points_count > 0 && face.p_eyeball_center != NULL) {
                
                size_t eyeball_center_points_size = sizeof(st_pointf_t) * face.eyeball_center_points_count;
                st_pointf_t *p_eyeball_center = malloc(eyeball_center_points_size);
                memset(p_eyeball_center, 0, eyeball_center_points_size);
                memcpy(p_eyeball_center, face.p_eyeball_center, eyeball_center_points_size);
                (*dst).p_faces[i].p_eyeball_center = p_eyeball_center;
            }
            
            // p_eyeball_contour
            if (face.eyeball_contour_points_count > 0 && face.p_eyeball_contour != NULL) {
                
                size_t eyeball_contour_points_size = sizeof(st_pointf_t) * face.eyeball_contour_points_count;
                st_pointf_t *p_eyeball_contour = malloc(eyeball_contour_points_size);
                memset(p_eyeball_contour, 0, eyeball_contour_points_size);
                memcpy(p_eyeball_contour, face.p_eyeball_contour, eyeball_contour_points_size);
                (*dst).p_faces[i].p_eyeball_contour = p_eyeball_contour;
            }
        }
    }
    
    
    // copy hands
    if ((*src).hand_count > 0) {
        
        size_t hands_size = sizeof(st_mobile_hand_t) * (*src).hand_count;
        st_mobile_hand_t *p_hands = malloc(hands_size);
        memset(p_hands, 0, hands_size);
        memcpy(p_hands, (*src).p_hands, hands_size);
        (*dst).p_hands = p_hands;
        
        for (int i = 0; i < (*src).hand_count; i ++) {
            
            st_mobile_hand_t hand = (*src).p_hands[i];
            
            // p_key_points
            if (hand.key_points_count > 0 && hand.p_key_points != NULL) {
                
                size_t key_points_size = sizeof(st_pointf_t) * hand.key_points_count;
                st_pointf_t *p_key_points = malloc(key_points_size);
                memset(p_key_points, 0, key_points_size);
                memcpy(p_key_points, hand.p_key_points, key_points_size);
                (*dst).p_hands[i].p_key_points = p_key_points;
            }
            
            // p_skeleton_keypoints
            if (hand.skeleton_keypoints_count > 0 && hand.p_skeleton_keypoints != NULL) {
                
                size_t skeleton_keypoints_size = sizeof(st_pointf_t) * hand.skeleton_keypoints_count;
                st_pointf_t *p_skeleton_keypoints = malloc(skeleton_keypoints_size);
                memset(p_skeleton_keypoints, 0, skeleton_keypoints_size);
                memcpy(p_skeleton_keypoints, hand.p_skeleton_keypoints, skeleton_keypoints_size);
                (*dst).p_hands[i].p_skeleton_keypoints = p_skeleton_keypoints;
            }
            
            // p_skeleton_3d_keypoints
            if (hand.skeleton_3d_keypoints_count > 0 && hand.p_skeleton_3d_keypoints != NULL) {
                
                size_t skeleton_3d_keypoints_size = sizeof(st_point3f_t) * hand.skeleton_3d_keypoints_count;
                st_point3f_t *p_skeleton_3d_keypoints = malloc(skeleton_3d_keypoints_size);
                memset(p_skeleton_3d_keypoints, 0, skeleton_3d_keypoints_size);
                memcpy(p_skeleton_3d_keypoints, hand.p_skeleton_3d_keypoints, skeleton_3d_keypoints_size);
                (*dst).p_hands[i].p_skeleton_3d_keypoints = p_skeleton_3d_keypoints;
            }
        }
    }
    
    
    // copy body
    if ((*src).body_count > 0) {
        
        size_t bodys_size = sizeof(st_mobile_body_t) * (*src).body_count;
        st_mobile_body_t *p_bodys = malloc(bodys_size);
        memset(p_bodys, 0, bodys_size);
        memcpy(p_bodys, (*src).p_bodys, bodys_size);
        (*dst).p_bodys = p_bodys;
        
        for (int i = 0; i < (*src).body_count; i ++) {
            
            st_mobile_body_t body = (*src).p_bodys[i];
            
            // p_key_points & p_key_points_score
            if (   body.key_points_count > 0
                && body.p_key_points != NULL
                && body.p_key_points_score != NULL) {
                
                size_t key_points_size = sizeof(st_pointf_t) * body.key_points_count;
                st_pointf_t *p_key_points = malloc(key_points_size);
                memset(p_key_points, 0, key_points_size);
                memcpy(p_key_points, body.p_key_points, key_points_size);
                (*dst).p_bodys[i].p_key_points = p_key_points;
                
                size_t key_points_score_size = sizeof(float) * body.key_points_count;
                float *p_key_points_score = malloc(key_points_score_size);
                memset(p_key_points_score, 0, key_points_score_size);
                memcpy(p_key_points_score, body.p_key_points_score, key_points_score_size);
                (*dst).p_bodys[i].p_key_points_score = p_key_points_score;
            }
            
            
            // p_contour_points & p_contour_points_score
            if (   body.contour_points_count > 0
                && body.p_contour_points != NULL
                && body.p_contour_points_score != NULL) {
                
                size_t contour_points_size = sizeof(st_pointf_t) * body.contour_points_count;
                st_pointf_t *p_contour_points = malloc(contour_points_size);
                memset(p_contour_points, 0, contour_points_size);
                memcpy(p_contour_points, body.p_contour_points, contour_points_size);
                (*dst).p_bodys[i].p_contour_points = p_contour_points;
                
                size_t contour_points_score_size = sizeof(float) * body.contour_points_count;
                float *p_contour_points_score = malloc(contour_points_score_size);
                memset(p_contour_points_score, 0, contour_points_score_size);
                memcpy(p_contour_points_score, body.p_contour_points_score, contour_points_score_size);
                (*dst).p_bodys[i].p_contour_points_score = p_contour_points_score;
            }
        }
    }
    
    
    // p_background
    if ((*src).p_background != NULL) {
        
        st_image_t *p_background = malloc(sizeof(st_image_t));
        memcpy(p_background, (*src).p_background, sizeof(st_image_t));
        
        size_t image_data_size = sizeof(unsigned char) * (*src).p_background[0].width * (*src).p_background[0].height;
        unsigned char *data = malloc(image_data_size);
        memset(data, 0, image_data_size);
        memcpy(data, (*src).p_background[0].data, image_data_size);
        p_background[0].data = data;
        
        (*dst).p_background = p_background;
    }
    
    // p_hair
    if ((*src).p_hair != NULL) {
        
        st_image_t *p_hair = malloc(sizeof(st_image_t));
        memcpy(p_hair, (*src).p_hair, sizeof(st_image_t));
        
        size_t image_data_size = sizeof(unsigned char) * (*src).p_hair[0].width * (*src).p_hair[0].height;
        unsigned char *data = malloc(image_data_size);
        memset(data, 0, image_data_size);
        memcpy(data, (*src).p_hair[0].data, image_data_size);
        p_hair[0].data = data;
        
        (*dst).p_hair = p_hair;
    }
}

void freeHumanAction(st_mobile_human_action_t *src) {
    
    // free faces
    if ((*src).face_count > 0) {
        
        for (int i = 0; i < (*src).face_count; i ++) {
            
            st_mobile_face_t face = (*src).p_faces[i];
            
            // p_extra_face_points
            if (face.extra_face_points_count > 0 && face.p_extra_face_points != NULL) {
                
                free(face.p_extra_face_points);
                face.p_extra_face_points = NULL;
            }
            
            // p_tongue_points & p_tongue_points_score
            if (   face.tongue_points_count > 0
                && face.p_tongue_points != NULL
                && face.p_tongue_points_score != NULL) {
                
                free(face.p_tongue_points);
                face.p_tongue_points = NULL;
                
                free(face.p_tongue_points_score);
                face.p_tongue_points_score = NULL;
            }
            
            // p_eyeball_center
            if (face.eyeball_center_points_count > 0 && face.p_eyeball_center != NULL) {
                
                free(face.p_eyeball_center);
                face.p_eyeball_center = NULL;
            }
            
            // p_eyeball_contour
            if (face.eyeball_contour_points_count > 0 && face.p_eyeball_contour != NULL) {
                
                free(face.p_eyeball_contour);
                face.p_eyeball_contour = NULL;
            }
        }
        
        free((*src).p_faces);
        (*src).p_faces = NULL;
    }
    
    
    // free hands
    if ((*src).hand_count > 0) {
        
        for (int i = 0; i < (*src).hand_count; i ++) {
            
            st_mobile_hand_t hand = (*src).p_hands[i];
            
            // p_key_points
            if (hand.key_points_count > 0 && hand.p_key_points != NULL) {
                
                free(hand.p_key_points);
                hand.p_key_points = NULL;
            }
            
            // p_skeleton_keypoints
            if (hand.skeleton_keypoints_count > 0 && hand.p_skeleton_keypoints != NULL) {
                
                free(hand.p_skeleton_keypoints);
                hand.p_skeleton_keypoints = NULL;
            }
            
            // p_skeleton_3d_keypoints
            if (hand.skeleton_3d_keypoints_count > 0 && hand.p_skeleton_3d_keypoints != NULL) {
                
                free(hand.p_skeleton_3d_keypoints);
                hand.p_skeleton_3d_keypoints = NULL;
            }
        }
        
        free((*src).p_hands);
        (*src).p_hands = NULL;
    }
    
    
    // free body
    if ((*src).body_count > 0) {
        
        for (int i = 0; i < (*src).body_count; i ++) {
            
            st_mobile_body_t body = (*src).p_bodys[i];
            
            // p_key_points & p_key_points_score
            if (   body.key_points_count > 0
                && body.p_key_points != NULL
                && body.p_key_points_score != NULL) {
                
                free(body.p_key_points);
                body.p_key_points = NULL;
                
                free(body.p_key_points_score);
                body.p_key_points_score = NULL;
            }
            
            
            // p_contour_points & p_contour_points_score
            if (   body.contour_points_count > 0
                && body.p_contour_points != NULL
                && body.p_contour_points_score != NULL) {
                
                free(body.p_contour_points);
                body.p_contour_points = NULL;
                
                free(body.p_contour_points_score);
                body.p_contour_points_score = NULL;
            }
        }
        
        free((*src).p_bodys);
        (*src).p_bodys = NULL;
    }
    
    
    // p_background
    if ((*src).p_background != NULL) {
        
        if ((*src).p_background[0].data != NULL) {
            
            free((*src).p_background[0].data);
            (*src).p_background[0].data = NULL;
        }
        
        free((*src).p_background);
        (*src).p_background = NULL;
    }
    
    // p_hair
    if ((*src).p_hair != NULL) {
        
        if ((*src).p_hair[0].data != NULL) {
            
            free((*src).p_hair[0].data);
            (*src).p_hair[0].data = NULL;
        }
        
        free((*src).p_hair);
        (*src).p_hair = NULL;
    }
    
    memset(src, 0, sizeof(st_mobile_human_action_t));
}

- (void)resetBmp
{
    [self resetBmpModels];
    
    st_mobile_makeup_clear_makeups(_hBmpHandle);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resetUIs" object:nil];
}

- (void)resetBmpModels
{
    _bmp_Eye_Value = _bmp_EyeLiner_Value = _bmp_EyeLash_Value = _bmp_Lip_Value = _bmp_Brow_Value = _bmp_Nose_Value = _bmp_Face_Value = _bmp_Blush_Value = _bmp_Eyeball_Value = 0.8;
}

- (st_makeup_type)getMakeUpType:(STBMPTYPE)bmpType
{
    st_makeup_type type;
    switch (bmpType) {
        case STBMPTYPE_EYE:
            type = ST_MAKEUP_TYPE_EYE;
            break;
        case STBMPTYPE_EYELINER:
            type = ST_MAKEUP_TYPE_EYELINER;
            break;
        case STBMPTYPE_EYELASH:
            type = ST_MAKEUP_TYPE_EYELASH;
            break;
        case STBMPTYPE_LIP:
            type =  ST_MAKEUP_TYPE_LIP;
            break;
        case STBMPTYPE_BROW:
            type =  ST_MAKEUP_TYPE_BROW;
            break;
        case STBMPTYPE_FACE:
            type =  ST_MAKEUP_TYPE_NOSE;
            break;
        case STBMPTYPE_BLUSH:
            type =  ST_MAKEUP_TYPE_FACE;
            break;
        case STBMPTYPE_EYEBALL:
            type = ST_MAKEUP_TYPE_EYEBALL;
            break;
        case STBMPTYPE_COUNT:
            break;
    }
    
    return type;
}

- (void)sliderValueDidChange:(float)value
{
    if (!_hBmpHandle) {
        return;
    }
    st_makeup_type makeupType;
    switch (_bmp_Current_Model.m_bmpType) {
        case STBMPTYPE_EYE:
            _bmp_Eye_Model.m_bmpStrength = value;
            _bmp_Eye_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_EYE];
            break;
        case STBMPTYPE_EYELINER:
            _bmp_EyeLiner_Model.m_bmpStrength = value;
            _bmp_EyeLiner_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_EYELINER];
            break;
        case STBMPTYPE_EYELASH:
            _bmp_EyeLash_Model.m_bmpStrength = value;
            _bmp_EyeLash_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_EYELASH];
            break;
        case STBMPTYPE_LIP:
            _bmp_Lip_Model.m_bmpStrength = value;
            _bmp_Lip_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_LIP];
            break;
        case STBMPTYPE_BROW:
            _bmp_Brow_Model.m_bmpStrength = value;
            _bmp_Brow_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_BROW];
            break;
        case STBMPTYPE_FACE:
            _bmp_Face_Model.m_bmpStrength = value;
            _bmp_Face_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_FACE];
            break;
        case STBMPTYPE_BLUSH:
            _bmp_Blush_Model.m_bmpStrength = value;
            _bmp_Blush_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_BLUSH];
            break;
        case STBMPTYPE_EYEBALL:
            _bmp_Eyeball_Model.m_bmpStrength = value;
            _bmp_Eyeball_Value = value;
            makeupType = [self getMakeUpType:STBMPTYPE_EYEBALL];
            break;
        case STBMPTYPE_COUNT:
            break;
    }
    
    st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, value);
}

- (void)didSelectedDetailModel:(STBMPModel *)model
{
    _bmp_Current_Model = model;
    
    if (model.m_index == 0) {
        _bMakeUp = NO;
    }else{
        _bMakeUp = YES;
    }
    
    st_makeup_type makeupType = [self getMakeUpType:model.m_bmpType];
    if (model.m_zipPath) {
        st_mobile_makeup_set_makeup_for_type(_hBmpHandle, makeupType, model.m_zipPath.UTF8String, NULL);
    }else{
        st_mobile_makeup_set_makeup_for_type(_hBmpHandle, makeupType, NULL, NULL);
    }
    
    unsigned long long config = 0;
    st_result_t iRet = st_mobile_makeup_get_trigger_action(_hBmpHandle, &config);
    if (iRet == ST_OK) {
        _makeUpConf = config;
    }
    
    switch (model.m_bmpType) {
        case STBMPTYPE_EYE:
            _bmp_Eye_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Eye_Value);
            break;
        case STBMPTYPE_EYELINER:
            _bmp_EyeLiner_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_EyeLiner_Value);
            break;
        case STBMPTYPE_EYELASH:
            _bmp_EyeLash_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_EyeLash_Value);
            break;
        case STBMPTYPE_LIP:
            _bmp_Lip_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Lip_Value);
            break;
        case STBMPTYPE_BROW:
            _bmp_Brow_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Brow_Value);
            break;
        case STBMPTYPE_FACE:
            _bmp_Face_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Face_Value);
            break;
        case STBMPTYPE_BLUSH:
            _bmp_Blush_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Blush_Value);
            break;
        case STBMPTYPE_EYEBALL:
            _bmp_Eyeball_Model = model;
            st_mobile_makeup_set_strength_for_type(_hBmpHandle, makeupType, _bmp_Eyeball_Value);
            break;
        case STBMPTYPE_COUNT:
            break;
    }
}

@end
