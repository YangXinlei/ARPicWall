//
//  ViewController.m
//  ARPicWall
//
//  Created by yangxinlei on 2017/7/14.
//  Copyright © 2017年 qunar. All rights reserved.
//

#import "ViewController.h"
#import "Plane.h"


void print_Matrix4(SCNMatrix4 matrix)
{
    NSLog(@"‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹matrix‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹");
    NSLog(@"\n%.2f, %.2f, %.2f, %.2f\n%.2f, %.2f, %.2f, %.2f\n%.2f, %.2f, %.2f, %.2f\n%.2f, %.2f, %.2f, %.2f\n",
          matrix.m11, matrix.m12, matrix.m13, matrix.m14,
          matrix.m21, matrix.m22, matrix.m23, matrix.m24,
          matrix.m31, matrix.m32, matrix.m33, matrix.m34,
          matrix.m41, matrix.m42, matrix.m43, matrix.m44);
    NSLog(@"››››››››››››››››››››››››matrix›››››››››››››››››››››››››››››››");
}

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

//AR视图：展示3D界面
@property(nonatomic,strong)ARSCNView *arSCNView;

//AR会话，负责管理相机追踪配置及3D相机坐标
@property(nonatomic,strong)ARSession *arSession;

//会话追踪配置：负责追踪相机的运动
@property(nonatomic,strong)ARSessionConfiguration *arSessionConfiguration;

//飞机3D模型(本小节加载多个模型)
@property(nonatomic,strong)SCNNode *planeNode;

@property (nonatomic) SCNNode *picNode;

@property(nonatomic, assign) vector_float3 curCameraAngle;

@property(nonatomic, strong) NSMutableArray *picArray;

@property (nonatomic) NSMutableDictionary *planes;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.将AR视图添加到当前视图
    [self.view addSubview:self.arSCNView];
    //2.开启AR会话（此时相机开始工作）
    [self.arSession runWithConfiguration:self.arSessionConfiguration];
    
    UIButton *choosePicBtn = [UIButton buttonWithType:UIButtonTypePlain];
    [choosePicBtn setTitle:@"选择照片" forState:UIControlStateNormal];
    [choosePicBtn sizeToFit];
    [choosePicBtn setCenter:CGPointMake(40, [UIScreen mainScreen].bounds.size.height - 30)];
    [choosePicBtn addTarget:self action:@selector(pickPic:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:choosePicBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

//- (void)viewDidDisappear:(BOOL)animated
//{
//    [super viewDidDisappear:animated];
//
//    // 重置
//    [self.arSCNView removeFromSuperview];
//    self.arSCNView = nil;
//    self.arSession = nil;
//    self.arSessionConfiguration = nil;
//    self.planes = nil;
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    if (! [anchor isKindOfClass:[ARPlaneAnchor class]])
    {
        return ;
    }
    
    Plane *plane = [[Plane alloc] initWithAnchor:(ARPlaneAnchor *)anchor];
    [self.planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    // See if this is a plane we are currently rendering
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    if (plane == nil) {
        return;
    }
    [plane update:(ARPlaneAnchor *)anchor];
}

#pragma mark - events

- (IBAction)pickPic:(UIButton *)sender
{
    UIImagePickerController *picker = [UIImagePickerController new];
    [picker setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setAllowsEditing:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)tapped:(UITapGestureRecognizer *)tapper
{
    CGPoint location = [tapper locationInView:self.arSCNView];
    NSArray<ARHitTestResult *> *hitTestResults = [self.arSCNView hitTest:location types:ARHitTestResultTypeFeaturePoint];
    if (hitTestResults && [hitTestResults count] > 0)
    {
        ARHitTestResult *anchor = [hitTestResults firstObject];
        SCNMatrix4 hitPointTransform = SCNMatrix4FromMat4(anchor.worldTransform);
        print_Matrix4(hitPointTransform);
//        // sth like this:
//        1.00, 0.00, 0.00, 0.00
//        0.00, 1.00, 0.00, 0.00
//        0.00, 0.00, 1.00, 0.00
//        0.38, -0.12, -0.18, 1.00
        SCNVector3 hitPointPosition = SCNVector3Make(hitPointTransform.m41, hitPointTransform.m42, hitPointTransform.m43);
        
        // put at nearest anchor
        [self.picNode setPosition:hitPointPosition];
        
        // face to camera
        [self.picNode setEulerAngles:SCNVector3Make(self.curCameraAngle.x, self.curCameraAngle.y, 0)];
    }
}

- (void)swipped:(UISwipeGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.arSCNView];
    NSArray<SCNHitTestResult *> *results = [self.arSCNView hitTest:location options:nil];
    if (results && [results count] > 0)
    {
        SCNHitTestResult *result = results.firstObject;
        
        if (self.picNode && [result node] == self.picNode)
        {
//            if (recognizer.direction == UISwipeGestureRecognizerDirectionRight)
//            {
//                [self.picNode.geometry setMaterials:@[self.picArray[0]]];
//            }
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *pickedImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    SCNMaterial *material = [SCNMaterial new];
    material.diffuse.contents = pickedImage;
    [self.picArray addObject:material];
    CGFloat constWidth = 0.15;
    CGFloat scale = pickedImage.size.width / constWidth;
    SCNPlane *picPlane = [SCNPlane planeWithWidth:constWidth height:pickedImage.size.height/scale];
    [picPlane setMaterials:@[material]];
    SCNNode *picNode = [SCNNode nodeWithGeometry:picPlane];
    picNode.transform = SCNMatrix4MakeTranslation(0, 0, -0.5);
    
    if ([picNode parentNode] == nil)
    {
        [[self.arSCNView.scene rootNode] addChildNode:picNode];
    }
    
    self.picNode = picNode;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame
{
    self.curCameraAngle = frame.camera.eulerAngles;
}


#pragma mark - get/set

- (NSMutableArray *)picArray
{
    if (_picArray == nil)
    {
        _picArray = [NSMutableArray arrayWithCapacity:3];
    }
    return _picArray;
}

- (NSMutableDictionary *)planes
{
    if (_planes == nil)
    {
        _planes = [NSMutableDictionary dictionary];
    }
    return _planes;
}

//懒加载会话追踪配置
- (ARSessionConfiguration *)arSessionConfiguration
{
    if (_arSessionConfiguration != nil) {
        return _arSessionConfiguration;
    }
    
    //1.创建世界追踪会话配置（使用ARWorldTrackingSessionConfiguration效果更加好），需要A9芯片支持
    ARWorldTrackingSessionConfiguration *configuration = [[ARWorldTrackingSessionConfiguration alloc] init];
    //2.设置追踪方向（追踪平面，后面会用到）
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    _arSessionConfiguration = configuration;
    //3.自适应灯光（相机从暗到强光快速过渡效果会平缓一些）
    _arSessionConfiguration.lightEstimationEnabled = YES;
    
    return _arSessionConfiguration;
    
}

//懒加载拍摄会话
- (ARSession *)arSession
{
    if(_arSession != nil)
    {
        return _arSession;
    }
    //1.创建会话
    _arSession = [[ARSession alloc] init];
    _arSession.delegate = self;
    //2返回会话
    return _arSession;
}

//创建AR视图
- (ARSCNView *)arSCNView
{
    if (_arSCNView != nil) {
        return _arSCNView;
    }
    //1.创建AR视图
    _arSCNView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    
    //2.设置代理  捕捉到平地会在代理回调中返回
    _arSCNView.delegate = self;
    
    //2.设置视图会话
    _arSCNView.session = self.arSession;
    //3.自动刷新灯光（3D游戏用到，此处可忽略）
    _arSCNView.automaticallyUpdatesLighting = YES;
    
    // 开启debug
    _arSCNView.debugOptions = ARSCNDebugOptionShowWorldOrigin | ARSCNDebugOptionShowFeaturePoints;
    
    // 添加手势
    UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [_arSCNView addGestureRecognizer:tapper];
    
    // 处理左滑
    UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipped:)];
    [swipeLeftRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.arSCNView addGestureRecognizer:swipeLeftRecognizer];
    // 处理右滑
    UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipped:)];
    [swipeRightRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.arSCNView addGestureRecognizer:swipeRightRecognizer];
    
    return _arSCNView;
}
@end
