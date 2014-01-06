//
//  ViewController.m
//  TestNaviController
//
//  Created by Wesley Yang on 1/6/14.
//  Copyright (c) 2014 Ma. All rights reserved.
//

#import "ViewController2.h"
#import "ViewController.h"

@interface ViewController2 ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController2

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIColor *bgC = [UIColor colorWithHue:random()%100/100. saturation:0.6 brightness:0.9 alpha:1];
    self.view.backgroundColor = bgC;
    self.label.text = [NSString stringWithFormat:@"%d",[self getMyIndex]];
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
    [self.naviController pushViewController:vc animation:ViewAnimationPush intent:@{@"index":@([self getMyIndex]+1)}];
    
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
