# emacs-config 项目规则

## 配置大纲:emacs-config.org 是唯一事实来源

- `emacs-config.org` 是配置大纲,`.el` 文件全部由它 tangle 生成(用户经 `C-c C-v C-t` 执行)。
- **所有改动必须优先改 `emacs-config.org` 里的 `#+begin_src` 代码块**,永不直接编辑 `core/*.el`、`.dir-locals.el` 等 tangle 产物 —— 用户下次 tangle 会把直接改动整个覆盖掉。
- 同步顺序:先改 org(代码块 + 必要的说明文字),再在 org 对应位置保持叙述一致;`.el` 与 org 不一致时以 org 为准。
- 改完 org 后提醒用户执行 `C-c C-v C-t` 重新 tangle,或用 `org-babel-tangle` 同步;不要自行 tangle 覆盖用户可能未保存的 buffer。

## 待办提醒(每次动配置时先看)

- **ETAF 全家桶升级未完成**(2026-11-28):上游已重组为 `packages/` 结构,但 recipe 没写 `:files`,
  直接升级会让 `straight/build/etaf/` 变空。另外 `straight/versions/default.el` 里
  `etaf`/`etaf-md` 记的是**本地 commit**(上游不存在),换机器 thaw 会失败。
  细节与升级清单:`dev-docs/notes/051-etaf-upgrade-todo.md`。
  **用户要求:涉及包更新/升级/straight 操作的对话里,主动提醒这件事。**
