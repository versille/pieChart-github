//
//  PieChartView.h
//  CG
//
//  Created by versille on 5/20/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "constant.h"

@class PieChartView;
@protocol PieChartViewDataSource <NSObject>
@required
- (NSArray*)getData:(mealType)meal;
@end

@interface PieChartView : UIView
@property(nonatomic, weak) id<PieChartViewDataSource> dataSource;
@property(nonatomic, assign) CGFloat startPieAngle;
@property(nonatomic, assign) CGFloat animationSpeed;
@property(nonatomic, assign) CGPoint pieCenter;
@property(nonatomic, assign) CGFloat pieRadius;
@property(nonatomic, assign) BOOL    showLabel;
@property(nonatomic, strong) UIFont  *labelFont;
@property(nonatomic, strong) UIColor *labelColor;
@property(nonatomic, assign) CGFloat labelRadius;
@property(nonatomic, assign) CGFloat selectedSliceStroke;
@property(nonatomic, assign) CGFloat selectedSliceOffsetRadius;
@property(nonatomic, assign) BOOL    showPercentage;
@property(nonatomic, assign) mealType selectedMeal;

- (void)loadChart;
@end
