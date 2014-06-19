//
//  ViewController.h
//  CG
//
//  Created by versille on 5/4/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PieChartView.h"

@interface ViewController : UIViewController <PieChartViewDataSource>
@property (weak, nonatomic) IBOutlet PieChartView *PieChart;
@property (strong, nonatomic) NSMutableArray *sliceArray;
@property (strong, nonatomic) NSArray *sliceColor;
@property (weak, nonatomic) IBOutlet UIButton *breakfastButton;
@property (weak, nonatomic) IBOutlet UIButton *lunchButoon;
@property (weak, nonatomic) IBOutlet UIButton *dinnerButton;
@property (weak, nonatomic) IBOutlet UIButton *snackButton;
- (IBAction)buttonClicked:(id)sender;

@end
