---
name: iss-open-cli
description: 当 AI 智能体应用（如 Codex、Claude Code、Openclaw 等）需要帮助公网客户使用 iss-open-cli 二进制命令调用或排查闪送开放平台接口时使用本 skill，包括 orderCalculate 订单询价、orderPlace 提交订单、orderInfo 查询订单详情、abortOrder 取消订单、安装目录配置、CLI 入参 JSON 构造、响应解读和常见错误排查。
---

# 闪送开放平台 CLI

## 适用智能体

本 skill 面向通用 AI 智能体应用使用，包括但不限于Codex、Claude Code、Openclaw 以及其他支持读取 Markdown 指令和执行本地命令的 Agent。使用时不要依赖特定厂商能力；优先按本文件中的固定二进制路径、配置位置、命令格式和参考文档执行。

## 核心流程

1. 接口调用默认使用已安装二进制：`$HOME/.iss-open-cli/iss-open-cli`。
2. 默认配置文件放在 `$HOME/.iss-open-cli/configs/config.yaml`。CLI 会在当前工作目录或可执行文件同级目录查找 `configs/config.yaml`。
3. 用 `$HOME/.iss-open-cli/iss-open-cli --list` 查看当前支持的动作码。
4. 发起接口调用前，先阅读 [CLI 使用说明](references/cli-usage.md)。该文件包含配置、命令格式、示例和响应结构。
5. 构造或校验 `--data` JSON 时，阅读 [接口参考](references/api-reference.md)。

## 已支持动作码

- `orderCalculate`: 订单询价。需要城市、发件人、收件人信息；返回后续调用使用的 `orderNumber`。
- `orderPlace`: 提交订单。需要 `issOrderNo`，通常取自 `orderCalculate` 返回的 `orderNumber`。
- `orderInfo`: 查询订单详情。按平台文档传入 `issOrderNo` 和/或 `thirdOrderNo`。
- `abortOrder`: 取消订单。需要 `issOrderNo`。

## 调用方式

`--data` 使用紧凑 JSON。Shell 中优先用单引号包住 JSON，避免破坏内部双引号：

```bash
$HOME/.iss-open-cli/iss-open-cli --api orderInfo --data '{"issOrderNo":"TDH2026041300954053","thirdOrderNo":"OTK_2026041320001"}'
```

## 项目约定

- 配置来自 `configs/config.yaml` 或环境变量：`ISS_OPEN_API_URL`、`ISS_OPEN_AUTH_CLIENT_ID`、`ISS_OPEN_AUTH_SHOP_ID`、`ISS_OPEN_AUTH_APP_SECRET`、`ISS_OPEN_LOG_LEVEL`。
- 开放平台请求为 `POST application/x-www-form-urlencoded`，系统参数包含 `clientId`、`shopId`、`timestamp`、`sign`，业务参数为可选的紧凑 JSON 字符串 `data`。
- CLI 会自动生成系统参数和签名；客户只需要提供配置和 `--data` 业务 JSON。
- 客户端会解包平台响应 `{"status":200,"msg":...,"data":...}`；CLI 成功输出为 `{"status":200,"err":"","success":true,"data":...}`。
- 日志写入检测到的应用根目录下的 `logs/`。
