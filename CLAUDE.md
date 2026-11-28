# emacs-config 项目规则

## 配置大纲:emacs-config.org 是唯一事实来源

- `emacs-config.org` 是配置大纲,`.el` 文件全部由它 tangle 生成(用户经 `C-c C-v C-t` 执行)。
- **所有改动必须优先改 `emacs-config.org` 里的 `#+begin_src` 代码块**,永不直接编辑 `core/*.el`、`.dir-locals.el` 等 tangle 产物 —— 用户下次 tangle 会把直接改动整个覆盖掉。
- 同步顺序:先改 org(代码块 + 必要的说明文字),再在 org 对应位置保持叙述一致;`.el` 与 org 不一致时以 org 为准。
- 改完 org 后提醒用户执行 `C-c C-v C-t` 重新 tangle,或用 `org-babel-tangle` 同步;不要自行 tangle 覆盖用户可能未保存的 buffer。

## 待办提醒(每次动配置时先看)

- **隐私：这个远端是 public 仓库**(`github.com/Dragonshock/emacs`)。凭据靠 `.gitignore`
  (`private.el`、`~/.authinfo`) 隔离，但任何提交都全世界可读。
  推送前检查器在 `scripts/git-hooks/pre-push`（拦截邮箱 / 疑似密钥 / `/Users/<name>` 路径）。
  **它是本地 hook，不进版本控制**，新 clone 后需重装：
  ```sh
  ln -sf ../../scripts/git-hooks/pre-push .git/hooks/pre-push
  ```
  已知历史残留：`/Users/dragon` 曾写在 `scripts/test-init-*` 的注释里，已在 2a8e7f2 修复，
  但更早的 commit(`86a07da` 及之前)仍含它；该信息价值低(仅 macOS 用户名)，未改写历史。

- **ETAF 全家桶升级未完成**(2026-11-28):上游已重组为 `packages/` 结构,但 recipe 没写 `:files`,
  直接升级会让 `straight/build/etaf/` 变空。另外 `straight/versions/default.el` 里
  `etaf`/`etaf-md` 记的是**本地 commit**(上游不存在),换机器 thaw 会失败。
  细节与升级清单:`dev-docs/notes/051-etaf-upgrade-todo.md`。
  **用户要求:涉及包更新/升级/straight 操作的对话里,主动提醒这件事。**

## 本地密钥与凭据(排查备忘)

- **GPG 加密子键会单独过期**(2026-11-28 续期过一次)。症状很有迷惑性:
  `gpg -e` 报 `Unusable public key` / Emacs 报 `epg-error "no usable configuration"`,
  但**解密一直正常**—— 因为主密钥只负责签名(`[SC]`),加密靠子键(`[e]`),两者到期日不同。
  检查:`gpg --list-keys --with-colons <fpr> | awk -F: '$1=="pub"||$1=="sub"'`
  续期(需**完整 40 位指纹**,给 keyid 会报 "is not a fingerprint"):
  ```sh
  gpg --quick-set-expire <primary-fpr> 2y <subkey-fpr>
  ```
  当前到期:主键 2028-07-27 / 加密子键 2028-11-27。

- **凭据文件分工**:`~/.authinfo`(明文,权限 600)只放非关键的 apikey;
  `~/.authinfo.gpg` 放邮件等敏感项(imap/smtp)。`auth-sources` 顺序是明文优先,
  所以明文里删掉某项后会回退到 gpg 找。需要重新加密 gpg 时,先确认加密子键未过期(见上)。

- **`exec-path` 里的 Homebrew**:见 `init-emacs-core` 的 `exec-path-from-shell` 块。
  GUI Emacs 拿到的是极简 PATH,而该包跑 shell 时无参数、登录文件不加载,所以 Homebrew 缺失。
  `gpg`/`pinentry` 只装在 Homebrew,不补 PATH 就会让所有 `.authinfo.gpg` 查询静默失败。
