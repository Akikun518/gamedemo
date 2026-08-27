# 验证记录

日期：2026-08-26

## 变更内容

- 任务改为延时结算，第二天早晨弹结果，之后回委托板。
- 佣兵按 `likes` / `dislikes` 接单，界面显示好感度并隐藏信用点。
- 任务新增 `time_limit_days` / `unlimited`，支持逾期失败与主线不限时。
- 酒新增 `ingredients` 配方字段，晚上面板展示材料。
- EventBus 5 个信号已接到 MainView / GameState 实际使用点。

## 命令与结果

### 结构校验

```text
$ python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 7
- folders: data / scenes / scripts / assets / tests
- no content IDs hard-coded in scripts
```

### 运行时验收

```text
$ godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED
```

### 主场景启动检查

```text
$ godot --headless --quit-after 5
（退出码 0，无工程脚本错误）
```

说明：本机 Godot headless 会额外打印 `Failed to read the root certificate store`，这是 Godot/系统证书环境提示，不是项目脚本错误。

## 测试覆盖

- 佣兵命中讨厌标签时拒绝任务。
- 佣兵 `likes` 非空且无命中标签时拒绝任务。
- 完成天数超过截止日时结算为逾期失败，且结算日落在截止日。
- Day 1 派遣后任务进入队列、不弹结果、保持 Morning。
- Day 2 早晨先进入 Result，关闭后回到 Morning 委托板。
- Morning 面板渲染任务列表与“结束白天”按钮。
