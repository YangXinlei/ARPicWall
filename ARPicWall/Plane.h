//
//  Plane.h
//  OhAR
//
//  Created by yangxinlei on 2017/7/12.
//  Copyright © 2017年 qunar. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface Plane : SCNNode

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor;

- (void)update:(ARPlaneAnchor *)anchor;

- (void)setTextureScale;

@property (nonatomic)   ARPlaneAnchor *anchor;
@property (nonatomic)   SCNPlane *planeGeometry;

@end
