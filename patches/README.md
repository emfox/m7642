# patches/

`git format-patch` 的落点。规则：

- **一个补丁一件事**，主题行写 `subsystem: 做了什么`（`usb: add mstar ehci glue`）。
- DTS 与驱动分开；绑定文档（`Documentation/devicetree/bindings/`）与 DTS 同一个补丁。
- 提交前过 `scripts/checkpatch.pl --strict`，并在真实 `-next` 基线上验证过 `make dt_binding_check`。
- 序列用 `git format-patch --cover-letter <base>` 生成，cover letter 里写清楚：
  测过什么硬件、哪几项功能验证过、哪些是已知缺口。

当前还没有可提交的代码补丁——先有 `Documentation/` 与 DTS。

生成方式：

```sh
git format-patch --cover-letter -o patches/ master..m7642/port
```
