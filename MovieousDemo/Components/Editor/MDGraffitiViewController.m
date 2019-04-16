//
//  MDGraffitiViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/19.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDGraffitiViewController.h"
#import "MDSharedCenter.h"

#define kGraffitiEffectID @"kGraffitiEffectID"

@interface MDGraffitiViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
MSVGraffitiViewDelegate
>

@property (strong, nonatomic) IBOutlet UISlider *lineWidthSlider;
@property (strong, nonatomic) IBOutlet UIButton *undoButton;
@property (strong, nonatomic) IBOutlet UIButton *redoButton;

@end

@implementation MDGraffitiViewController {
    NSInteger _previeousIndex;
    NSArray<UIColor *> *_brushColors;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (MDSharedCenter.sharedCenter.graffitiView.canUndo) {
        _undoButton.enabled = YES;
    } else {
        _undoButton.enabled = NO;
    }
    if (MDSharedCenter.sharedCenter.graffitiView.canRedo) {
        _redoButton.enabled = YES;
    } else {
        _redoButton.enabled = NO;
    }
    MDSharedCenter.sharedCenter.graffitiView.delegate = self;
    _previeousIndex = -1;
    _lineWidthSlider.value = MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth;
    if (MDSharedCenter.sharedCenter.graffitiView.brush.lineColor == UIColor.clearColor) {
        [_lineWidthSlider setThumbImage:[self resizeImage:[UIImage imageNamed:@"eraser"] toSize:CGSizeMake(MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth, MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth)] forState:UIControlStateNormal];
    } else {
        [_lineWidthSlider setThumbImage:[self thumbImageWithDiameter:MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth color:MDSharedCenter.sharedCenter.graffitiView.brush.lineColor] forState:UIControlStateNormal];
    }
    _brushColors = @[movieousRGBA(0, 0, 0, 1), movieousRGBA(255, 255, 255, 1), movieousRGBA(255, 0, 0, 1), movieousRGBA(0, 255, 0, 1), movieousRGBA(0, 0, 255, 1), movieousRGBA(159, 0, 82, 1), movieousRGBA(235, 97, 111, 1), movieousRGBA(252, 226, 196, 1), movieousRGBA(192, 220, 151, 1), movieousRGBA(65, 178, 102, 1)];
    MDSharedCenter.sharedCenter.graffitiView.hidden = NO;
    NSMutableArray *basicEffects = [NSMutableArray array];
    for (int i = 0; i < MDSharedCenter.sharedCenter.editor.draft.basicEffects.count; i++) {
        id<MSVBasicEditorEffect> basicEffect = MDSharedCenter.sharedCenter.editor.draft.basicEffects[i];
        if ([basicEffect.ID isEqualToString:kGraffitiEffectID]) {
            _previeousIndex = i;
        } else {
            [basicEffects addObject:basicEffect];
        }
    }
    NSError *error;
    [MDSharedCenter.sharedCenter.editor.draft updateBasicEffects:basicEffects error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)dealloc {
    MDSharedCenter.sharedCenter.graffitiView.hidden = YES;
    UIImage *snapshot = [MDSharedCenter.sharedCenter.graffitiView takeSnapshot];
    MSVImageStickerEditorEffect *effect = [MSVImageStickerEditorEffect new];
    effect.image = snapshot;
    effect.ID = kGraffitiEffectID;
    CGSize videoSize = MDSharedCenter.sharedCenter.editor.draft.videoSize;
    effect.destRect = CGRectMake(0, 0, videoSize.width, videoSize.height);
    NSMutableArray *basicEffects = [NSMutableArray arrayWithArray:MDSharedCenter.sharedCenter.editor.draft.basicEffects];
    if (_previeousIndex >= 0) {
        [basicEffects insertObject:effect atIndex:_previeousIndex];
    } else {
        [basicEffects addObject:effect];
    }
    NSError *error;
    [MDSharedCenter.sharedCenter.editor.draft updateBasicEffects:basicEffects error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
    }
}

- (IBAction)undoButtonPressed:(UIButton *)sender {
    [MDSharedCenter.sharedCenter.graffitiView undo];
}

- (IBAction)redoButtonPressed:(UIButton *)sender {
    [MDSharedCenter.sharedCenter.graffitiView redo];
}

- (IBAction)resetButtonPressed:(UIButton *)sender {
    [MDSharedCenter.sharedCenter.graffitiView reset];
}

- (IBAction)clearButtonPressed:(UIButton *)sender {
    [MDSharedCenter.sharedCenter.graffitiView clear];
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth = sender.value;
    if (MDSharedCenter.sharedCenter.graffitiView.brush.lineColor == UIColor.clearColor) {
        [_lineWidthSlider setThumbImage:[self resizeImage:[UIImage imageNamed:@"eraser"] toSize:CGSizeMake(MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth, MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth)] forState:UIControlStateNormal];
    } else {
        [_lineWidthSlider setThumbImage:[self thumbImageWithDiameter:MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth color:MDSharedCenter.sharedCenter.graffitiView.brush.lineColor] forState:UIControlStateNormal];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _brushColors.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.backgroundColor = UIColor.clearColor;
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"eraser"]];
        cell.backgroundView.frame = cell.bounds;
    } else {
        cell.backgroundView = nil;
        cell.backgroundColor = _brushColors[indexPath.row - 1];
    }
    cell.layer.borderWidth = 1;
    cell.layer.borderColor = UIColor.lightGrayColor.CGColor;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        MDSharedCenter.sharedCenter.graffitiView.brush.lineColor = UIColor.clearColor;
        [_lineWidthSlider setThumbImage:[self resizeImage:[UIImage imageNamed:@"eraser"] toSize:CGSizeMake(MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth, MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth)] forState:UIControlStateNormal];
    } else {
        UIColor *brushColor = _brushColors[indexPath.row - 1];
        MDSharedCenter.sharedCenter.graffitiView.brush.lineColor = brushColor;
        [_lineWidthSlider setThumbImage:[self thumbImageWithDiameter:MDSharedCenter.sharedCenter.graffitiView.brush.lineWidth color:MDSharedCenter.sharedCenter.graffitiView.brush.lineColor] forState:UIControlStateNormal];
    }
}

- (UIImage *)thumbImageWithDiameter:(CGFloat)diameter color:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), NO, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColor.lightGrayColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0, 0, diameter, diameter));
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(1, 1, diameter - 2, diameter - 2));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)resizeImage:(UIImage *)originalImage toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    [originalImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)graffitiViewUndoRedoStatusChanged:(MSVGraffitiView *)graffitiView {
    if (MDSharedCenter.sharedCenter.graffitiView.canUndo) {
        _undoButton.enabled = YES;
    } else {
        _undoButton.enabled = NO;
    }
    if (MDSharedCenter.sharedCenter.graffitiView.canRedo) {
        _redoButton.enabled = YES;
    } else {
        _redoButton.enabled = NO;
    }
}

@end
