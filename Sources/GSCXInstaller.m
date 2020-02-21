//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "GSCXInstaller.h"

#import "GSCXAnalytics.h"
#import "GSCXContinuousScanner.h"
#import "GSCXContinuousScannerPeriodicScheduler.h"
#import "GSCXDefaultSharingDelegate.h"
#import "GSCXInstallerOptions+Internal.h"
#import "GSCXMasterScheduler.h"
#import "GSCXScanner.h"
#import "GSCXScannerOverlayViewController.h"
#import "GSCXScannerOverlayWindow.h"
#import "GSCXScannerWindowCoordinator+Internal.h"
#import "GSCXScannerWindowCoordinator.h"
#import "GSCXTouchActivitySource.h"

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval kGSCXContinuousScannerInterval = 2.0;

@implementation GSCXInstaller

+ (GSCXContinuousScanner *)
    _continuousScannerWithScanner:(GSCXScanner *)scanner
                  activitySources:
                      (nullable NSArray<id<GSCXActivitySourceMonitoring>> *)activitySources
                       schedulers:
                           (nullable NSArray<id<GSCXContinuousScannerScheduling>> *)schedulers
                         delegate:(id<GSCXContinuousScannerDelegate>)delegate {
  if (activitySources == nil) {
    activitySources = @[ [GSCXTouchActivitySource touchSource] ];
  }
  if (schedulers == nil) {
    schedulers = @[ [GSCXContinuousScannerPeriodicScheduler
        schedulerWithTimeInterval:kGSCXContinuousScannerInterval] ];
  }
  id<GSCXContinuousScannerScheduling> masterScheduler =
      [GSCXMasterScheduler schedulerWithActivitySources:activitySources schedulers:schedulers];
  return [GSCXContinuousScanner scannerWithScanner:scanner
                                          delegate:delegate
                                         scheduler:masterScheduler];
}

+ (GSCXScannerOverlayWindow *)installScannerWithOptions:(GSCXInstallerOptions *)options {
  BOOL setupSuccessful = [GTXTestEnvironment setupEnvironmentWithError:nil];
  CGRect frame = [[UIScreen mainScreen] bounds];
  GSCXScannerOverlayWindow *overlayWindow = [[GSCXScannerOverlayWindow alloc] initWithFrame:frame];
  GSCXScannerOverlayViewController *viewController = [[GSCXScannerOverlayViewController alloc]
           initWithNibName:@"GSCXScannerOverlayViewController"
                    bundle:[NSBundle bundleForClass:[GSCXScannerOverlayViewController class]]
      accessibilityEnabled:setupSuccessful || UIAccessibilityIsVoiceOverRunning()];
  viewController.scanner = [GSCXScanner scannerWithChecks:options.checks
                                               blacklists:options.blacklists];
  viewController.scanner.delegate = options.scannerDelegate;

  GSCXContinuousScanner *continuousScanner =
      [GSCXInstaller _continuousScannerWithScanner:viewController.scanner
                                   activitySources:options.activitySources
                                        schedulers:options.schedulers
                                          delegate:viewController];
  viewController.continuousScanner = continuousScanner;
  viewController.resultsWindowCoordinator = [GSCXScannerWindowCoordinator
      coordinatorWithMultiWindowPresentation:options.isMultiWindowPresentation];
  viewController.sharingDelegate =
      options.sharingDelegate ?: [[GSCXDefaultSharingDelegate alloc] init];
  // This forces the performScanButton into memory if it isn't already.
  [viewController loadViewIfNeeded];
  overlayWindow.windowLevel = [GSCXScannerWindowCoordinator windowLevel];
  overlayWindow.settingsButton = viewController.settingsButton;
  overlayWindow.rootViewController = viewController;
  overlayWindow.hidden = NO;
  overlayWindow.continuousScanner = continuousScanner;
  [GSCXAnalytics invokeAnalyticsEvent:GSCXAnalyticsEventScannerInstalled count:1];
  return overlayWindow;
}

+ (GSCXScannerOverlayWindow *)installScanner {
  return [GSCXInstaller installScannerWithOptions:[[GSCXInstallerOptions alloc] init]];
}

@end

NS_ASSUME_NONNULL_END
