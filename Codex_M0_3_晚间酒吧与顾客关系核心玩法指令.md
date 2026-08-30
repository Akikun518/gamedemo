# Cyberpunk Fixer
# Codex M0.3：晚间酒吧与顾客关系核心玩法指令

> 本指令用于在当前 Prototype 基础上继续开发。
>
> 本阶段目标不是增加大量 NPC 或大量对白，而是把夜晚酒吧真正做成：
>
> **服务 → 调酒 → 普通交流 → 判断人物 → 深入交流 → 情报交易 / 情报交换 → 关系变化 → 人物记忆 → 情报进入第二天白天**
>
> 夜晚应该成为本项目核心玩法的一半，而不是独立的“调酒小游戏”。

---

# 0. 执行前必须做的事情

不要立即修改代码。

先完整阅读当前项目：

- README.md
- AGENTS.md（如果存在）
- docs/
- 当前 Prototype 开发文档
- scripts/
- data/
- scenes/
- tests/
- project.godot
- 当前 Git 状态和最近提交

然后输出：

1. 当前夜晚系统已经实现什么。
2. 当前 `serve_drink` 已经实现什么。
3. 当前 Guest / Customer 系统是否存在。
4. 当前 Dialogue 系统是否存在。
5. 当前 Intel 系统如何保存。
6. 当前 GameState 如何保存关系和状态。
7. 当前系统与本 M0.3 要求之间的差距。
8. 准备修改的文件。
9. 实施顺序。
10. 可能的兼容性风险。

确认后再开始修改。

**不要推倒现有架构。**

优先复用已有：

- GameState
- BartendingSystem
- DialogueSystem
- IntelSystem
- FactionSystem
- SaveSystem
- Evening UI

---

# 1. 本阶段最高优先级

夜晚不能再只是：

```text
选择顾客
→ 调酒
→ 获得信息
```

必须变成：

```text
顾客进入
→ 正常接待
→ 顾客点酒
→ 调酒
→ 普通交流
→ 玩家观察人物
→ 判断是否值得深入
→ 消耗精力
→ 深入交流
→ 情报 / 世界观 / 交易 / 关系
→ 记录人物状态与玩家行为
```

---

# 2. 所有顾客都可以正常接待

不要设计：

> “今晚只能挑 4 个顾客。”

不要使用：

> 服务次数。

不要让“精力耗尽”导致夜晚立即结束。

正确逻辑：

```text
所有出现的顾客
↓
都可以正常服务
↓
普通服务不消耗精力
```

精力只限制：

> **深度交流和复杂社交行为。**

这样符合酒吧世界观。

---

# 3. 夜晚客流

Prototype 建议：

```text
每晚 6～8 名顾客
```

客流数量必须配置化。

不要把数量写死在 evening_panel。

未来可以由：

- 酒吧等级
- 日期
- 势力状态
- 剧情
- 城市事件

影响客流。

---

# 4. 夜晚结束

夜晚在：

> 当晚预设客流全部处理完 / 酒吧打烊

时结束。

不要：

- 精力归零自动结束。
- 现实时间倒计时。
- 服务次数归零结束。

精力为 0：

```text
仍然可以：
- 调酒
- 收钱
- 普通聊天
- 观察顾客
```

但：

```text
DeepTalk = Disabled
IntelTrade = 根据设计决定是否允许
```

深度交流必须受精力限制。

---

# 5. 精力系统

初始：

```text MaxStamina = 4
```

精力代表：

> 主角当晚处理复杂人际关系、谈判和情报的注意力。

不是纯粹体力。

---

# 6. 精力消耗

默认：

```text
普通居民 = 1
普通佣兵 = 1
普通公司员工 = 2
普通帮派成员 = 2
高级人物 = 3
特殊剧情人物 = 3
```

所有成本必须配置化：

```text social_class.interaction_cost
```

不要在代码中到处出现：

```text stamina -= 1
stamina -= 2
```

---

# 7. 电子脑与精力

正式上限：

```text 基础 4
电子脑 I +1 → 5
电子脑 II +1 → 6
```

最大：

```text 6
```

不允许电子脑继续：

```text III → 7
IV → 8
```

Prototype 只需要预留接口。

---

# 8. 普通接待

流程：

```text
GuestEnter
→ OrderDrink
→ ServeDrink
→ DrinkReaction
→ CasualDialogue
```

普通接待：

- 不消耗精力。
- 可提供基础信息。
- 可表现客人情绪。
- 可表现世界观。
- 可表现人物性格。
- 不应直接交付全部关键情报。

---

# 9. 顾客主动点酒

顾客可以主动指定：

```text Martini
Negroni
Highball
...
```

如果已解锁：

- 正常调酒。
- 可触发 Perfect。
- 更容易进入深层互动。

如果未解锁：

不要单纯：

```text 未解锁
```

允许玩家用其他已解锁酒替代。

但：

> 指定酒未解锁时，不应轻易获得该人物完整深层互动。

酒类解锁因此成为：

> **某类人际圈 / 情报圈的进入钥匙。**

---

# 10. 调酒结果

必须至少支持：

```text Perfect
Acceptable
Wrong
```

不要变成：

```text correct = intel
wrong = no intel
```

正确设计：

## Perfect

- 好感上升。
- 更高质量对话。
- 更深互动概率提高。
- 情报质量提高。
- 交易机会增加。

## Acceptable

- 正常聊天。
- 普通关系变化。
- 普通情报。

## Wrong

- 顾客不满。
- 好感可能下降。
- 可能只提供模糊信息。

但是：

> Wrong 不代表一定没有信息。

某些人物可能因为：

- 烦躁
- 醉意
- 情绪失控

反而泄露一条特殊消息。

---

# 11. 酒匹配必须标签化

不要：

```text
drink_id == favorite_drink_id
```

优先使用：

```text
taste
alcohol
audience
ingredients
style
```

返回：

```text perfect
acceptable
wrong
```

新增酒不应该要求修改 DialogueSystem。

---

# 12. 深入交流

每名顾客可以拥有：

```text DeepTalk
```

但必须：

```text stamina >= interaction_cost
```

点击：

```text 消耗精力
→ 播放深层对话
→ 根据人物状态决定结果
```

可能结果：

- Intel
- WorldLore
- Relationship
- Flag
- Contract
- Recruit
- IntelTrade
- IntelExchange
- PersonalEvent

非常重要：

```text DeepTalk
≠ Guaranteed Intel
```

不是每个人都有值钱的信息。

---

# 13. 情报系统升级

情报必须变成真正的库存物品：

```text GameState.intel_inventory
```

每条 Intel 至少：

```text id
content
source
reliability
related_mission
related_faction
value
expiration
status
```

状态：

```text Active
Used
Expired
False
Corrected
```

---

# 14. 情报可信度

不要告诉玩家：

```text 此人可信
此人不可信
```

玩家自己判断。

可靠度可以显示：

```text ★
★★
★★★
★★★★
★★★★★
```

但：

> 星级不是绝对真相。

高地位的人也能撒谎。

低地位的人也可能说真话。

---

# 15. 情报的来源非常重要

例如：

```text 公司经理
★★★★☆

公司基层员工
★★★★

资深佣兵
★★★★

街头混混
★★★

陌生人
★★

醉酒客
★～★★
```

但是来源只是参考。

历史行为、关系和利益冲突也必须影响玩家判断。

---

# 16. 情报交易

深入交流阶段可以：

```text Buy Intel
Sell Intel
Exchange Intel
```

---

## Buy Intel

顾客提出：

> “我有条消息，你要吗？”

玩家支付信用点。

获得：

```text Intel
```

---

## Sell Intel

玩家从库存选择情报。

顾客：

```text Accept
Reject
CounterOffer
```

---

## Exchange Intel

玩家：

> 提供 Intel A

顾客：

> 提供 Intel B

玩家决定：

> 是否值得交换。

这时：

> 情报本身就是资源。

---

# 17. 情报对玩家也可能有价值

禁止简单：

> 所有 Intel 都可以卖。

玩家必须考虑：

```text 我卖掉这条 Intel

以后自己还能不能用？
```

因此交易必须考虑：

- 当前任务
- 即将发生的任务
- 情报有效期
- 相关势力
- 玩家信誉
- 潜在剧情

---

# 18. 客人也可能向玩家索取情报

例如：

> “你知道最近港口谁在接货吗？”

玩家：

```text 没有
有
有，但不卖
有，换东西
```

于是出现：

> **玩家自己的信息网络。**

---

# 19. 顾客不是固定任务 NPC

不要让：

```text 公司员工出现
→ 必定提供公司情报
```

这种逻辑。

顾客首先是：

> **生活在城市里的人。**

某天他可能只是：

```text Drink
```

另一天：

```text Social
```

再另一天：

```text Intel
```

之后：

```text Trade
```

或者：

```text Problem
```

---

# 20. Guest Intent

每次来店可以有：

```text Drink
Social
Intel
Trade
Contract
Recruit
Rumor
Problem
Story
Spy
```

同一个 NPC：

```text Day 1 → Drink
Day 4 → Social
Day 7 → Intel
Day 10 → Trade
```

人物没换。

但：

> 本次来店目的不同。

---

# 21. 顾客关系阶段

不要只依赖：

```text Affection 0～100
```

增加：

```text RelationshipStage
```

建议：

```text 0 Stranger
1 Acquaintance
2 Familiar
3 Trusted
4 BusinessPartner
5 StoryCharacter
```

---

# 22. 每 20% 好感度的设计

可以使用：

```text 20
40
60
80
100
```

作为关系里程碑。

但是：

> **不要让玩家看到“好感 40% = 解锁对白”。**

不要做成 RPG 好感度攻略表。

应该表现为：

```text RelationshipStage changed
→ 新话题出现
→ 新情报出现
→ 新交易出现
→ 新人物秘密出现
→ 新事件出现
```

即：

> 每 20% 是“关系里程碑”，不是“刷条奖励”。

---

# 23. 重要 NPC 的秘密层级

每个关系型 NPC 应该至少拥有：

```text PersonalInfo
Past
Beliefs
Secret
CurrentProblem
RelationshipWithFactions
```

关系逐渐提高：

### 20

基本个人信息。

### 40

过去经历 / 立场线索。

### 60

个人秘密。

### 80

独家信息 / 重要关系。

### 100

特殊事件 / 人物剧情。

具体结构必须数据驱动。

---

# 24. 玩家为什么想再次聊天

目标不是：

> “为了刷满好感。”

而是：

> **玩家知道这个人还有东西没说。**

例如：

第一次：

> “最近公司加班挺严重。”

第四次：

> “其实不是加班，他们在查东西。”

第六次：

> “‘夜莺项目’你听说过吗？”

第八次：

> “算了，这事跟你没关系。”

玩家应该产生：

> “这人到底知道什么？”

---

# 25. 顾客记忆

增加：

```text guestMemory[]
```

NPC 可以记住：

- 玩家调错过的酒。
- 玩家调对过的酒。
- 玩家卖过的情报。
- 玩家拒绝过的交易。
- 玩家撒过的谎。
- 玩家帮助过的势力。
- 玩家造成的任务伤亡。
- 玩家过去的行为。

---

# 26. 记忆不能只用 Affection 表现

例如：

玩家调错酒：

```text memory:
"player_served_bad_drink"
```

玩家卖过假情报：

```text memory:
"player_sold_false_intel"
```

玩家成功完成任务：

```text memory:
"player_completed_job_for_faction_x"
```

这些 Memory 可以改变：

- 对话。
- 客人态度。
- 情报可信度。
- 交易条件。
- GuestIntent。
- RelationshipStage。

---

# 27. 顾客信息库存

重要 NPC 建立：

```text knownIntelPool
```

例如：

```text Intel_A
Intel_B
Intel_C
```

第一次访问：

> 获得 A。

第二次：

> 获得 B。

第三次：

> 可以用钱 / 情报交换 C。

处理完关键情报后：

> 进入下一关系阶段。

这样重复访问的意义是：

> **逐步挖掘一个人的信息网络。**

---

# 28. 顾客的生活线

重要 NPC 可拥有：

```text personalGoal
workState
currentProblem
secret
lifeState
```

状态可以随天数变化。

例如：

```text 公司员工
↓
工作异常
↓
被调查
↓
离职
↓
成为独立情报商
```

角色状态变化可以改变：

- 社会地位。
- 精力成本。
- 酒类偏好。
- 情报来源。
- 势力关系。
- 可交易信息。

M0.3 可先实现简单状态，不必做复杂模拟。

---

# 29. 顾客社会地位

建议保留：

```text Civilian
Mercenary
GangMember
CorporateEmployee
HighStatus
Special
```

社会地位决定：

```text DeepTalkCost
```

而不是决定“是不是重要 NPC”。

普通居民也可以藏着重要秘密。

高级公司员工也可能只是来喝酒。

---

# 30. NPC 数量控制

不要为了解决重复问题无限增加 NPC。

Prototype 推荐：

### 普通顾客

10～15

### 关系型顾客

5～8

### 核心剧情人物

3～5

先做少量高质量角色。

---

# 31. 关系型顾客的 M0.3 验证规模

不要一开始制作 8 个关系型 NPC 的完整剧情。

先完成：

> 3 个关系型顾客。

每人：

```text 2～3 个关系阶段
2～3 个 GuestIntent
3～5 条重要 Intel
至少 2 条 Memory
至少 1 个特殊事件
```

验证循环成功后再扩。

---

# 32. 酒类 Prototype

仍然使用：

```text Highball
Old Fashioned
Margarita
Martini
Negroni
```

酒的价值不是：

> 多一个经营数值。

而是：

> **打开不同客群、人际圈和情报入口。**

例如：

```text Highball
→ 普通居民 / 普通佣兵

Margarita
→ 年轻佣兵 / 街头客

Martini
→ 公司人员

Negroni
→ 老 Fixer / 高级客人
```

这些只是方向示例。

不要硬编码“某酒只能对应某职业”。

---

# 33. 数据结构

建议：

```text
data/guests/*.json
data/drinks/*.json
data/dialogues/**/*.json
data/intel/*.json
```

Guest：

```text
id
name
social_class
interaction_cost
favorite_tags
disliked_tags
relationship_stage
affection
visit_count
intent_pool
memory
known_intel_pool
personal_goal
current_problem
flags
```

---

# 34. Dialogue 最小 Schema

```text
guest_id
conditions
opening
drink_reactions
branches
effects
```

条件至少：

```text
min_day
relationship_min
required_intel
required_flags
visit_count
guest_intent
faction_state
```

不要做复杂 DSL。

---

# 35. serve_drink 接口

使用：

```text
serve_drink(guest_id, drink_id)
```

返回：

```json
{
  "reaction_tier": "perfect",
  "relationship_delta": 2,
  "dialogue_id": "guest_x_perfect_01",
  "intel_candidates": [],
  "trade_available": true
}
```

不要只返回：

```text
ok
message
```

---

# 36. 夜晚与白天连接

夜晚获得的 Intel：

必须进入：

```text GameState.intel_inventory
```

第二天打开任务平板：

相关委托显示：

```text NEW INTEL
```

情报至少可以影响：

```text MissionRank
Risk
Reward
Duration
RequiredSkill
HiddenCondition
```

---

# 37. 最重要的昼夜闭环

```text
白天
接受委托
↓
调查
↓
信息不足
↓
决定晚上找谁
↓
晚上
接待所有人
↓
调酒
↓
深入交流
↓
买 / 换 / 卖情报
↓
判断情报可信度
↓
第二天
重新评估委托
↓
调整任务等级
↓
重新定价
↓
选择佣兵
↓
派遣
```

必须至少有一个任务完整测试这个链条。

---

# 38. 失败与顾客反应

如果玩家任务失败：

晚上顾客可以对此做出反应。

例如：

> “听说昨天有人没回来。”

关系型 NPC 可能：

- 安慰。
- 质疑。
- 嘲讽。
- 提供情报。
- 趁机抬高交易价格。
- 开始不信任玩家。

但是：

> 不要让所有 NPC 都知道所有事情。

信息传播必须通过：

```text faction
social_network
information_source
```

简单实现即可。

---

# 39. 玩家过去行为必须影响未来夜晚

例如：

玩家赔偿死亡佣兵：

→ 佣兵圈对玩家评价上升。

玩家不赔：

→ 某些佣兵降低关系。

玩家帮助某公司：

→ 公司员工更愿意接近。

玩家连续失败：

→ 酒吧客人议论。

这让夜晚成为：

> **玩家行为的回音室。**

---

# 40. Debug

必须增加：

```text Set Stamina
Add Stamina
Reveal Guest Intent
Reveal RelationshipStage
Reveal Guest Memory
Reveal Guest Intel
Give Intel
Remove Intel
Force Drink Result
Force Guest Visit
Set Guest Relationship
Set Guest Intent
Set Guest SocialClass
Trigger Guest Event
```

正式 UI 不显示。

---

# 41. 自动测试

至少测试：

```text 普通接待不消耗精力

DeepTalk 消耗正确精力

Civilian = 1

Mercenary = 1

Corporate = 2

Gang = 2

HighStatus = 3

Stamina=0 时不能 DeepTalk

Stamina=0 时仍可以正常接待

电子脑 I：4 → 5

电子脑 II：5 → 6

Stamina 不超过 6

Perfect / Acceptable / Wrong 正常分流

未解锁指定酒可以使用替代品

正确酒更容易进入深层互动

Intel 正确进入库存

Intel 可以购买

Intel 可以出售

Intel 可以交换

False Intel 可以记录

Corrected Intel 可以记录

RelationshipStage 可以变化

20/40/60/80/100 可以触发不同关系里程碑

Guest Memory 可以保存

GuestIntent 可以改变

Guest 可以重复出现

重复出现时不重复使用完全相同的关键内容

客人过去记忆能影响下一次互动

夜晚 Intel 能保存到第二天

Intel 能影响 Mission
```

---

# 42. 严格禁止

M0.3 暂时不要加入：

- 厨房。
- 酒水采购。
- 酒水库存经营。
- 座位管理。
- 服务员路径 AI。
- 客人实时行为模拟。
- 实时倒计时酒吧经营。
- 装修编辑器。
- 大型社交网络 UI。
- 复杂天气系统。
- 大量 NPC。

本阶段只有：

> **酒 + 人 + 情报。**

---

# 43. 开发顺序

## Phase A
serve_drink：

```text Perfect / Acceptable / Wrong
```

## Phase B
Guest：

```text Relationship
VisitCount
Memory
Intent
SocialClass
```

## Phase C

```text DeepTalk
Stamina
SocialClassCost
```

## Phase D

```text IntelInventory
BuyIntel
SellIntel
ExchangeIntel
Reliability
```

## Phase E

```text DialoguePlayer
DialogueData
Conditions
Branches
Effects
```

## Phase F

```text GuestIntent
GuestState
GuestMemory
```

## Phase G

```text Night Intel
→ Next Day Mission
```

## Phase H

制作 3 个完整关系型 NPC。

只有完成这 3 个 NPC 并经过实际试玩后，才决定是否扩到 5～8 个关系型 NPC。

---

# 44. 文档维护

每完成一个 Phase：

必须同步更新：

```text README.md
docs/
Prototype Design Document
docs/DEVELOPMENT_LOG.md
```

记录：

```text Version
Date
Completed
Changed Files
New Systems
Tests
Known Issues
Next Step
```

不能出现：

> 文档写“已完成”，代码实际没有。

也不能：

> 代码已经完成，文档还是旧版本。

---

# 45. GitHub 强制同步

每个 Phase：

```text
代码
→ 测试
→ 文档
→ README
→ git diff
→ git status
→ commit
→ push
```

GitHub：

```text
https://github.com/Akikun518/gamedemo
```

每个独立功能必须有独立 commit。

示例：

```text
feat: add guest deep talk system
feat: add intel trading
feat: add guest memory
feat: add stamina interaction cost

test: add evening interaction tests

docs: update M0.3 development status
```

只有实际：

```text
git push
```

成功以后，才能报告：

> 已同步到 GitHub。

---

# 46. 最终验收

M0.3 不以“系统数量”判断完成。

必须能让玩家自然产生：

> “所有客人都可以服务。”

> “但我只有 4 点精力。”

> “这个公司员工值得我花 2 点。”

> “他点的 Martini 我刚好有。”

> “这杯酒让他明显愿意多聊一些。”

> “他给我的这条信息是真的吗？”

> “他愿意用自己的情报换我的港口情报。”

> “这条消息可能对明天的任务有用，我不能随便卖掉。”

然后第二天：

> “昨晚那个公司员工说的话，让我重新判断了这份委托。”

如果玩家能自然经历：

```text
服务
→ 调酒
→ 交流
→ 深入
→ 情报
→ 交易
→ 判断
→ 第二天任务
```

M0.3 达到目标。

---

# 47. 最重要的设计原则

不要让玩家为了：

> “刷满 NPC 好感度”

而去聊天。

让玩家为了：

> **“我想知道这个人到底是什么样的人，以及他到底知道什么。”**

而去聊天。

不要让重复顾客只是：

> “同一个 NPC 再播一遍新对白。”

要做到：

> **同一个人再次出现时，他的状态、目的、记忆、关系、情报库存、生活状况至少有一部分发生变化。**

不要追求：

> 每次都有新文本。

追求：

> **每次都有新的可能性。**

---

# 48. M0.3 核心宣言

> **白天，玩家判断事情。**
>
> **晚上，玩家判断人。**
>
> **酒决定别人愿不愿意向玩家开口。**
>
> **精力决定玩家能真正聊透多少人。**
>
> **关系和记忆决定一个人以后还愿不愿意相信玩家。**
>
> **情报决定第二天玩家敢不敢把人派出去。**

这就是本阶段必须实现的核心体验。
