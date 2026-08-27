# Drinks JSON

One JSON object per recipe. M0 only loads the record and displays the reserved evening drink; M2 will add matching rules.

Required fields: `id`, `name`, `taste`, `alcohol`, `audience`, `unlock`, `ingredients`。

`ingredients` 是配方材料列表，当前用于晚上面板展示；完整的调酒小游戏后续在 M2 实现。
