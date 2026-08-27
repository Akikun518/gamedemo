# Morning 面板布局修复

日期：2026-08-26

## 问题

委托列表和佣兵列表同时设置 `size_flags_vertical = 3`，两个列表都按内容撑满高度，把状态栏和“派遣所选佣兵 / 结束白天”按钮挤出 640×360 视口，导致按钮点不到。

## 根因

MorningPanel 是 VBoxContainer，两个内容列表都是可扩展且按内容计算最小高度；在小视口下，列表内容的高度超过了可用空间，底部固定高度的按钮被推到视口之外。

## 修复

- 把委托列表放进 `MissionScroll`，佣兵列表放进 `MercenaryScroll`。
- 两个 ScrollContainer 使用 `size_flags_vertical = 3` 分享剩余空间，并设置较小的 `custom_minimum_size`。
- 状态栏与两个按钮保持固定高度，不再被列表挤出去。
- 脚本节点引用改为 `$MissionScroll/MissionList` 与 `$MercenaryScroll/MercenaryList`。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

godot --headless --quit-after 5
（退出码 0，无工程脚本错误）
```

测试新增了布局断言：派遣按钮和结束白天按钮必须落在 Morning 面板和视口可见区域之内。
