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

#import "GSCXScannerTestCase.h"

#import <XCTest/XCTest.h>

#import "third_party/objective_c/EarlGreyV2/TestLib/EarlGreyImpl/EarlGrey.h"
#import "GSCXTestEnvironmentVariables.h"
#import "third_party/objective_c/GSCXScanner/Tests/FunctionalTests/Utils/GSCXScannerTestUtils.h"

@implementation GSCXScannerTestCase {
  XCUIApplication *_application;
}

- (void)setUp {
  [super setUp];

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _application = [[XCUIApplication alloc] init];
    _application.launchEnvironment = @{kEnvUseTestSharingDelegateKey : @"YES"};
    [_application launch];
  });
}

// Cleans up after each test case is run. Navigates to the original app screen so other test cases
// start from a valid state.
- (void)tearDown {
  [GSCXScannerTestUtils navigateToRootPage];
  [super tearDown];
}

@end
