BOOL prefHideTextNotificationCenter = YES;
BOOL prefPullToDismissEnabled = YES;
BOOL prefPullToDismissVibrateEnabled = YES;
float prefPullToDismissAmount = 150;

@interface NCNotificationCombinedListViewController : UIViewController
- (long long)collectionView:(id)arg1 numberOfItemsInSection:(long long)arg2;
- (void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2;
- (void)_clearAllNotificationRequests;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView;
@end

@interface NCNotificationListCollectionView : UICollectionView
@property (assign, nonatomic) NCNotificationCombinedListViewController *listDelegate;
@end

@interface NCNotificationListSectionHeaderView : UICollectionReusableView
@property (copy, nonatomic) NSString *title;
@property (nonatomic,retain) UILabel *titleLabel;
@end

@interface NCNotificationRequest
@property (nonatomic,copy,readonly) NSString * sectionIdentifier;
@end

@interface NCNotificationStructuredSectionList
- (void)clearAllNotificationRequests;
@end

@interface CSCombinedListViewController : UIViewController
- (void)forceNotificationHistoryRevealed:(bool)arg1 animated:(bool)arg2;
@end

@interface NCNotificationMasterList
@property (nonatomic,retain) NCNotificationStructuredSectionList * incomingSectionList;
@property (nonatomic,retain) NCNotificationStructuredSectionList * historySectionList;
@property (nonatomic,retain) NCNotificationStructuredSectionList * missedSectionList;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView;
@end

@interface NCNotificationStructuredListViewController : UIViewController
@property (nonatomic, weak) CSCombinedListViewController *delegate;
@end

@interface SBDashBoardViewController : UIViewController
@property(nonatomic, getter=isAuthenticated) BOOL authenticated;
@end

@interface CSCoverSheetViewController : UIViewController
@property(nonatomic, getter=isAuthenticated) BOOL authenticated;
@end

@interface SBLockScreenManager
@property (readonly, nonatomic) SBDashBoardViewController *dashBoardViewController;
@property (readonly, nonatomic) CSCoverSheetViewController *coverSheetViewController;

@end

NCNotificationListCollectionView *collectionView;
NCNotificationStructuredListViewController *combinedList;

BOOL dismiss = NO;

%group OneNotifyEnabled

	%hook NCNotificationListCollectionView

	- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
		collectionView = %orig;
		return collectionView;
	}

	%end

	%hook NCNotificationStructuredListViewController

	-(id)init {
		combinedList = %orig;
		return combinedList;
	}

	%end

	%hook SBScreenWakeAnimationController

		-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 delegate:(id)arg4 target:(id)arg5 completion:(/*^block*/id)arg6 {
			dispatch_async(dispatch_get_main_queue(), ^{
				[collectionView.listDelegate forceNotificationHistoryRevealed: YES animated: NO];
			});

			%orig;
		}

		-(void)prepareToWakeForSource:(long long)arg1 timeAlpha:(double)arg2 statusBarAlpha:(double)arg3 target:(id)arg4 completion:(/*^block*/id)arg5 {
			dispatch_async(dispatch_get_main_queue(), ^{
				[combinedList.delegate forceNotificationHistoryRevealed: YES animated: NO];
			});

			%orig;
		}

	%end

	%hook NCNotificationListSectionRevealHintView

		- (void)layoutSubviews {
			return;
		}

	%end

%end


%group HideNotificationCenter

	%hook NCNotificationListSectionHeaderView

	-(id)initWithFrame:(CGRect)arg1 {
		NCNotificationListSectionHeaderView *r = %orig;
		r.hidden = 1;
		return r;
	}

	%end

	%hook NCNotificationStructuredSectionList

	-(double)headerViewHeightForNotificationList:(id)arg1 {
		return 0;
	}

	%end

%end

%group PullToDismiss

	%hook NCNotificationMasterList

		- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
			%orig;
			if (scrollView.contentOffset.y < -scrollView.contentInset.top - prefPullToDismissAmount) {
				if (dismiss) return;
				dismiss = YES;
				[self kn_dismissAllNotifications: scrollView];
			}
		}

		- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
			%orig;
			dismiss = NO;
		}

		%new
		- (void)kn_dismissAllNotifications:(UIScrollView *)scrollView {
			if (prefPullToDismissVibrateEnabled) {
				UIImpactFeedbackGenerator *myGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:(UIImpactFeedbackStyleHeavy)];
				[myGen impactOccurred];
				myGen = NULL;
			}

			float scrollHeight = scrollView.contentOffset.y;
			[self.incomingSectionList clearAllNotificationRequests];
			[self.historySectionList clearAllNotificationRequests];
			[self.missedSectionList clearAllNotificationRequests];
			scrollView.contentOffset = CGPointMake(0, scrollHeight);
		}

	%end

%end

%ctor {
		%init(OneNotifyEnabled);

		if (prefHideTextNotificationCenter) %init(HideNotificationCenter);
		if (prefPullToDismissEnabled) %init(PullToDismiss);
}
