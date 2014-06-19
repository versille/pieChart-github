//
//  ViewController.m
//  CG
//
//  Created by versille on 5/4/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.PieChart setDataSource:self];
    self.PieChart.selectedMeal = BREAKFAST;
    [self.PieChart loadChart];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)getData:(mealType)meal
{
    NSArray *result;
    switch (meal) {
        case BREAKFAST:
            result = [NSArray arrayWithObjects:@12,@24,@36,nil];
            break;
        case LUNCH:
            result = [NSArray arrayWithObjects:@24,@36,@12,nil];
            break;
        case DINNER:
            result = [NSArray arrayWithObjects:@36,@12,@24,nil];
            break;
        case SNACK:
            result = [NSArray arrayWithObjects:@12,@12,@12,nil];
            break;
            
        default:
            break;
    }
    return result;
}

-(void)buttonClicked:(id)sender
{
    self.PieChart.selectedMeal = [sender tag];
    [self.PieChart loadChart];
}




@end
