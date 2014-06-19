//
//  PieChartView.m
//  CG
//
//  Created by versille on 5/20/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import "PieChartView.h"

@interface SliceLayer : CAShapeLayer
@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, strong) NSString  *text;
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate;
@end

@implementation SliceLayer
- (NSString*)description
{
    return [NSString stringWithFormat:@"value:%f, percentage:%0.0f, start:%f, end:%f", _value, _percentage, _startAngle/M_PI*180, _endAngle/M_PI*180];
}
+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"]) {
        return YES;
    }
    else {
        return NO;
    }
}
- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer])
    {
        if ([layer isKindOfClass:[SliceLayer class]]) {
            self.startAngle = [(SliceLayer *)layer startAngle];
            self.endAngle = [(SliceLayer *)layer endAngle];
            self.isSelected = NO;
        }
    }
    return self;
}
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate
{
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    if(!currentAngle) currentAngle = from;
    [arcAnimation setFromValue:currentAngle];
    [arcAnimation setToValue:to];
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
//    [arcAnimation setDuration:10.0];
    [self addAnimation:arcAnimation forKey:key];
    [self setValue:to forKey:key];
}
@end

@interface PieChartView (Private)
- (void)updateTimerFired:(NSTimer *)timer;
- (SliceLayer *)createSliceLayer;
- (void)updateLabelForLayer:(SliceLayer *)pieLayer string:(NSString*)inputString value:(NSInteger)inputValue;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;
- (void)setSliceSelectedAtIndex:(NSInteger)index;

@end

@implementation PieChartView
{
    NSInteger selectedSliceIndex;
    //pie view, contains all slices
    UIView  *pieView;
    
    //animation control
    NSTimer *animationTimer;
    NSMutableArray *animations;
}
static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);
    
    return path;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        pieView = [[UIView alloc] initWithFrame:self.bounds];
        [pieView setBackgroundColor:[UIColor whiteColor]];
        [self insertSubview:pieView atIndex:0];
        
        selectedSliceIndex = -1;
        animations = [[NSMutableArray alloc] init];
        
        self.animationSpeed = 2;
        self.startPieAngle = M_PI_2*3;
        self.selectedSliceStroke = 3.0;
        
        CGRect bounds = [[self layer] bounds];
        self.pieRadius = MIN(bounds.size.width/2, bounds.size.height/2) - 10;
        self.pieCenter = CGPointMake(bounds.size.width/2, bounds.size.height/2);
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
        self.labelColor = [UIColor whiteColor];
        self.labelRadius = self.pieRadius*2/3;
        self.selectedSliceOffsetRadius = MAX(10, _pieRadius/10);
        
    }
    return self;

}

- (void)setPieCenter:(CGPoint)pieCenter
{
    [pieView setCenter:pieCenter];
    _pieCenter = CGPointMake(pieView.frame.size.width/2, pieView.frame.size.height/2);
}

- (void)setPieRadius:(CGFloat)pieRadius
{
    _pieRadius = pieRadius;
    CGPoint origin = pieView.frame.origin;
    CGRect frame = CGRectMake(origin.x+_pieCenter.x-pieRadius, origin.y+_pieCenter.y-pieRadius, pieRadius*2, pieRadius*2);
    [pieView setFrame:frame];
    [pieView.layer setCornerRadius:self.pieRadius];
}

- (void)loadChart
{
//    NSArray *dataArray = [NSArray arrayWithObjects:@12,@24,@36,nil];
    NSArray *dataArray = [self.dataSource getData:self.selectedMeal];
    NSArray *textArray = [NSArray arrayWithObjects:@"carbon",@"protein",@"fat",nil];
    CALayer *parentLayer = [pieView layer];
    NSArray *slicesArray = [parentLayer sublayers];

    CGFloat currentStartAngle = self.startPieAngle, currentEndAngle = 0;
    CGFloat startAngleMoveFrom = self.startPieAngle, startAngleMoveTo  = 0, endAngleMoveFrom = self.startPieAngle, endAngleMoveTo = 0;
    double sum = [[dataArray valueForKeyPath: @"@sum.self"] doubleValue];
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:self.animationSpeed];
    BOOL isOnStart = (slicesArray.count==0)?1:0;
    for (int i=0; i<dataArray.count; i++) {
        
        SliceLayer *oneSliceLayer;

        if (isOnStart)
        {
            oneSliceLayer = [self createSliceLayer];
            oneSliceLayer.text = [textArray objectAtIndex:i];
            UIColor *color = [UIColor colorWithHue:(i%3)/20.0+0.02 saturation:1 brightness:1 alpha:1];
            oneSliceLayer.fillColor = color.CGColor;
        }
        else
            oneSliceLayer = [slicesArray objectAtIndex:i];

        oneSliceLayer.percentage = [[dataArray objectAtIndex:i] doubleValue]/sum;
        oneSliceLayer.value = [[dataArray objectAtIndex:i] integerValue];
        
        if(oneSliceLayer.percentage<=0.001)
            oneSliceLayer.hidden = YES;
        else
            oneSliceLayer.hidden = NO;

        currentEndAngle = currentStartAngle + 2 * M_PI * oneSliceLayer.percentage;

        if (isOnStart)
        {
            startAngleMoveTo = currentStartAngle;
            endAngleMoveTo = currentEndAngle;
            CGPathRef path = CGPathCreateArc(self.pieCenter, self.pieRadius, oneSliceLayer.startAngle, oneSliceLayer.endAngle);
            [oneSliceLayer setPath:path];
            CFRelease(path);
        }
        else
        {
            startAngleMoveFrom = oneSliceLayer.startAngle;
            startAngleMoveTo = currentStartAngle;
            endAngleMoveFrom = oneSliceLayer.endAngle;
            endAngleMoveTo = currentEndAngle;
        }
        oneSliceLayer.startAngle = currentStartAngle;
        oneSliceLayer.endAngle = currentEndAngle;

        
        [self updateLabelForLayer:oneSliceLayer string:oneSliceLayer.text value:oneSliceLayer.value];

        [oneSliceLayer createArcAnimationForKey:@"startAngle"
                              fromValue:[NSNumber numberWithDouble:startAngleMoveFrom]
                                toValue:[NSNumber numberWithDouble:startAngleMoveTo]
                               Delegate:self];
        [oneSliceLayer createArcAnimationForKey:@"endAngle"
                              fromValue:[NSNumber numberWithDouble:endAngleMoveFrom]
                                toValue:[NSNumber numberWithDouble:endAngleMoveTo]
                               Delegate:self];

        if(isOnStart)
            [parentLayer addSublayer:oneSliceLayer];
        currentStartAngle = currentEndAngle;
    }
    [CATransaction commit];
    
}

- (SliceLayer *)createSliceLayer
{
    SliceLayer *pieLayer = [SliceLayer layer];
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        [textLayer setFont:font];
        CFRelease(font);
    }
    [textLayer setFontSize:self.labelFont.pointSize];
    [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setBackgroundColor:[UIColor colorWithWhite:0.25 alpha:1.0].CGColor];
    [textLayer setForegroundColor:self.labelColor.CGColor];
    [pieLayer addSublayer:textLayer];
    return pieLayer;
}

-(void)updateLabelForLayer:(SliceLayer *)pieLayer string:(NSString*)inputString value:(NSInteger)inputValue
{
    CATextLayer *textLayer = [[pieLayer sublayers] objectAtIndex:0];
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:8]};
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGSize size = [@"W" sizeWithAttributes:attributes];
    textLayer.frame = CGRectMake(textLayer.bounds.origin.x, textLayer.bounds.origin.y, MAX
                                 (size.width * inputString.length, size.width*4), size.height*4);
    CGFloat midAngle = (pieLayer.startAngle+pieLayer.endAngle)/2;
    CGFloat xshift = round(self.labelRadius*(cos(0-midAngle)));
    CGFloat yshift = 0-round(self.labelRadius * sin(0-midAngle));
    [textLayer setPosition:CGPointMake(self.pieCenter.x+xshift , self.pieCenter.y+yshift)];
    inputString = [NSString stringWithFormat:@"%@ \n %d%%", inputString, inputValue];
    [textLayer setString:inputString];
    
}

- (void)updateTimerFired:(NSTimer *)timer;
{
    CALayer *parentLayer = [pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(CAShapeLayer * obj, NSUInteger idx, BOOL *stop) {
        
        NSNumber *presentationLayerStartAngle = [[obj presentationLayer] valueForKey:@"startAngle"];
        CGFloat currentStartAngle = [presentationLayerStartAngle doubleValue];
        
        NSNumber *presentationLayerEndAngle = [[obj presentationLayer] valueForKey:@"endAngle"];
        CGFloat currentEndAngle = [presentationLayerEndAngle doubleValue];
        
        CGPathRef path = CGPathCreateArc(self.pieCenter, self.pieRadius, currentStartAngle, currentEndAngle);
        [obj setPath:path];
        CFRelease(path);
        
        CALayer *labelLayer = [[obj sublayers] objectAtIndex:0];
        CGFloat currentMidAngle = (currentEndAngle + currentStartAngle) / 2;
        [CATransaction setDisableActions:YES];
        [labelLayer setPosition:CGPointMake(self.pieCenter.x + round(self.labelRadius * cos(currentMidAngle)), self.pieCenter.y + round(self.labelRadius * sin(currentMidAngle)))];
        [CATransaction setDisableActions:NO];
    }];
}

- (void)animationDidStart:(CAAnimation *)anim
{

    if (animationTimer == nil) {
        static float timeInterval = 1.0/60.0;
        // Run the animation timer on the main thread.
        // We want to allow the user to interact with the UI while this timer is running.
        // If we run it on this thread, the timer will be halted while the user is touching the screen (that's why the chart was disappearing in our collection view).
        animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:animationTimer forMode:NSRunLoopCommonModes];
    }
    
    
    [animations addObject:anim];
 
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted
{
    
    [animations removeObject:anim];
    
    if ([animations count] == 0) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
}

- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSUInteger selectedIndex = -1;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CALayer *parentLayer = [pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];
    
    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *pieLayer = (SliceLayer *)obj;
        CGPathRef path = [pieLayer path];
        
        if (CGPathContainsPoint(path, &transform, point, 0)) {
            selectedIndex = idx;
        }
    }];
    return selectedIndex;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:pieView];
    [self getCurrentSelectedOnTouch:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:pieView];
    NSInteger currentIndex = [self getCurrentSelectedOnTouch:point];
    if (currentIndex!=-1) {
        if(currentIndex != selectedSliceIndex)
        {
            [self setSliceSelectedAtIndex:currentIndex];
            [self setSliceDeselectedAtIndex:selectedSliceIndex];
            selectedSliceIndex = currentIndex;
        }
        else
        {
            [self setSliceDeselectedAtIndex:selectedSliceIndex];
            selectedSliceIndex = -1;
        }
    }
//    [self notifyDelegateOfSelectionChangeFrom:self.selectedSliceIndex to:selectedIndex];
//    [self touchesCancelled:touches withEvent:event];
    
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    if(self.selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = [pieView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.isSelected) {
        CGPoint currPos = layer.position;
        double midAngle = (layer.startAngle + layer.endAngle)/2.0;
        NSInteger xshift =  round(self.selectedSliceOffsetRadius*cos(0-midAngle));
        NSInteger yshift =  0 - round(self.selectedSliceOffsetRadius*sin(0-midAngle));
        CGPoint newPos = CGPointMake(currPos.x + xshift, currPos.y +yshift);
        layer.position = newPos;
        layer.isSelected = YES;
    }
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    if(_selectedSliceOffsetRadius <= 0)
        return;
    SliceLayer *layer = [pieView.layer.sublayers objectAtIndex:index];
    if (layer && layer.isSelected) {
        layer.position = CGPointMake(0, 0);
        layer.isSelected = NO;
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
