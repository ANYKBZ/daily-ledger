# 收支本 / Daily Ledger

一款简洁、温和、设备本地优先的个人收支记录应用。使用 Flutter 构建，支持简体中文和英文。

A calm, local-first personal income and expense tracker built with Flutter. The interface supports Simplified Chinese and English.

## 视觉设计 / Visual design

界面采用现代记账应用常见的快速录入、大金额焦点、圆角数据卡、分类图标和月度圆环图结构，并加入原创的紫金“比赛夜”主题。球场线条、8/24 徽章和黑曼巴动势表达专注精神，但不使用 NBA、湖人官方标识或科比肖像。

The interface combines the quick-entry, amount-first, card-based structure common to modern finance apps with an original purple-and-gold game-night theme. Court lines, an 8/24 badge, and mamba-inspired motion cues express focus without using NBA or Lakers marks or Kobe Bryant's likeness.

原创图标源文件位于 `assets/branding/mamba-ledger-icon-v1.png`。

## 第一版功能 / Version 1

- 手动记录美元收入和支出
- 餐饮、交通、购物、住房、其他五类支出
- 按日期分组的月度明细
- 人民币与美元实时换算（Frankfurter 最新官方参考汇率）
- 编辑、左滑删除与撤销
- 月度收入、支出、结余和支出分类圆环图
- 相机与相册小票入口（自动识别将在下一阶段加入）
- SQLite 设备本地存储

---

- Record USD income and expenses manually
- Five expense categories: food, transport, shopping, housing, and other
- Monthly transactions grouped by date
- CNY/USD conversion using Frankfurter's latest official reference rate
- Edit, swipe to delete, and undo
- Monthly totals and expense breakdown chart
- Camera and photo-library receipt entry point (recognition comes next)
- Local SQLite storage

## 项目结构 / Project structure

三个主要页面分别维护：

```text
lib/pages/entry_page.dart
lib/pages/transactions_page.dart
lib/pages/statistics_page.dart
```

共享数据通过 `LedgerRepository` 和 `LedgerController` 管理。金额以整数美分存储，账目日期以本地 `YYYY-MM-DD` 存储。

## 本地运行 / Run locally

本项目当前固定使用 Flutter 3.35.7，以兼容开发机上的 macOS Ventura 13.7。升级 macOS 后可以迁移到较新的 Flutter stable。

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

iOS开发需要完整 Xcode 15.2或更高版本。正式提交 App Store 前需要升级到满足 Apple 当前 SDK要求的 macOS和Xcode版本。

## 隐私 / Privacy

第一版不包含账号、云同步、银行连接或广告。账目保存在设备本地。小票图片不会复制到应用的持久存储中。

Version 1 has no accounts, cloud sync, bank connections, or advertising. Ledger data stays on the device, and receipt images are not copied into persistent app storage.

货币换算通过无需密钥的 Frankfurter API 获取央行公布的最新日参考汇率。汇率仅供参考，不等于银行、信用卡或兑换机构的实际成交价；断网时应用会优先显示本次运行期间缓存的最近一次成功结果。

Currency conversion uses the keyless Frankfurter API and the latest daily reference rates published by central banks. Rates are indicative rather than executable bank, card, or cash-exchange prices; if the network is unavailable, the app can fall back to the latest successful result cached during the current session.

## 许可证 / License

本仓库暂未提供开源许可证。代码可公开查看，但未授予复制、修改或分发权利。

No open-source license is currently granted. The code is publicly viewable, but permission to copy, modify, or distribute it is not provided.
