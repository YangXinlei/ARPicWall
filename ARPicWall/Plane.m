//
//  Plane.m
//  OhAR
//
//  Created by yangxinlei on 2017/7/12.
//  Copyright © 2017年 qunar. All rights reserved.
//

#import "Plane.h"

@implementation Plane

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor
{
    self = [super init];
    
    self.anchor = anchor;
    self.planeGeometry = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"tron_grid.png"];
    material.diffuse.contents = img;
    self.planeGeometry.materials = @[material];
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:self.planeGeometry];
    planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI/2.0, 1.0, 0, 0);
    
    [self setTextureScale];
    [self addChildNode:planeNode];
    
    return self;
}

- (void)update:(ARPlaneAnchor *)anchor {
    // As the user moves around the extend and location of the plane
    // may be updated. We need to update our 3D geometry to match the
    // new parameters of the plane.
    self.planeGeometry.width = anchor.extent.x;
    self.planeGeometry.height = anchor.extent.z;
    
    // When the plane is first created it's center is 0,0,0 and the nodes
    // transform contains the translation parameters. As the plane is updated
    // the planes translation remains the same but it's center is updated so
    // we need to update the 3D geometry position
    self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    [self setTextureScale];
}

- (void)setTextureScale
{
    CGFloat width = self.planeGeometry.width;
    CGFloat height = self.planeGeometry.height;
    
    SCNMaterial *material = self.planeGeometry.materials.firstObject;
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.diffuse.wrapT = SCNWrapModeRepeat;
}

@end
