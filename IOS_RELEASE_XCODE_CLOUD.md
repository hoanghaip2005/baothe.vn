# Hướng dẫn release iOS lên App Store Connect bằng Xcode Cloud

Cập nhật: 2026-05-14

Tài liệu này dành cho dự án Flutter `baothe_vn`, sau khi app đã chạy ổn trên simulator và cần chuẩn bị luồng release iOS qua App Store Connect, TestFlight và Xcode Cloud.

## Thông tin dự án hiện tại

| Hạng mục | Giá trị hiện tại |
| --- | --- |
| Flutter package | `baothe_vn` |
| iOS workspace | `ios/Runner.xcworkspace` |
| Scheme | `Runner` |
| Bundle ID | `com.baothe.app` |
| Apple Team ID trong project | `5MNN7PQYBD` |
| Version hiện tại | `1.0.0+7` trong `pubspec.yaml` |
| App Store Connect app | `BaoThe`, Apple ID `6763936547`, SKU `baothevn-ios` |
| Display name | `BaoThe` trong `Info.plist` và Xcode build setting |
| iOS deployment target | `15.0` trong `Podfile`, một số setting của Runner đang là `16.6` |
| Capability đang dùng | Push Notifications, Sign in with Apple |

Trước khi upload bản đầu tiên, nên chốt lại 3 điểm:

1. Tên app hiển thị trên máy và tên trên App Store dùng thống nhất `BaoThe`.
2. Minimum iOS support là `15.0` hay `16.6`; nên chỉnh đồng nhất trong Xcode target Runner và `ios/Podfile`.
3. Bundle ID `com.baothe.app` phải trùng trong Apple Developer, App Store Connect, Firebase iOS app và Xcode project.

## 1. Điều kiện cần

Cần có tài khoản Apple Developer Program đang hoạt động. Nếu chỉ có Apple ID thường thì có thể chạy simulator/local device ở mức giới hạn, nhưng không upload App Store/TestFlight qua App Store Connect được.

Cần quyền phù hợp trong App Store Connect. Tối thiểu nên có quyền `Admin`, `App Manager` hoặc quyền được cấp cho app `BaoThe` để tạo app record, cấu hình TestFlight và gửi review.

Cần repository Git đã push lên remote mà Xcode Cloud truy cập được. Repo hiện tại đang trỏ tới:

```text
https://github.com/tuanminh2409bn/baothe.vn.git
```

Các file quan trọng cần được commit:

```text
pubspec.yaml
pubspec.lock
ios/Podfile
ios/Podfile.lock
ios/Runner.xcodeproj/project.pbxproj
ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
ios/Runner/GoogleService-Info.plist
ios/Runner/Info.plist
ios/Runner/Runner.entitlements
```

Không commit các file sinh tự động/local:

```text
.dart_tool/
build/
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
ios/Flutter/ephemeral/
ios/build/
```

## 2. Cấu hình Apple Developer

Vào Apple Developer > Certificates, Identifiers & Profiles > Identifiers và tạo hoặc kiểm tra App ID:

```text
Bundle ID: com.baothe.app
Type: Explicit App ID
```

Bật các capability tương ứng với project:

```text
Push Notifications
Sign in with Apple
```

Nếu dùng Firebase Cloud Messaging cho thông báo, cần tạo APNs Auth Key trong Apple Developer và upload vào Firebase Console > Project settings > Cloud Messaging. Key này không commit vào repository.

Trong Xcode, mở `ios/Runner.xcworkspace`, chọn target `Runner` > Signing & Capabilities:

```text
Team: 5MNN7PQYBD
Bundle Identifier: com.baothe.app
Automatically manage signing: bật
```

Nếu team id hiện tại không phải team sẽ release app, đổi lại team trước khi archive hoặc cấu hình Xcode Cloud.

## 3. App record trong App Store Connect

App record hiện đã tồn tại trong App Store Connect:

```text
Platform: iOS
Name: BaoThe
Primary Language: Vietnamese
Bundle ID: com.baothe.app
SKU: baothevn-ios
Apple ID: 6763936547
```

Sau khi tạo app record, hoàn thiện các phần sau:

```text
App Information: category nên chọn Finance nếu app quản lý thẻ/tài chính cá nhân.
Pricing and Availability: chọn giá và quốc gia phát hành.
App Privacy: khai báo dữ liệu thu thập, liên kết tài khoản, analytics, crash logs, Firebase.
Age Rating: trả lời đúng theo nội dung app.
Privacy Policy URL: bắt buộc nên cần có URL public trước khi submit.
Support URL: nên có URL public.
Screenshots: chuẩn bị ảnh cho các kích thước iPhone bắt buộc.
Review Notes: ghi cách đăng nhập/test account nếu app cần tài khoản.
Export Compliance: trả lời theo việc app có dùng mã hóa ngoài HTTPS/Firebase SDK mặc định hay không.
```

Vì app có Google Sign-In và Sign in with Apple dependency, cần đảm bảo luồng đăng nhập Apple hoạt động trên thiết bị thật trước khi gửi review.

## 4. Chuẩn bị version release

Mỗi lần upload build mới lên App Store Connect, `build number` phải tăng. Với Flutter, chỉnh trong `pubspec.yaml`:

```yaml
version: 1.0.0+2
```

Trong đó:

```text
1.0.0 = version người dùng thấy trên App Store
2     = build number nội bộ, phải tăng sau mỗi lần upload
```

Kiểm tra nhanh local trước khi để Xcode Cloud archive:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter test
flutter build ios --release --no-codesign
```

Nếu cần tự xuất IPA local để upload thủ công:

```bash
flutter build ipa --release --build-name 1.0.0 --build-number 2
```

Sau đó upload bằng Xcode Organizer hoặc app Transporter. Luồng local này là phương án dự phòng; luồng chính bên dưới dùng Xcode Cloud.

## 5. Chuẩn bị Flutter cho Xcode Cloud

Xcode Cloud build từ môi trường sạch, vì vậy không nên dựa vào `D:\flutter`, `.dart_tool`, `Generated.xcconfig` hoặc cache local. Với Flutter project, nên thêm custom script để Xcode Cloud cài Flutter và chạy `pub get` trước khi archive.

Vì workspace nằm ở `ios/Runner.xcworkspace`, tạo file:

```text
ios/ci_scripts/ci_post_clone.sh
```

Nội dung đang dùng trong repo:

```sh
#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "error: Missing Xcode Cloud environment variable GEMINI_API_KEY"
  exit 1
fi

mkdir -p lib/src/constants
cat > lib/src/constants/api_keys.dart <<EOF
class ApiKeys {
  static const geminiApiKey = '$GEMINI_API_KEY';
}
EOF

FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter pub get
flutter precache --ios

if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi

cd ios
pod install --repo-update
```

Khuyến nghị: sau khi build ổn, thay `-b stable` bằng tag Flutter cụ thể đang dùng cho release để build có thể lặp lại ổn định hơn.

Trong Xcode Cloud workflow, thêm Environment Variable dạng secret:

```text
GEMINI_API_KEY=<Gemini API key production>
```

Không commit `lib/src/constants/api_keys.dart`; file này được tạo tự động trong Xcode Cloud và đang nằm trong `.gitignore`.

Trên macOS hoặc môi trường có Git executable bit, chạy:

```bash
chmod +x ios/ci_scripts/ci_post_clone.sh
git add ios/ci_scripts/ci_post_clone.sh
git update-index --chmod=+x ios/ci_scripts/ci_post_clone.sh
git commit -m "Add Xcode Cloud Flutter setup script"
git push origin main
```

Nếu Xcode Cloud báo không tìm thấy `pod`, thêm bước cài CocoaPods trước `pod install`:

```sh
if ! command -v pod >/dev/null 2>&1; then
  brew install cocoapods
fi
```

## 6. Tạo workflow Xcode Cloud

Trên Mac có Xcode:

1. Mở `ios/Runner.xcworkspace`, không mở `Runner.xcodeproj`.
2. Đăng nhập Apple ID có quyền với team trong Xcode > Settings > Accounts.
3. Chọn scheme `Runner`.
4. Vào Product > Xcode Cloud > Create Workflow hoặc mở Xcode Cloud từ Report navigator.
5. Chọn repository GitHub của dự án và branch `main`.
6. Chọn product/scheme `Runner`.
7. Chọn environment Xcode `26` hoặc mới hơn. App Store Connect hiện từ chối IPA build bằng iOS 18.5 SDK/Xcode 16.4.
8. Workflow action nên gồm:

```text
Analyze: optional
Test: optional, bật nếu test iOS ổn định
Archive: required
Post-action: Upload to App Store Connect hoặc Distribute to TestFlight
```

Trigger đề xuất:

```text
Manual: bật để chủ động release.
Pull Request: optional, chỉ analyze/test.
Branch main push: optional, chỉ bật khi quy trình version đã ổn định.
Tag release: khuyến nghị về sau, ví dụ v1.0.0-build.2.
```

Với bản release đầu tiên, nên để workflow chạy manual để dễ kiểm soát build number và metadata.

## 7. Xuất build qua Xcode Cloud

Quy trình release chuẩn:

1. Tăng version/build number trong `pubspec.yaml`.
2. Commit và push code lên branch `main`.
3. Vào Xcode hoặc App Store Connect > Xcode Cloud > chọn workflow > Start Build.
4. Đợi action `Archive` hoàn tất.
5. Nếu workflow có post-action upload, build sẽ xuất hiện trong App Store Connect > My Apps > app > TestFlight > Builds sau khi Apple xử lý xong.
6. Gán build cho Internal Testing trước.
7. Nếu test nội bộ ổn, thêm External Testing. External Testing thường cần Beta App Review.
8. Khi build ổn để submit App Store, vào tab App Store > version đang chuẩn bị > chọn build > Submit for Review.

Lưu ý: với Xcode Cloud, output chính là archive/build được đưa lên App Store Connect/TestFlight. Nếu cần file `.ipa` để lưu nội bộ, dùng luồng local `flutter build ipa` hoặc tải artifact nếu workflow/tài khoản hiển thị artifact phù hợp.

## 8. Checklist trước khi submit App Review

```text
[ ] App chạy được trên thiết bị thật iPhone, không chỉ simulator.
[ ] Google Sign-In hoạt động với bundle ID com.baothe.app.
[ ] Sign in with Apple hoạt động trên thiết bị thật.
[ ] Push notification/Firebase Messaging hoạt động hoặc tắt nếu chưa dùng.
[ ] App icon 1024x1024 không có alpha.
[ ] Launch screen không lỗi layout.
[ ] Version/build number đã tăng.
[ ] App Store screenshots đủ kích thước bắt buộc.
[ ] Privacy Policy URL và Support URL truy cập public.
[ ] App Privacy khai báo đúng Firebase/Auth/Firestore/Analytics nếu có.
[ ] Firestore rules production không mở quá rộng.
[ ] Không commit API key/server secret/private key.
[ ] Có test account hoặc hướng dẫn review nếu app cần đăng nhập.
```

## 9. Lỗi thường gặp

`FLUTTER_ROOT not found` hoặc `Generated.xcconfig must exist`

Xcode Cloud chưa chạy được `flutter pub get`. Kiểm tra file `ios/ci_scripts/ci_post_clone.sh`, executable bit và vị trí file phải nằm cạnh workspace `ios/Runner.xcworkspace`.

`No profiles for com.baothe.app were found`

Bundle ID, team, capability hoặc automatic signing chưa khớp giữa Xcode project và Apple Developer.

`The bundle version must be higher than the previously uploaded version`

Tăng phần sau dấu `+` trong `pubspec.yaml`, ví dụ `1.0.0+3`.

`Runner has conflicting provisioning settings`

Kiểm tra target `Runner` > Signing & Capabilities, ưu tiên bật automatic signing nếu chưa có nhu cầu signing thủ công.

Lỗi liên quan Push entitlement

Kiểm tra App ID đã bật Push Notifications, provisioning profile đúng loại App Store/Ad Hoc/TestFlight và capability trong Xcode khớp với Apple Developer. Không tự đổi entitlement nếu chưa archive lại và xem lỗi cụ thể.

Lỗi deployment target

Đồng nhất `IPHONEOS_DEPLOYMENT_TARGET` trong Xcode target Runner và `platform :ios` trong `ios/Podfile`. Với dự án hiện tại, đang có cả `15.0` và `16.6`.

## Tài liệu chính thức nên tham khảo

- Apple Developer Program enrollment: https://developer.apple.com/programs/enroll/
- Register an App ID: https://developer.apple.com/help/account/identifiers/register-an-app-id/
- Add a new app in App Store Connect: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Xcode Cloud overview: https://developer.apple.com/documentation/xcode/xcode-cloud
- Configure an Xcode Cloud workflow: https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow
- Custom build scripts for Xcode Cloud: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
- Flutter iOS deployment: https://docs.flutter.dev/deployment/ios
