   NaviController
========================
   
   NaviController is a tree based view controller container.
   
    Requires: ios target >= 5.0
 
### Advantage
    . Make complicated view controller's switch simple (Push,Pop,PopTo,Jump)
    . Enable push a view controller as many time as you like.
      You can choose to push it as a new VC or as a REF by setting identifier.
    . Make custom view transition animations easily.
    . Android style's view controller's communication(such as value pass and call back).
      Keep away from annoying custom init and Delegate callbacks.
 
    NaviController provide 3 types of ViewController's transition:

### Usage
```ObjectiveC
   //First init a naviController like UINavigationController and provide a root view controller.
   //In any view controller pushed by naviController, you can push/pop/jump to other view controller
   [self.naviController pushViewController:vc];
   //or if you like a present animation
   [self.naviController pushViewController:vc animation:ViewAnimationPresent];
   
   //and if you want to pass value to next view controller
   [self.naviController pushViewController:vc intent:@{@"input":@100}];
   //in the next view controller you can use self.intent to get the params passed by previous view controller.
   
   
   //when your view controllers done a job in a series view controllers, 
   //you may want to pass result to the job assigner.
   [self sendResponseWithResultCode:SomeCodeSuccess intent:myInfo];
   
   //parent view controller will receive this message and return YES to consume the message, 
   //or NO passing to his parent. In order to accomplish this, 
   //you'd implement this method in the view controllers who want to receive these message.
   -(BOOL)didReceiveResponseFromViewController:(UIViewController*)vc resultStatus:(int)statusCode intent:(NSDictionary*)intent{
      if(intent[@"job"] == JOB_I_ASSIGNED){
         if(statusCode == SomeCodeSuccess)
            ...
         else
            ...
         return YES;
      }
      return NO;
   }

   

```

### PUSH 
   push a view controller(new or referrence) will add a node to current navigationTree. Push a view controller several times is allowed.
```ObjectiveC
-(void)pushViewController:(UIViewController *)vc;

-(void)pushViewController:(UIViewController *)vc animated:(BOOL)animated;

- (void)pushViewController:(UIViewController*)vc intent:(NSDictionary*)intent;

-(void)pushViewController:(UIViewController *)vc animated:(BOOL)animated intent:(NSDictionary *)intent;
```


### JUMP
jump to a exsiting vc. Jump do not add node to navigation tree, it simply moves current node to jump target.
```ObjectiveC
- (void)jumpToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation intent:(NSDictionary*)intent;

- (void)jumpToViewController:(UIViewController*)controller animation:(ViewAnimation)animation intent:(NSDictionary *)intent;
```
### POP
pop to a target will cause navigation tree release subnode under target vc.
```ObjectiveC
- (void)popViewControllerAnimated:(BOOL)animated;

- (void)popViewControllerWithAnimation:(ViewAnimation)animation;

- (void)popToViewController:(UIViewController*)controller animation:(ViewAnimation)animation;

- (void)popToViewControllerIdentifiedBy:(id<NSCopying>)identifier animation:(ViewAnimation)animation;

```
 
 
### Identifier
   A unique identifier is added to view controller when you push a view controller with no identifier specified. So you can always leave identifier nil. But identifier is a recommended way to identify view controller instead of VC instance variables. You can define identifier & viewcontroller's name in a global header file. Create viewcontroller using NSClassFromString. Reference viewcontroller using identifier. You can set identifier='view controller name' when this view controller is a singleton instance. This is a good way to sperate class implemetion and classes' interactions.
 
### Handel ViewController's Callback
   Usually we use a VC to push other VCs to finish a job. When those VCs finish this job, you'll want to notify the job owner and let owner handle all these stuffs.
        
   . Send a callback : A response should be send when you finish a job, and let parent controller do the dismiss job.
                        Use 'sendResponseWithResultCode' to send a response to parent controllers who want recieve 
                        this message. callback will pass from parent controller to root controller until some one
                        catches this callback.
                        
   . Receive callback: A VC should implement method ```didReceiveResponseFromViewController``` to handle event from sub controllers.
    
   This method has a return value of which YES means it can handle this callback and NO to continue pass on callback to parent controller.
