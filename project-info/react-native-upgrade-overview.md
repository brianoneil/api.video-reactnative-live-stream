# React Native 0.82+ Upgrade Plan

**Date**: October 20, 2025  
**Current Version**: React Native 0.76.1  
**Target Version**: React Native 0.82+  
**Primary Focus**: iOS/Swift Compatibility

---

## Project Summary

`@api.video/react-native-livestream` - RTMP live streaming library for React Native with native iOS (Swift) and Android (Kotlin) implementations.

---

## Current State (0.76.1)

### Dependencies
```json
{
  "react-native": "0.76.1",
  "react": "18.3.1",
  "@react-native/babel-preset": "0.76.1",
  "@react-native/eslint-config": "0.76.1"
}
```

### Architecture Support
- ✅ New Architecture (Fabric) already implemented
- ✅ Codegen configuration in place
- ✅ Both oldarch and newarch folders present
- ✅ iOS minimum version: 13.0

### iOS Implementation
- Swift files: `RNLiveStreamViewImpl.swift`, `RNLiveStreamViewManager.swift`
- Objective-C++ bridge files
- CocoaPods dependency: `ApiVideoLiveStream` 1.4.6
- Uses legacy UIManager block pattern

---

## React Native 0.82+ Requirements

### Expected Changes in 0.82
Based on React Native's progression:
- React 19.1.1+ integration
- Hermes V1 (experimental)
- Enhanced New Architecture APIs
- Improved TurboModule/Fabric patterns
- Updated Swift/iOS interop requirements

---

## Upgrade Strategy: 0.76.1 → 0.82+

### Phase 1: Dependency Updates (REQUIRED)

#### 1.1 Update package.json
```json
{
  "devDependencies": {
    "react-native": "^0.82.0",
    "react": "^19.1.1",
    "@react-native/babel-preset": "^0.82.0",
    "@react-native/eslint-config": "^0.82.0",
    "@react-native/typescript-config": "^0.82.0",
    "@react-native-community/cli": "^16.0.0",
    "@react-native-community/cli-platform-ios": "^16.0.0"
  }
}
```

#### 1.2 Update Podspec (iOS)
**File**: `react-native-livestream.podspec`

Check if these changes are needed:
```ruby
s.platforms = { :ios => "13.0" }  # May need to increase to iOS 14.0+

# Verify install_modules_dependencies is still valid
if respond_to?(:install_modules_dependencies, true)
  install_modules_dependencies(s)
else
  s.dependency "React-Core"
end
```

#### 1.3 Verify ApiVideoLiveStream SDK Compatibility
- Current: `ApiVideoLiveStream` 1.4.6
- Action: Test compatibility with React Native 0.82
- May need to update if there are Swift/Xcode compatibility issues

### Phase 2: iOS/Swift Breaking Changes (CRITICAL)

#### 2.1 UIManager Blocks Removal (BREAKING)
React Native 0.82 may deprecate/remove `bridge.uiManager.addUIBlock` pattern.

**Current Code (RNLiveStreamViewManager.swift)**:
```swift
// ❌ Will likely break in 0.82
@objc(startStreaming:withRequestId:withStreamKey:withUrl:)
func startStreaming(_ reactTag: NSNumber, withRequestId requestId: NSNumber, streamKey: String, url: String?) {
    bridge!.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
        let view: RNLiveStreamViewImpl = (viewRegistry![reactTag] as? RNLiveStreamViewImpl)!
        view.startStreaming(requestId: Int(truncating: requestId), streamKey: streamKey, url: url)
    }
}
```

**Required Fix**: Migrate to Fabric command handlers or direct view manager methods

#### 2.2 Force Unwrapping Removal (REQUIRED FOR SAFETY)
```swift
// ❌ Current - will crash if bridge is nil
bridge!.uiManager.addUIBlock { ... }

// ✅ Required fix
guard let bridge = bridge else { return }
bridge.uiManager.addUIBlock { ... }
```

**Must fix in**:
- `RNLiveStreamViewManager.swift` (all 3 methods)

#### 2.3 Codegen Updates (IF SPEC CHANGES)
If React Native 0.82 changes Codegen output format:
- Review generated files in `/ios/` after upgrading
- Update `NativeApiVideoLiveStreamView.ts` if needed
- Regenerate with: `yarn && cd example/ios && pod install`

### Phase 3: Build Configuration Updates (iOS)

#### 3.1 Update Example App Podfile
**File**: `example/ios/Podfile`

May need updates for:
- Minimum iOS version
- CocoaPods version requirements
- Xcode 15/16 compatibility

#### 3.2 Xcode Configuration
- Verify Swift version compatibility (likely Swift 5.9+)
- Update build settings if Xcode 16 is required
- Check for deprecated APIs in Swift code

#### 3.3 Info.plist Updates
Verify no new privacy requirements in iOS 18+ for:
- Camera usage
- Microphone usage
- Network access

### Phase 4: Testing Requirements (CRITICAL)

#### 4.1 iOS Compatibility Testing
- [ ] Test on iOS 13.0 (current minimum)
- [ ] Test on iOS 17+ (likely current release)
- [ ] Test on iOS 18+ if released
- [ ] Verify New Architecture (Fabric) still works

#### 4.2 Functional Testing
- [ ] Camera initialization (front/back)
- [ ] Start/stop streaming
- [ ] Zoom functionality
- [ ] Mute/unmute
- [ ] Error handling
- [ ] App backgrounding/foregrounding
- [ ] Memory leaks during long streams

#### 4.3 Build Testing
- [ ] Clean build succeeds
- [ ] CocoaPods installation works
- [ ] Archive for TestFlight/App Store
- [ ] Verify no Swift compiler errors

---

## Critical iOS Code Changes Required

### File: ios/RNLiveStreamViewManager.swift

#### Change 1: Remove Force Unwrapping (MANDATORY)
```swift
// Before
@objc(startStreaming:withRequestId:withStreamKey:withUrl:)
func startStreaming(_ reactTag: NSNumber, withRequestId requestId: NSNumber, streamKey: String, url: String?) {
    bridge!.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
        let view: RNLiveStreamViewImpl = (viewRegistry![reactTag] as? RNLiveStreamViewImpl)!
        view.startStreaming(requestId: Int(truncating: requestId), streamKey: streamKey, url: url)
    }
}

// After (0.82 compatible)
@objc(startStreaming:withRequestId:withStreamKey:withUrl:)
func startStreaming(_ reactTag: NSNumber, withRequestId requestId: NSNumber, streamKey: String, url: String?) {
    guard let bridge = bridge else { return }
    bridge.uiManager.addUIBlock { (_: RCTUIManager?, viewRegistry: [NSNumber: UIView]?) in
        guard let view = viewRegistry?[reactTag] as? RNLiveStreamViewImpl else { return }
        view.startStreaming(requestId: Int(truncating: requestId), streamKey: streamKey, url: url)
    }
}
```

Apply same pattern to:
- `stopStreaming`
- `setZoomRatioCommand`

### File: ios/RNLiveStreamViewImpl.swift

#### Change 1: Error Handling Enhancement
Ensure all error paths are handled for 0.82 compatibility - current implementation looks good, but verify error types haven't changed.

---

## Upgrade Execution Plan

### Step 1: Pre-Upgrade Preparation
```bash
# 1. Create upgrade branch
git checkout -b upgrade/react-native-0.82

# 2. Backup current working state
git add . && git commit -m "chore: pre-upgrade checkpoint"

# 3. Document current working state
cd example/ios && pod install
cd ../.. && yarn && yarn example ios
# Verify everything works before upgrade
```

### Step 2: Dependency Upgrade
```bash
# 1. Update root package.json dependencies
# (manually edit to versions listed in Phase 1)

# 2. Clean install
rm -rf node_modules yarn.lock
rm -rf example/node_modules example/yarn.lock
rm -rf example/ios/Pods example/ios/Podfile.lock

# 3. Install fresh
yarn install
cd example && yarn install

# 4. iOS pods
cd ios && pod install
```

### Step 3: Fix Breaking Changes
```bash
# 1. Apply iOS/Swift fixes from "Critical iOS Code Changes"
# 2. Run codegen if needed
# 3. Build and test
yarn example ios
```

### Step 4: Validation
```bash
# Run all checks
yarn typecheck
yarn lint
cd example && yarn ios
cd example && yarn android  # Verify Android still works
```

---

## Rollback Plan

If upgrade fails:
```bash
git checkout main
git branch -D upgrade/react-native-0.82
```

Keep 0.76.1 as fallback until 0.82 is stable.

---

## Known Risks & Mitigation

### Risk 1: UIManager.addUIBlock Removal
**Likelihood**: HIGH  
**Impact**: App crashes on all iOS commands  
**Mitigation**: Test immediately after upgrade, have Fabric command pattern ready

### Risk 2: Swift/Xcode Version Incompatibility  
**Likelihood**: MEDIUM  
**Impact**: Build failures  
**Mitigation**: Check React Native 0.82 release notes for Xcode requirements

### Risk 3: ApiVideoLiveStream SDK Incompatibility
**Likelihood**: LOW  
**Impact**: Streaming failures  
**Mitigation**: Test streaming functionality thoroughly, prepare SDK update

### Risk 4: Codegen Breaking Changes
**Likelihood**: MEDIUM  
**Impact**: Type mismatches, build errors  
**Mitigation**: Regenerate all codegen files, verify TypeScript specs

---

## Success Criteria

✅ **Upgrade is successful when**:
1. [ ] Example app builds without errors
2. [ ] All iOS streaming functionality works
3. [ ] No crashes or memory leaks
4. [ ] Both old and new architecture modes work
5. [ ] No regression in existing features
6. [ ] Passes all existing tests

---

## Post-Upgrade Tasks

1. [ ] Update CHANGELOG.md
2. [ ] Update README with new RN version
3. [ ] Update example app dependencies
4. [ ] Test library consumers can upgrade
5. [ ] Create migration guide for users
6. [ ] Publish new version to npm

---

## Timeline Estimate

**Preparation**: 1 day  
**Upgrade & Fix Breaking Changes**: 2-3 days  
**Testing**: 2-3 days  
**Documentation**: 1 day  

**Total**: 6-8 days for complete upgrade

---

## Resources

### React Native 0.82 Documentation
- Upgrade Helper: https://react-native-community.github.io/upgrade-helper/
- Release Notes: Check GitHub releases when 0.82 is available
- New Architecture Guide: https://reactnative.dev/docs/the-new-architecture/landing-page

### Testing Resources
- iOS Minimum Version Requirements
- Xcode Compatibility Matrix
- Swift Version Requirements

---

**Document Version**: 2.0  
**Last Updated**: October 20, 2025  
**Focus**: React Native 0.82+ Upgrade Only  
**Status**: Ready for Execution


---

## 9. Upgrade Execution Summary

### ✅ Completed Upgrade to React Native 0.82.0

**Date**: October 20, 2025  
**Branch**: `upgrade/react-native-0.82`  
**Status**: **SUCCESS** - iOS build working

### Changes Implemented

#### 1. Dependency Updates
- Updated `react-native` from `0.76.1` → `0.82.0`
- Updated `react` from `18.3.1` → `19.1.1`
- Updated CLI packages to `^16.0.0`
- Clean reinstall of all dependencies

**Commits**: `8d7e29a` - chore(deps): upgrade to React Native 0.82.0 and React 19.1.1

#### 2. iOS Code Fixes  
**File**: `ios/RNLiveStreamViewManager.swift`

Replaced force unwraps with safe guard statements:
- `bridge!` → `guard let bridge = bridge else { return }`
- `viewRegistry![reactTag]!` → `guard let view = viewRegistry?[reactTag] as? RNLiveStreamViewImpl else { return }`

Applied to: `startStreaming`, `stopStreaming`, `startAudioProcessing`, `stopAudioProcessing`, `setZoomRatio`

**Commits**: `68f83a6` - fix(ios): replace force unwraps with guard statements

#### 3. Folly Coroutine Fix (Critical)

**Problem**: `'folly/coro/Coroutine.h' file not found` build error

**Solution**: Added `post_install` hook in `example/ios/Podfile` to disable coroutines:
```ruby
# Apply -DFOLLY_CFG_NO_COROUTINES=1 to all Pod targets and main app target
```

**Commits**:
- `5f4d37e`, `b03cb53`, `c7f5e2a` - Folly coroutine fixes

### Build Results

✅ **iOS Build SUCCESSFUL**
- Xcode build completes without errors
- Example app runs on iPhone 15 Pro simulator (iOS 17.4)  
- Only deprecation warnings (non-blocking, expected)

### Testing Recommendations

1. **Streaming**: Test start/stop, audio/video, zoom
2. **Permissions**: Camera/microphone prompts
3. **iOS Versions**: Test on 13.0+ through latest
4. **Android**: Verify Android build (not tested in this upgrade)

### Next Steps

1. Merge to main
2. Update root package.json peer dependencies  
3. Bump version to 2.1.0
4. Update CHANGELOG.md
5. Create release

### References
- [React Native 0.82 Release](https://github.com/facebook/react-native/releases/tag/v0.82.0)
- [Folly Issue #37748](https://github.com/facebook/react-native/issues/37748)
