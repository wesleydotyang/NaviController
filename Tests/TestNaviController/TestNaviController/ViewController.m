//
//  ViewController.m
//  TestNaviController
//
//  Created by Wesley Yang on 1/6/14.
//  Copyright (c) 2014 Ma. All rights reserved.
//

#import "ViewController.h"
#import "ViewController2.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIColor *bgC = [UIColor colorWithHue:random()%100/100. saturation:0.6 brightness:0.9 alpha:1];
    self.view.backgroundColor = bgC;
    self.label.text = [NSString stringWithFormat:@"%d",[self getMyIndex]];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"view will appear");
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"view did appear");
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"view will disappear");
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"view did disappear");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int)getMyIndex
{
    if (self.intent[@"index"]) {
        return [self.intent[@"index"] intValue];
    }
    return 0;
}
- (IBAction)doPush:(id)sender {
    ViewController *vc = [ViewController new];
    ViewController2 *vc2 = [ViewController2 new];

    [self.naviController pushViewController:vc animation:ViewAnimationNone intent:@{@"index":@([self getMyIndex]+1)}];
    [self.naviController pushViewController:vc animation:ViewAnimationPush intent:@{@"index":@([self getMyIndex]+2)}];

}

- (IBAction)doPush2:(id)sender {
    ViewController2 *vc = [ViewController2 new];
    [self.naviController pushViewController:vc animation:ViewAnimationPush intent:@{@"index":@([self getMyIndex]+1)}];
}

- (IBAction)doPop:(id)sender {
    [self.naviController popViewControllerAnimated:YES];
}


-(void)dealloc
{
    NSLog(@"dealloc %@",NSStringFromClass([self class]));
}

@end
