@interface CSCombinedListViewController : UIViewController
- (void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2;
@end

@interface NCNotificationStructuredListViewController : UIViewController
	@property (nonatomic, weak) CSCombinedListViewController *delegate;
@end

%hook NCNotificationStructuredListViewController

	- (instancetype)init {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceRevealNotifications:) name:@"forceRevealNotifications" object:nil];
    return %orig;
  }

  - (void)dealloc {
      [[NSNotificationCenter defaultCenter] removeObserver:self name:@"forceRevealNotifications" object:nil];
      %orig;
  }

  %new
  - (void)forceRevealNotifications:(NSNotification *)notification {

      [self.delegate forceNotificationHistoryRevealed: YES animated: NO];
  }

%end

%hook SBScreenWakeAnimationController

	-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 target:(id)arg4 completion:(/*^block*/id)arg5 {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"forceRevealNotifications" object:nil];
		});

		%orig;
	}

%end

%hook NCNotificationListSectionRevealHintView

	- (void)layoutSubviews {
		return;
	}

%end
