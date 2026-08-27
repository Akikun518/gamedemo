# Missions JSON

One JSON object per commission. Surface rank is public; true rank is resolver-only. Add files here for M1 instead of editing GDScript.

Required fields: `id`, `title`, `client`, `surface_rank`, `true_rank`, `required_roles`, `reward`, `base_days`, `unlock`, `on_success`, `on_failure`, `tags`, `time_limit_days`, `unlimited`.

结算规则：完成天数按难度与队伍星级计算；普通任务超过 `time_limit_days` 会逾期失败，`unlimited = true` 的主线任务不设截止日。
