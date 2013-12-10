//
//  NaviController.m
//  Navigator
//
//  Created by WesleyYang on 13-8-5.
//  Copyright (c) 2013年 wesley.yang. All rights reserved.
//



//
//  ARC Helper
//
//  Version 1.3
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef AH_RETAIN
#if __has_feature(objc_arc)
#define AH_RETAIN(x) (x)
#define AH_RELEASE(x) (void)(x)
#define AH_AUTORELEASE(x) (x)
#define AH_SUPER_DEALLOC (void)(0)
#define __AH_BRIDGE __bridge
#else
#define __AH_WEAK
#define AH_WEAK assign
#define AH_RETAIN(x) [(x) retain]
#define AH_RELEASE(x) [(x) release]
#define AH_AUTORELEASE(x) [(x) autorelease]
#define AH_SUPER_DEALLOC [super dealloc]
#define __AH_BRIDGE
#endif
#endif



//  Weak reference support



#ifndef AH_WEAK

#if defined __IPHONE_OS_VERSION_MIN_REQUIRED

#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3

#define __AH_WEAK __weak

#define AH_WEAK weak

#else

#define __AH_WEAK __unsafe_unretained

#define AH_WEAK unsafe_unretained

#endif

#elif defined __MAC_OS_X_VERSION_MIN_REQUIRED

#if __MAC_OS_X_VERSION_MIN_REQUIRED > __MAC_10_6

#define __AH_WEAK __weak

#define AH_WEAK weak

#else

#define __AH_WEAK __unsafe_unretained

#define AH_WEAK unsafe_unretained

#endif

#endif

#endif
//  ARC Helper ends

#import "NaviController.h"
#import <objc/message.h>
#import <objc/runtime.h>

#if DEBUG_NAVI
#define  NAVILOGE(fmt, ...) NSLog((@"\n[NaviController][ERROR] \n  " fmt), ##__VA_ARGS__);
#define  NAVILOGI(fmt, ...) NSLog((@"[NaviController][INFO] \n  " fmt), ##__VA_ARGS__);
#else
#define  NAVILOGE(...)
#define  NAVILOGI(...)
#endif


@interface NaviController ()
{
    NATree *_navigationTree;
    NANode *_currentNode;
    
//    UIViewController *topViewController;
}

@property (nonatomic,retain) UIViewController *animationController;
@property (nonatomic,copy)  void(^animationCompletion)();

-(void)handleEventFromVC:(UIViewController*)vc  statusCode:(int)code intent:(NSDictionary*)intent;
- (void)addChildViewController:(UIViewController*)vc underViewController:(UIViewController*)parentVC;


@end


@interface UIViewController (NaviControllerItem_Internal)

// internal setter for the viewDeckController property on UIViewController
- (void)setNaviController:(NaviController*)naviController;
- (void)setIntent:(NSDictionary *)intent;

@end


@implementation NaviController

-(id)initWithRootViewController:(UIViewController *)rootVC identifiedBy:(id<NSCopying>)identifier
{
    
    if (self = [self initWithNibName:nil bundle:nil]) {
        [rootVC setNaviController:self];
        
        id ident = identifier;
        if (ident==nil) {
            ident = [self setDefaultIdentiferForViewController:rootVC];
//            NAVILOGI(@"identifier:%@",ident);
        }else{
            rootVC.identifier = identifier;
        }
        
        _navigationTree = [[NANode nodeWithData:rootVC] retain];
        _navigationTree.data = rootVC;
        
        _currentNode = _navigationTree;
        
        
    }
    return self;
    
}

-(UIViewController *)rootViewController
{
    return _navigationTree.data;
}

-(void)loadView
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
	UIView *view = [[UIView alloc] initWithFrame:frame];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.backgroundColor = [UIColor clearColor];
    
	// set up content view a bit inset
	_containerView = [[UIView alloc] initWithFrame:view.bounds];
	_containerView.backgroundColor = [UIColor clearColor];
	_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[view addSubview:_containerView];
    
	// from here on the container is automatically adjusting to the orientation
	self.view = view;
    AH_RELEASE(view);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.topViewController.parentViewController == self) {
        return;
    }
    
    self.topViewController.view.frame = _containerView.bounds;
    self.topViewController.view.autoresizingMask = _containerView.autoresizingMask;

    [self addChildViewController:self.topViewController];
	[_containerView addSubview:self.topViewController.view];
    
	[self.topViewController didMoveToParentViewController:self];

}


-(void)dealloc
{
    AH_RELEASE(_navigationTree);
    AH_RELEASE(_containerView);
    AH_SUPER_DEALLOC;
}

#pragma mark -

-(UIViewController *)topViewController
{
    return _currentNode.data;
}

-(UIViewController *)viewControllerWithIdentifier:(id<NSCopying>)identifier
{
    NANode *nextNode = [_navigationTree childNodeIdentifiedBy:identifier];
    if ([(id)_navigationTree.identifier isEqual:identifier]) {
        nextNode = _navigationTree;
    }
    if (nextNode == nil) {
        return nil;
    }
    return nextNode.data;
}

- (UIViewController*)pushAndcreateViewControllerIfNeededOfClass:(Class)cls identifiedBy:(id<NSCopying>)identifier pushAnimation:(ViewAnimation)animation intent:(NSDictionary*)intent
{
    id<NSCopying> ident = identifier;
    if (ident==nil) {
        ident = NSStringFromClass(cls);
    }
    
    UIViewController *ctr = [self viewControllerWithIdentifier:ident];
    if (ctr == nil) {
        ctr = [[cls new] autorelease];
        ctr.identifier = ident;
        [self pushViewController:ctr animation:animation intent:intent];
    }else{
        [self jumpToViewControllerIdentifiedBy:ident animation:animation intent:intent];
    }
    

    
    return ctr;
}

-(void)pushViewController:(UIViewController *)vc
{
    [self pushViewController:vc identifiedBy:vc.identifier animation:NA_DEFAULT_PUSH_ANIMATION intent:nil];
}

- (void)pushViewController:(UIViewController *)vc animated:(BOOL)animated
{
    if (animated) {
        [self pushViewController:vc identifiedBy:vc.identifier animation:NA_DEFAULT_PUSH_ANIMATION intent:nil];
    }else{
        [self pushViewController:vc identifiedBy:vc.identifier animation:ViewAnimationNone intent:nil];
    }
}

-(void)pushViewController:(UIViewController *)vc intent:(NSDictionary *)intent
{
    [self pushViewController:vc identifiedBy:vc.identifier animation:NA_DEFAULT_PUSH_ANIMATION intent:intent];
}

-(void)pushViewController:(UIViewController *)vc animated:(BOOL)animated intent:(NSDictionary *)intent
{
    ViewAnimation animation = ViewAnimationNone;
    if (animated) {
        animation = NA_DEFAULT_PUSH_ANIMATION;
    }
    [self pushViewController:vc identifiedBy:vc.identifier animation:animation intent:intent];
}

-(void)pushViewController:(UIViewController *)vc animation:(ViewAnimation)animation intent:(NSDictionary *)intent
{
    [self pushViewController:vc identifiedBy:vc.identifier animation:animation intent:intent];
}

- (void)pushViewController:(UIViewController*)vc identifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation intent:(NSDictionary*)intent
{
    id ident = identifier;
    if (ident==nil) {
        ident = [self setDefaultIdentiferForViewController:vc];
//        NAVILOGI(@"identifier:%@",ident);
    }else{
        vc.identifier = identifier;
    }
    
    NANode *node = [NANode nodeWithData:vc];
    [_currentNode addChild:node];
    
    //  setup
    vc.intent = intent;
    vc.naviController = self;

//	vc.view.autoresizingMask = _containerView.autoresizingMask;
    
    //add
    [vc willMoveToParentViewController:self];
	[self addChildViewController:vc];
    
//    vc.view.frame = _containerView.bounds;

    
    [self transitionFromViewController:self.topViewController toViewController:vc animation:animation isNew:YES completion:^{
        [self.topViewController removeFromParentViewController];
        [vc didMoveToParentViewController:self];
        _currentNode = node;
        

    }];
    
}

- (void)addChildViewController:(UIViewController*)vc underViewController:(UIViewController*)parentVC
{
    if (vc.identifier==nil) {
        vc.identifier = [self setDefaultIdentiferForViewController:vc];
    }
    
    NANode *node = [NANode nodeWithData:vc];
    NANode *parent = [_navigationTree childNodeIdentifiedBy:parentVC.identifier];
    if (parent==nil && _navigationTree.identifier==parentVC.identifier) {
        parent = _navigationTree;
    }
    
    [parent addChild:node];
    
    //  setup
    vc.naviController = self;
}

-(void)jumpToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation intent:(NSDictionary *)intent
{
   
    NANode *nextNode = [_navigationTree childNodeIdentifiedBy:identifier];
    if ([(id)_navigationTree.identifier isEqual:identifier]) {
        nextNode = _navigationTree;
    }
    if (nextNode == nil) {
        NAVILOGE(@"ViewController identified by %@ not found",identifier);
        return;
    }
    if (nextNode.data == self.topViewController) {
//        NAVILOGE(@"Jump to ViewController [id][%@] which is current showing!",identifier);
        return;
    }
    
    [self jumpToNode:nextNode animation:animation intent:intent];
}

-(void)jumpToViewController:(UIViewController*)controller animation:(ViewAnimation)animation intent:(NSDictionary *)intent
{
    NANode *nextNode = [_navigationTree childNodeWhichHasData:controller];
    if (nextNode==nil && _navigationTree.data==controller) {
        nextNode = _navigationTree;
    }
    if (nextNode == nil) {
        NAVILOGE(@"ViewController %@ not found",controller);
        return;
    }
    if (nextNode.data == self.topViewController) {
//        NAVILOGE(@"Jump to ViewController [%@] which is current showing!",controller);
        return;
    }
    
    [self jumpToNode:nextNode animation:animation intent:intent];

}

-(void)jumpToNode:(NANode*)nextNode animation:(ViewAnimation)animation intent:(NSDictionary *)intent
{
    [self addChildViewController:nextNode.data];
    
    [self transitionFromViewController:self.topViewController toViewController:nextNode.data animation:animation isNew:NO  completion:^{
        [nextNode.data didMoveToParentViewController:self];
        [self.topViewController removeFromParentViewController];
        _currentNode = nextNode;
    }];
}

-(void)popToRootViewControllerWithAnimation:(ViewAnimation)animation
{
    [self popToNode:_navigationTree animation:animation];
}

-(void)popViewControllerAnimated:(BOOL)animated
{
    ViewAnimation animation = ViewAnimationNone;
    if (animated) {
        animation = NA_DEFAULT_POP_ANIMATION;
    }
    [self popViewControllerWithAnimation:animation];
}

-(void)popViewControllerWithAnimation:(ViewAnimation)animation
{
    if (_currentNode.parent == nil) {
        NAVILOGE(@"PopViewController failed.No super view controller available!");
        return;
    }
    [self popToViewControllerIdentifiedBy:_currentNode.parent.identifier animation:animation];
}

-(void)popToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation
{
    if (identifier==nil) {
        NAVILOGE(@"PopToViewController: nil identifier");
        return;
    }
    
    NANode *parentNode = [_currentNode parentNodeIdentifiedBy:identifier];
    if (parentNode==nil) {
        NAVILOGE(@"PopToViewController identified by %@ not found!",identifier);
        return;
    }
    
    [self popToNode:parentNode animation:animation];
}

-(void)popToViewController:(UIViewController*)controller animation:(ViewAnimation)animation
{
    if (controller==nil) {
        NAVILOGE(@"PopToViewController nil controller");
        return;
    }
    
    NANode *parentNode = [_currentNode parentNodeWhichHasData:controller];
    if (parentNode==nil) {
        NAVILOGE(@"PopToViewController  controller %@ not found!",controller.identifier);
        return;
    }
    [self popToNode:parentNode animation:animation];
}

-(void)popToNode:(NANode*)parentNode animation:(ViewAnimation)animation
{
    [parentNode.data willMoveToParentViewController:self];
    [self addChildViewController:parentNode.data];
    

    
    
    
    [self transitionFromViewController:self.topViewController toViewController:parentNode.data animation:animation isNew:NO completion:^{
        [self.topViewController willMoveToParentViewController:nil];
        [self.topViewController removeFromParentViewController];
        
        [parentNode.data didMoveToParentViewController:self];
        
        NANode *parent = _currentNode.parent;
        
        if (parent==parentNode) {
            [parentNode removeChild:_currentNode];
            
        }else{
            while (YES){
                if (parent.parent == parentNode) {
                    //remove only this child:parent
                    [parentNode removeChild:parent];
                    break;
                }
                [parent removeAllChildren];
                parent = parent.parent;
            }
        }
        _currentNode = parentNode;

    }];

}



-(NSString*)setDefaultIdentiferForViewController:(UIViewController*)vc
{
    NSString *ident = [NSString stringWithFormat:@"%@%ld%ld",NSStringFromClass([vc class]),time(0),random()];
    vc.identifier = ident;
    return ident;
}


-(void)handleEventFromVC:(UIViewController*)vc  statusCode:(int)code intent:(NSDictionary*)intent
{
    NANode *thisNode = [self findNodeWithController:vc];
    if (thisNode==nil) {
        NAVILOGE(@"Handle event: %@ not found",vc);
        return;
    }
    
    NANode *parent = thisNode.parent;

    BOOL processed = NO;

    while(parent){
        
        UIViewController *parentVC = parent.data;
        
        if([parentVC respondsToSelector:@selector(didReceiveResponseFromViewController:resultStatus:intent:)]){
             processed = [parentVC didReceiveResponseFromViewController:vc resultStatus:code intent:intent];
            if(processed)break;
        }
        
        parent = parent.parent;
    }

    if(processed==NO){
        NAVILOGI(@"Event from [id]%@ is throwed away as no one would like process it. Implement -didReceiveResponseFromViewController.. to catch callbacks.",vc.identifier);
    }
}


-(void)sendResponseWithResultCode:(int)statusCode intent:(NSDictionary *)intent
{
    NAVILOGE(@"Use [viewcontroller sendResponseWithResultCode..] instead of [self.naviController send...]");
    return;
}

- (NANode*)findNodeWithController:(UIViewController*)vc
{
    if (vc == nil) {
        return nil;
    }
    NANode *nextNode = [_navigationTree childNodeWhichHasData:vc];
    if (_navigationTree.data==vc) {
        nextNode = _navigationTree;
    }
  
    return nextNode;
}

#pragma mark Animation

- (void)transitionFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController animation:(ViewAnimation)animation isNew:(BOOL)isNew completion:(void(^)())completion
{
    if (fromViewController == toViewController)
	{
		// cannot transition to same
        NAVILOGI(@"Transit same view controllers .");
		return;
	}
    
    toViewController.view.frame = _containerView.bounds;

    [_containerView addSubview:toViewController.view];
    [toViewController doAnimationWhenViewWillAppear];

    void(^animationBlock)() = ^(){};

    UIViewAnimationOptions sysAnimationOption = 0;
    float animationDuration = NA_VIEW_TRANSITION_DURATION;
    ViewAnimation direction = 0;
    
    CGPoint startPosition0 = fromViewController.view.layer.position;
    CGPoint endPosition0 = startPosition0;
    CGPoint startPosition1 = toViewController.view.layer.position;
    CGPoint endPosition1 = startPosition1;
    
    if (animation&ViewAnimationDirectionDown) {
        direction = ViewAnimationDirectionDown;
    }else if(animation&ViewAnimationDirectionLeft){
        direction = ViewAnimationDirectionLeft;
    }else if(animation&ViewAnimationDirectionRight){
        direction = ViewAnimationDirectionRight;
    }else if(animation&ViewAnimationDirectionUp){
        direction = ViewAnimationDirectionUp;
    }
    
    
    BOOL shouldFlip = animation & ViewAnimationFlip;
    BOOL shouldMoveIn = animation & ViewAnimationMoveIn;
    BOOL shouldMoveOut = animation & ViewAnimationMoveOut;
    BOOL shouldCurlUp = animation & ViewAnimationCurlUp;
    BOOL shouldCurlDown = animation & ViewAnimationCurlDown;
    BOOL shouldCustomPush = (animation & ViewAnimationCustomPush)!=0;
    BOOL shouldCustomPop = (animation & ViewAnimationCustomPop)!=0;
    BOOL shouldBounce = (animation & ViewAnimationOptionBounce)!=0;
    CAMediaTimingFunction *timingFunction = nil;
    if ((animation & ViewAnimationOptionEaseIn)!=0 ) {
        timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    }else if((animation & ViewAnimationOptionEaseOut)!=0 ) {
        timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    }else if((animation & ViewAnimationOptionEaseInOut)!=0 ) {
        timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    }

    
    
    if (shouldFlip) {
        if (direction==0) {
            direction = ViewAnimationDirectionLeft;
        }
        if (direction==ViewAnimationDirectionLeft) {
            sysAnimationOption |= UIViewAnimationOptionTransitionFlipFromLeft;
        }else if(direction==ViewAnimationDirectionRight)
            sysAnimationOption |= UIViewAnimationOptionTransitionFlipFromRight;
        else if (direction==ViewAnimationDirectionUp)
            sysAnimationOption |= UIViewAnimationOptionTransitionFlipFromBottom;
        else
            sysAnimationOption |= UIViewAnimationOptionTransitionFlipFromTop;
        
    }else if(shouldCurlUp){
        sysAnimationOption |= UIViewAnimationOptionTransitionCurlUp;
        
    }else if(shouldCurlDown){
        sysAnimationOption |= UIViewAnimationOptionTransitionCurlDown;
        
    }else if(shouldMoveIn){
        
        switch (direction) {
            case ViewAnimationDirectionLeft:
                startPosition1.x += self.view.frame.size.width;
                endPosition0.x -= self.view.frame.size.width;
                break;
            case ViewAnimationDirectionRight:
                startPosition1.x -= self.view.frame.size.width;
                endPosition0.x += self.view.frame.size.width;
                break;
            case ViewAnimationDirectionDown:
                startPosition1.y -= self.view.frame.size.height;
                break;
            default:
                startPosition1.y += self.view.frame.size.height;
                break;
        }
//        toViewController.view.frame = startFrame;
        
        
       
    }else if(shouldMoveOut){        

        switch (direction) {
            case ViewAnimationDirectionLeft:
                endPosition1.x -= self.view.frame.size.width;
                startPosition0.x += self.view.frame.size.width;
                break;
            case ViewAnimationDirectionRight:
                endPosition1.x += self.view.frame.size.width;
                startPosition0.x -= self.view.frame.size.width;
                break;
            case ViewAnimationDirectionDown:
                endPosition1.y += self.view.frame.size.height;
                break;
            default:
                endPosition1.y -= self.view.frame.size.height;
                break;
        }
        
    
        
    }
    // Your custom animation
    else if(shouldCustomPop|shouldCustomPush){
        
    }
    

    //for custom trasition
    if (sysAnimationOption==0) {


        if(animation){
            CAKeyframeAnimation *animation0,*animation1;
            
            if (shouldBounce) {
                animation0 = [CAKeyframeAnimation bounceAnimationFrom:startPosition0 to:endPosition0];
                animation1 = [CAKeyframeAnimation bounceAnimationFrom:startPosition1 to:endPosition1];
            }else{
                animation0 = [CAKeyframeAnimation moveAnimationFrom:startPosition0 to:endPosition0];
                animation1 = [CAKeyframeAnimation moveAnimationFrom:startPosition1 to:endPosition1];
            }
            
            if (shouldBounce) {
                animationDuration*=3;
            }
            
            animation0.duration = animationDuration;
            animation1.duration = animationDuration;
            animation0.timingFunction = timingFunction;
            animation1.timingFunction = timingFunction;

            animation1.delegate = self;
            if (shouldMoveIn) {
                [toViewController.view.layer addAnimation:animation1 forKey:@"movein"];
                [fromViewController.view.layer addAnimation:animation0 forKey:@"moveout"];
            }else{
                [self.containerView bringSubviewToFront:fromViewController.view];
                [toViewController.view.layer addAnimation:animation0 forKey:@"movein"];
                [fromViewController.view.layer addAnimation:animation1 forKey:@"moveout"];
                fromViewController.view.center = endPosition1;
            }
            self.animationController = fromViewController;
            self.animationCompletion = completion;
            
           
        }else{
            [fromViewController.view removeFromSuperview];
            completion();
        }

    }else{
    
        //for system transition
        [self transitionFromViewController:fromViewController
					  toViewController:toViewController
							  duration:animationDuration
							   options:sysAnimationOption
							animations:animationBlock
							completion:^(BOOL finished) {
								completion();
							}];
    }
    
    
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.animationController) {
        [self.animationController.view removeFromSuperview];
        _animationCompletion();
        AH_RELEASE( self.animationCompletion );
        AH_RELEASE( self.animationController );
        _animationController = nil;
        _animationCompletion = nil;
        [self.topViewController doAnimationWhenViewDidlAppear];
    }
}



@end


#pragma mark -

@implementation UIViewController (NaviControllerItem)

@dynamic naviController;
@dynamic intent;
@dynamic identifier;

static const char* naviControllerKey = "NaviControllerKey";
static const char* intentKey = "NaviIntentKey";
static const char* identifierKey = "NaviIdentifierKey";

- (void)addNaviChildViewController:(UIViewController*)vc
{
    return [self.naviController addChildViewController:vc underViewController:self];
}

- (NaviController*)naviController_core {
    return objc_getAssociatedObject(self, naviControllerKey);
}

- (NaviController*)naviController {
    id result = [self naviController_core];
    if (!result && self.navigationController)
        result = [self.navigationController naviController];
//    if (!result && [self respondsToSelector:@selector(wrappedController)] && self.wrappedController)
//        result = [self.wrappedController naviController];
    
    return result;
}

- (void)setNaviController:(NaviController*)naviController {
    objc_setAssociatedObject(self, naviControllerKey, naviController, OBJC_ASSOCIATION_ASSIGN);
}

-(NSDictionary *)intent
{
    id it = objc_getAssociatedObject(self, intentKey);
    return it;
}

-(void)setIntent:(NSDictionary *)intent
{
    objc_setAssociatedObject(self, intentKey, intent, OBJC_ASSOCIATION_COPY);
}

-(id<NSCopying>)identifier
{
    return objc_getAssociatedObject(self, identifierKey);
}

-(void)setIdentifier:(id<NSCopying>)identifier
{
    objc_setAssociatedObject(self, identifierKey, identifier, OBJC_ASSOCIATION_COPY);
}

-(void)doAnimationWhenViewDidlAppear
{
    
}

-(void)doAnimationWhenViewWillAppear
{
    
}

-(void)sendResponseWithResultCode:(int)statusCode intent:(NSDictionary *)intent
{
    [self.naviController handleEventFromVC:self statusCode:statusCode intent:intent];
}

-(BOOL)didReceiveResponseFromViewController:(UIViewController *)vc resultStatus:(int)statusCode intent:(NSDictionary *)intent
{
    return NO;
}

//whether need to override viewcontroller's push pop present...

#if OVERRIDE_SYS_METHOD
- (void)na_presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
    UIViewController* naviController = self.naviController;
    if (naviController==nil && [self isKindOfClass:[NaviController class]]) {
        naviController = self;
    }
    if(naviController){
        ViewAnimation animation = animated? ViewAnimationPresent:0;
        [(NaviController*)naviController pushViewController:modalViewController animation:animation intent:nil];
    }else{
        [self na_presentModalViewController:modalViewController animated:animated]; // when we get here, the na_ method is actually the old, real method
    }

}

- (void)na_dismissModalViewControllerAnimated:(BOOL)animated {
    UIViewController* naviController = self.naviController;
    if (naviController==nil && [self isKindOfClass:[NaviController class]]) {
        naviController = self;
    }
    if(naviController){
        ViewAnimation animation = animated? ViewAnimationDismiss:0;
        [(NaviController*)naviController popViewControllerWithAnimation:animation];
    }else{
        [self na_dismissModalViewControllerAnimated:animated]; // when we get here, the na_ method is actually the old, real method
    }
}

#ifdef __IPHONE_5_0

- (void)na_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)animated completion:(void (^)(void))completion {

    UIViewController* naviController = self.naviController;
    if (naviController==nil && [self isKindOfClass:[NaviController class]]) {
        naviController = self;
    }
    if(naviController && !completion){
        ViewAnimation animation = animated? ViewAnimationPresent:0;
        [(NaviController*)naviController pushViewController:viewControllerToPresent animation:animation intent:nil];
    }else{
        if (completion) {
            NAVILOGE(@"current naviController do not support completion block");
        }
        [self na_presentViewController:viewControllerToPresent animated:animated completion:completion]; // when we get here, the na_ method is actually the old, real method
    }
}

- (void)na_dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    UIViewController* naviController = self.naviController;
    if (naviController==nil && [self isKindOfClass:[NaviController class]]) {
        naviController = self;
    }
    if(naviController && !completion){
        ViewAnimation animation = animated? ViewAnimationDismiss:0;
        [(NaviController*)naviController popViewControllerWithAnimation:animation];
    }else{
        if (completion) {
            NAVILOGE(@"current naviController do not support completion block");
        }
        [self na_dismissViewControllerAnimated:animated completion:completion]; // when we get here, the na_ method is actually the old, real method
    }
}

#endif //end iphone 5

//- (UINavigationController*)na_navigationController {
//    UIViewController* controller = self.naviController_core ? self.naviController_core : self;
//    return [controller na_navigationController]; // when we get here, the na_ method is actually the old, real method
//}
//
//- (UINavigationItem*)na_navigationItem {
//    UIViewController* controller = self.naviController_core ? self.naviController_core : self;
//    return [controller na_navigationItem]; // when we get here, the na_ method is actually the old, real method
//}

+ (void)na_swizzle {
    SEL presentModal = @selector(presentModalViewController:animated:);
    SEL vdcPresentModal = @selector(na_presentModalViewController:animated:);
    method_exchangeImplementations(class_getInstanceMethod(self, presentModal), class_getInstanceMethod(self, vdcPresentModal));
    
    SEL presentVC = @selector(presentViewController:animated:completion:);
    SEL vdcPresentVC = @selector(na_presentViewController:animated:completion:);
    method_exchangeImplementations(class_getInstanceMethod(self, presentVC), class_getInstanceMethod(self, vdcPresentVC));
    
    
    SEL dismissModal = @selector(dismissModalViewControllerAnimated:);
    SEL vdcDissmissModal = @selector(na_dismissModalViewControllerAnimated:);
    method_exchangeImplementations(class_getInstanceMethod(self, dismissModal), class_getInstanceMethod(self, vdcDissmissModal));
    
    SEL dismissVC = @selector(dismissViewControllerAnimated:completion:);
    SEL vdcDismissVC = @selector(na_dismissViewControllerAnimated:completion:);
    method_exchangeImplementations(class_getInstanceMethod(self, dismissVC), class_getInstanceMethod(self, vdcDismissVC));
//    SEL nc = @selector(navigationController);
//    SEL vdcnc = @selector(na_navigationController);
//    method_exchangeImplementations(class_getInstanceMethod(self, nc), class_getInstanceMethod(self, vdcnc));
//    
//    SEL ni = @selector(navigationItem);
//    SEL vdcni = @selector(na_navigationItem);
//    method_exchangeImplementations(class_getInstanceMethod(self, ni), class_getInstanceMethod(self, vdcni));
    
    // view containment drop ins for <ios5
//    SEL willMoveToPVC = @selector(willMoveToParentViewController:);
//    SEL vdcWillMoveToPVC = @selector(na_willMoveToParentViewController:);
//    if (!class_getInstanceMethod(self, willMoveToPVC)) {
//        Method implementation = class_getInstanceMethod(self, vdcWillMoveToPVC);
//        class_addMethod([UIViewController class], willMoveToPVC, method_getImplementation(implementation), "v@:@");
//    }
//    
//    SEL didMoveToPVC = @selector(didMoveToParentViewController:);
//    SEL vdcDidMoveToPVC = @selector(na_didMoveToParentViewController:);
//    if (!class_getInstanceMethod(self, didMoveToPVC)) {
//        Method implementation = class_getInstanceMethod(self, vdcDidMoveToPVC);
//        class_addMethod([UIViewController class], didMoveToPVC, method_getImplementation(implementation), "v@:");
//    }
//    
//    SEL removeFromPVC = @selector(removeFromParentViewController);
//    SEL vdcRemoveFromPVC = @selector(na_removeFromParentViewController);
//    if (!class_getInstanceMethod(self, removeFromPVC)) {
//        Method implementation = class_getInstanceMethod(self, vdcRemoveFromPVC);
//        class_addMethod([UIViewController class], removeFromPVC, method_getImplementation(implementation), "v@:");
//    }
//    
//    SEL addCVC = @selector(addChildViewController:);
//    SEL vdcAddCVC = @selector(na_addChildViewController:);
//    if (!class_getInstanceMethod(self, addCVC)) {
//        Method implementation = class_getInstanceMethod(self, vdcAddCVC);
//        class_addMethod([UIViewController class], addCVC, method_getImplementation(implementation), "v@:@");
//    }
}

+ (void)load {
    [super load];
    [self na_swizzle];
}

#endif//end override system

@end

@implementation UIViewController (NaviController_ViewContainmentEmulation_Fakes)

//- (void)na_addChildViewController:(UIViewController *)childController {
//    // intentionally empty
//}
//
//- (void)na_removeFromParentViewController {
//    // intentionally empty
//}
//
//- (void)na_willMoveToParentViewController:(UIViewController *)parent {
//    // intentionally empty
//}
//
//- (void)na_didMoveToParentViewController:(UIViewController *)parent {
//    // intentionally empty
//}




@end


@implementation NANode

+(NANode *)nodeWithData:(id)data
{
    NANode *node = [[NANode alloc] init];
    node.data = data;
    return AH_AUTORELEASE(node);
}

-(id)init
{
    if (self=[super init]) {
        self.children = [NSMutableArray array];
    }
    return self;
}

-(id<NSCopying>)identifier
{
    return _data.identifier;
}

-(void)setIdentifier:(id<NSCopying>)identifier
{
    [_data setIdentifier:identifier];
}

-(void)addChild:(NANode *)node
{
    if (node) {
        [self.children addObject:node];
        node.parent = self;
    }
}

-(void)removeChild:(NANode*)node
{
    if (node) {
        [self.children removeObject:node];
    }
}

-(void)removeAllChildren
{
    [self.children removeAllObjects];
}

-(NANode *)parentNodeIdentifiedBy:(id<NSCopying>)identifier
{
    NANode *par = self.parent;
    while(par) {
        if ([(id)par.identifier isEqual: identifier]) {
            return par;
        }
        par = par.parent;
    }
    return nil;
}

-(NANode *)parentNodeWhichHasData:(UIViewController *)data
{
    NANode *par = self.parent;
    while(par) {
        if (par.data == data) {
            return par;
        }
        par = par.parent;
    }
    return nil;
}

-(NANode *)childNodeIdentifiedBy:(id<NSCopying>)identifier
{
   
    for (NANode *child in self.children) {
        if ([(id)child.identifier isEqual:identifier]) {
            return child;
        }
        NANode *resultNode = [child childNodeIdentifiedBy:identifier];
        if (resultNode) {
            return resultNode;
        }
        
    }
    
    return nil;
}

-(NANode *)childNodeWhichHasData:(UIViewController *)data
{
    for (NANode *child in self.children) {
        if (child.data==data) {
            return child;
        }
        NANode *resultNode = [child childNodeWhichHasData:data];
        if (resultNode) {
            return resultNode;
        }
        
    }
    
    return nil;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"[%@]%@",self.identifier,self.children];
}


-(void)dealloc
{
    NAVILOGI(@"dealloc node%@",self.identifier);
    self.identifier = nil;
    self.data = nil;
    self.children = nil;
    AH_SUPER_DEALLOC;
}

@end



@implementation CAKeyframeAnimation (NAKeyFrameAnimation)


+(CAKeyframeAnimation *)bounceAnimationFrom:(CGPoint)start to:(CGPoint)end
{

    int frames = 200;
    
    NSMutableArray *values =[NSMutableArray array];
    
    for (int i=0; i<=frames; ++i) {
        float k = BounceEaseOut(i/(float)frames);
        float x = (end.x-start.x)*k+start.x;
        float y = (end.y-start.y)*k+start.y;
        [values addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }

    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    [animation setValues:values];
    animation.duration = 2;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 1;
    
    return animation;
    
}

+(CAKeyframeAnimation *)moveAnimationFrom:(CGPoint)start to:(CGPoint)end
{    
    NSMutableArray *values =[NSMutableArray array];
    
    [values addObject:[NSValue valueWithCGPoint:start]];
    [values addObject:[NSValue valueWithCGPoint:end]];

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    [animation setValues:values];
    animation.duration = 2;
    animation.removedOnCompletion = NO;
    animation.repeatCount = 1;
    
    return animation;
}


float BounceEaseOut(float p)
{
	if(p < 4/11.0)
	{
		return (121 * p * p)/16.0;
	}
	else if(p < 8/11.0)
	{
		return (363/40.0 * p * p) - (99/10.0 * p) + 17/5.0;
	}
	else if(p < 9/10.0)
	{
		return (4356/361.0 * p * p) - (35442/1805.0 * p) + 16061/1805.0;
	}
	else
	{
		return (54/5.0 * p * p) - (513/25.0 * p) + 268/25.0;
	}
}

@end

