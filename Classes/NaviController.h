//
//  NaviController.h
//  Created by WesleyYang on 13-8-5.
//  Copyright (c) 2013年 wesley.yang. All rights reserved.
//
//bug to fix: sysanimation doesn't support adding view to container.


/**
    NaviController is a tree based view controller container.
    Requires: ios target >= 5.0
 
- Why use:
    . Make complicated view controller's switch simple (Push,Pop,PopTo,Jump)
    . Enable push a view controller as many time as you like.
      You can choose to push it as a new VC or as a REF by setting identifier.
    . Make custom view transition animations easily.
    . Android style's view controller's communication(such as value pass and call back).
      Say goodbye to custom init and Delegate callbacks.
 
    NaviController provide 3 types of ViewController's transition:
    . PUSH : push a view controller(new or referrence) will add a node to current navigationTree. Push a view controller several times is allowed.
    . JUMP : jump to a exsiting vc. Jump do not add node to navigation tree, it simply moves current node to jump target.
    . POP  : pop to a target will cause navigation tree release subnode under target vc.
 
 
- ViewController's identifier
    A unique identifier is added to view controller when you push a view controller with no identifier specified. So you can always leave identifier nil. But identifier is a recommended way to identify view controller instead of VC instance variables. You can define identifier & viewcontroller's name in a global header file. Create viewcontroller using NSClassFromString. Reference viewcontroller using identifier. You can set identifier='view controller name' when this view controller is a singleton instance. This is a good way to sperate class implemetion and classes' interactions.
 
- Handel ViewController's Callback
        Usually we use a VC to push other VCs to finish a job. When those VCs finish this job, you'll want to notify the job owner and let owner handle all these stuffs.
    . Send a callback : A response should be send when you finish a job, and let parent controller do the dismiss job.
                        Use 'sendResponseWithResultCode' to send a response to parent controllers who want recieve this message.
                        callback will pass from parent controller to root controller until some one catches this callback.
    . Receive callback: A VC should implement method "didReceiveResponseFromViewController" to handle event from sub controllers.
                        This method has a return value of which YES means it can handle this callback and NO to continue pass on callback to parent controller.
 
 */ 



#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@class NANode;

/*******    User Config(modifiable)      *******/
#if DEBUG
#define DEBUG_NAVI      0       //log warning & error?
#else
#define DEBUG_NAVI      0
#endif

#define NA_VIEW_TRANSITION_DURATION     0.3
#define OVERRIDE_SYS_METHOD     0//override system transition method with swizzing. Note that do not use this when ViewDeckController is also in project.

// Config default action's animation(When you do not specify animationType). modify it as project needs.
#define NA_DEFAULT_PUSH_ANIMATION           ViewAnimationPush
#define NA_DEFAULT_POP_ANIMATION            ViewAnimationPop
#define NA_DEFAULT_JUMP_ANIMATION           ViewAnimationPush

// animation that used frequently
#define   ViewAnimationPush       ViewAnimationMoveIn|ViewAnimationDirectionLeft|ViewAnimationOptionEaseInOut
#define   ViewAnimationPop        ViewAnimationMoveOut|ViewAnimationDirectionRight|ViewAnimationOptionEaseInOut
#define   ViewAnimationPresent    ViewAnimationMoveIn|ViewAnimationDirectionUp|ViewAnimationOptionEaseInOut
#define   ViewAnimationDismiss    ViewAnimationMoveOut|ViewAnimationDirectionDown|ViewAnimationOptionEaseInOut
#define   ViewAnimationDropDown   ViewAnimationMoveIn|ViewAnimationDirectionDown|ViewAnimationOptionBounce

//result code used in view controller's interaction. You can change as you like or use your own code.
#define   NA_RESULT_STATUS_SUCCESS         200
#define   NA_RESULT_STATUS_CANCEL          0
#define   NA_RESULT_STATUS_FAIL            400

/*******    End User Config      *******/


typedef enum {
    ViewAnimationNone                     = 0,
    
    ViewAnimationMoveIn                   = 1<<0,//used for push
    ViewAnimationMoveOut                  = 1<<1,//used for pop
    
    //system animation
    ViewAnimationFlip                     = 1<<2,
    ViewAnimationCurlUp                   = 1<<3,
    ViewAnimationCurlDown                 = 1<<4,



    ViewAnimationDirectionUp              =1<<8,
    ViewAnimationDirectionDown            =1<<9,
    ViewAnimationDirectionLeft            =1<<10,
    ViewAnimationDirectionRight           =1<<11,

    //wait for you to implement
    ViewAnimationCustomPush               =1<<16,
    ViewAnimationCustomPop                =1<<17,

    //bounce can be used with move animation
    ViewAnimationOptionBounce             = 1<<20,
    
    ViewAnimationOptionEaseIn             =1<<21,
    ViewAnimationOptionEaseOut            =1<<22,
    ViewAnimationOptionEaseInOut          =1<<23,

    
}ViewAnimation;

         
typedef ViewAnimation ViewAnimationDirection;




@interface NaviController : UIViewController

/**
	Get current displaying view controller
 */
@property (nonatomic,readonly) UIViewController *topViewController;

@property (nonatomic,readonly) UIViewController *rootViewController;

@property (nonatomic,readonly) UIView    *containerView;



/**
	Initiate method: init with a root view controller.
 */
- (id) initWithRootViewController:(UIViewController*)rootVC identifiedBy:(id<NSCopying>)identifier;

/**
    Create View Controller that will be jumped to. This is a quick method to implement TabbarController like ViewController container.
    Note: use jump instead of push to transit to next view controller.
 */
- (void)addNextViewControllers:(NSArray*)viewControllers;

/**
	Get ViewController of specified identifier
 */
- (UIViewController*)viewControllerWithIdentifier:(id<NSCopying>)identifier;


- (UIViewController*)pushAndcreateViewControllerIfNeededOfClass:(Class)cls identifiedBy:(id<NSCopying>)identifier pushAnimation:(ViewAnimation)animation intent:(NSDictionary*)intent;

/**
     Push VC methods.
     @param vc : vc to be pushed. Push same VC is allowed.
     @param identifier: If identifier is nil, a random identifier will be generated for this VC.
     @param animation/animated: see ViewAnimation. 0 represents no animation. If no 'animation' param or animated=YES, use NA_DEFAULT_PUSH_ANIMATION
     @param intent:  data passed to vc 
 */
- (void)pushViewController:(UIViewController *)vc;

- (void)pushViewController:(UIViewController *)vc animated:(BOOL)animated;

- (void)pushViewController:(UIViewController*)vc intent:(NSDictionary*)intent;

-(void)pushViewController:(UIViewController *)vc animated:(BOOL)animated intent:(NSDictionary *)intent;

- (void)pushViewController:(UIViewController*)vc animation:(ViewAnimation)animation intent:(NSDictionary*)intent;

- (void)pushViewController:(UIViewController*)vc identifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation intent:(NSDictionary*)intent;

/**
     Pop VC methods
     @param identifier/controller: target controller or its identifier.
     @param animation /animated: animated=YES or no animation/animated param it will use NA_DEFAULT_POP_ANIMATION
 */
- (void)popViewControllerAnimated:(BOOL)animated;

- (void)popViewControllerWithAnimation:(ViewAnimation)animation;

- (void)popToViewController:(UIViewController*)controller animation:(ViewAnimation)animation;

- (void)popToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation;

- (void)popToRootViewControllerWithAnimation:(ViewAnimation)animation;


/**
    jump to view controller created before
	@param identifier/controller: target controller or its identifier.
	@param animation
	@param intent :  data passed to vc
 */
- (void)jumpToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation intent:(NSDictionary*)intent;

- (void)jumpToViewController:(UIViewController*)controller animation:(ViewAnimation)animation intent:(NSDictionary *)intent;


@end






@interface UIViewController (NaviControllerItem)


/**
    Any view controller added using NaviController will get this property set to the NaviController instance.
 
 */
@property(nonatomic,readonly,retain) NaviController *naviController;

/**
	intent comes from andriod which stores env. and activity information.
    You can use intent to store arguments(env. and inputs...) passed to other view controller.
 */
@property(nonatomic,copy)   NSDictionary   *intent;

/**
    View Controller's identifier identify the view controller. View Controller with the same identifier will be considered the same  when navigate through view controllers. 
    Thus you can use the same identifier to dequeue previous created view controller or navigate to that view controller. 
    Default identifier(random value) will be added when the view controller is added to naviController if you don't specify it.
 */
@property(nonatomic,copy)            id<NSCopying>  identifier;

-(void)sendResponseWithResultCode:(int)statusCode intent:(NSDictionary*)intent;


/**
    sub class should implement this method to receive response from child controllers.
	@param vc : from vc
	@param statusCode: code which indicate result status. You can customize as you like
	@param intent: params passed on
	@returns : return YES to indicate that response is processed. NO to let parent deal with this.
 */
-(BOOL)didReceiveResponseFromViewController:(UIViewController*)vc resultStatus:(int)statusCode intent:(NSDictionary*)intent;


/**
 add a view controller as current child. this controller will not be added to childviewcontroller but add in navigation tree. You can use jump viewcontroller to actually present this view controller.
 @param vc : from vc
 */
- (void)addNaviChildViewController:(UIViewController*)vc;


- (void)doAnimationWhenViewWillAppear;
- (void)doAnimationWhenViewDidlAppear;


@end



//===========================Private Class=============================//

#define NATree NANode

@interface NANode : NSObject

@property (nonatomic,retain) UIViewController  *data;
@property (nonatomic,copy)   id<NSCopying>     identifier;
@property (nonatomic,retain) NSMutableArray   *children;
@property (nonatomic,assign) NANode           *parent;

- (void) addChild:(NANode*)node;

-(void)removeChild:(NANode*)node;

-(void)removeAllChildren;

/**
	search parent with the identifier
	@param identifier
	@returns 
 */
- (NANode*)parentNodeIdentifiedBy:(id<NSCopying>)identifier;

- (NANode*)parentNodeWhichHasData:(UIViewController*)data;

- (NANode*)childNodeIdentifiedBy:(id<NSCopying>)identifier;

- (NANode*)childNodeWhichHasData:(UIViewController*)data;

+ (NANode*)nodeWithData:(UIViewController*)data;

@end



@interface CAKeyframeAnimation (NAKeyFrameAnimation)

+(CAKeyframeAnimation *)bounceAnimationFrom:(CGPoint)start to:(CGPoint)end;
+(CAKeyframeAnimation *)moveAnimationFrom:(CGPoint)start to:(CGPoint)end;

@end
