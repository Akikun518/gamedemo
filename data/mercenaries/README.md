# Mercenaries JSON

One JSON object per hireable character. M0 ships exactly three initial mercenaries; later content can be added as new files without script changes.

Required fields: `id`, `name`, `role`, `star`, `stats`, `affection`, `price`, `personality`, `taboo`, `alive`, `unlock`, `likes`, `dislikes`.

接单规则：任务命中任意 `dislikes` 标签即拒绝；`likes` 非空时，任务至少要命中一个 `likes` 标签才会接。
