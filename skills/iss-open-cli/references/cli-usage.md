# CLI 使用说明

## 智能体执行原则

- 使用者可以是 Codex、Claude Code、Openclaw 或其他 AI Agent。
- 默认通过本地 shell 执行 `$HOME/.iss-open-cli/iss-open-cli`。
- 不要要求客户手动计算签名；CLI 会自动处理系统参数和签名。
- 涉及真实下单、取消订单或生产环境调用时，先确认客户意图、环境和关键业务参数。

## 安装路径与发现

- 真实接口调用默认使用二进制：`$HOME/.iss-open-cli/iss-open-cli`
- 默认配置文件：`$HOME/.iss-open-cli/configs/config.yaml`
- 查看支持的接口：`$HOME/.iss-open-cli/iss-open-cli --list`
- 查看单个接口示例：`$HOME/.iss-open-cli/iss-open-cli --api orderCalculate --example`
- 查看版本：`$HOME/.iss-open-cli/iss-open-cli --version`

公网客户直接使用安装目录下的二进制文件。

## 配置

安装后的默认配置文件：`$HOME/.iss-open-cli/configs/config.yaml`

```yaml
api:
  base_url: "http://open-astable.bingex.com"
  timeout: 3
auth:
  client_id: "..."
  app_secret: "..."
  shop_id: "..."
log:
  level: "info"
```

环境变量覆盖项：

- `ISS_OPEN_API_URL`
- `ISS_OPEN_AUTH_CLIENT_ID`
- `ISS_OPEN_AUTH_SHOP_ID`
- `ISS_OPEN_AUTH_APP_SECRET`
- `ISS_OPEN_LOG_LEVEL`

闪送开放平台文档列出的环境地址：

- 测试环境：`http://open.s.bingex.com`
- 生产环境：`https://open.ishansong.com`

调用时使用用户明确指定的环境和凭证。不要擅自切换测试或生产地址。

## 命令格式

```bash
$HOME/.iss-open-cli/iss-open-cli --api <action-code> --data '<compact-json>'
```

CLI 会校验 `--api` 是否存在、`--data` 是否为合法 JSON，然后读取配置、计算签名、提交 form 请求、解包平台 `data`，最后输出统一 JSON 响应。

成功响应：

```json
{"status":200,"err":"","success":true,"data":{...}}
```

失败响应：

```json
{"status":400,"err":"...","success":false,"data":null}
```

## 常用调用

订单询价：

```bash
$HOME/.iss-open-cli/iss-open-cli --api orderCalculate --data '{"cityName":"北京市","sender":{"fromAddress":"闪送总部","fromSenderName":"243001餐饮店","fromMobile":"19020243001","fromLatitude":"40.049058","fromLongitude":"116.379594"},"receiverList":[{"orderNo":"OTK_2026041320001","toAddress":"永泰庄 地铁站","toLatitude":"40.043612","toLongitude":"116.361199","toReceiverName":"收件专员","toMobile":"13800138001"}]}'
```

提交订单：

```bash
$HOME/.iss-open-cli/iss-open-cli --api orderPlace --data '{"issOrderNo":"TDH2026041300954053"}'
```

查询订单：

```bash
$HOME/.iss-open-cli/iss-open-cli --api orderInfo --data '{"issOrderNo":"TDH2026041300954053","thirdOrderNo":"OTK_2026041320001"}'
```

取消订单：

```bash
$HOME/.iss-open-cli/iss-open-cli --api abortOrder --data '{"issOrderNo":"TDH2026041300954053"}'
```

## 排查要点

- `未找到配置文件`：优先检查 `$HOME/.iss-open-cli/configs/config.yaml` 是否存在，或确认当前工作目录下是否存在 `configs/config.yaml`。
- `--data 参数不是合法的 JSON 格式`：先检查 shell 引号；建议用单引号包住 JSON。
- `平台返回失败`：查看 `logs/` 中的平台 `status` 和 `msg`；平台非 200 业务状态会被 CLI 转为 502 类应用错误。
- 超时或代理问题：检查配置中的 `api.timeout` 和可选 `api.proxy`。
