# 接口参考

主要内容来自闪送开放平台公网文档。需要精确可选字段、枚举或响应样例时，优先查看对应公网文档页面；本文件只保留 AI 智能体构造 CLI 参数时最常用的摘要。

公网文档来源：

- 订单计费：`https://open.ishansong.com/joinGuide/281`
- 提交订单：`https://open.ishansong.com/joinGuide/282`
- 查询订单详情：`https://open.ishansong.com/joinGuide/284`
- 订单取消：`https://open.ishansong.com/joinGuide/289`

## 签名与协议

来源：闪送开放平台接口协议及签名规则。

- 请求方式：`POST`
- 请求类型：`application/x-www-form-urlencoded`
- 系统参数：`clientId`、`shopId`、`timestamp`、`sign`
- 业务参数：`data`，接口需要业务入参时传 JSON 字符串
- 平台响应结构：`{"status": 状态码, "msg": 错误信息, "data": 数据}`；平台 `status == 200` 表示成功。
- CLI 使用的签名顺序：`appSecret + "clientId" + clientId + "data" + data + "shopId" + shopId + "timestamp" + timestamp`。`data` 为空时省略 `data` 及其值，最后计算 MD5 并转为大写。

正常使用 CLI 时无需手动计算签名。客户只需要维护配置文件和业务参数 JSON。

## orderCalculate 订单询价

来源文档：`https://open.ishansong.com/joinGuide/281`

- 平台路径：`/openapi/merchants/v5/orderCalculate`
- CLI 动作码：`orderCalculate`
- 必要业务字段：
  - `cityName`
  - `sender.fromAddress`
  - `sender.fromSenderName`
  - `sender.fromMobile`
  - `sender.fromLatitude`
  - `sender.fromLongitude`
  - `receiverList[].orderNo`
  - `receiverList[].toAddress`
  - `receiverList[].toLatitude`
  - `receiverList[].toLongitude`
  - `receiverList[].toReceiverName`
  - `receiverList[].toMobile`
- 当前 CLI 在调用平台前会设置 `appointType = 0`，并把第一个收件人的 `goodType = 10`、`weight = 1`。
- 关键响应字段：`orderNumber`，后续 `orderPlace`、`orderInfo`、`abortOrder` 使用它作为 `issOrderNo`。

## orderPlace 提交订单

来源文档：`https://open.ishansong.com/joinGuide/282`

- 平台路径：`/openapi/merchants/v5/orderPlace`
- CLI 动作码：`orderPlace`
- 必要业务字段：`issOrderNo`
- `issOrderNo` 来自订单询价返回的 `orderNumber`。

## orderInfo 查询订单详情

来源文档：`https://open.ishansong.com/joinGuide/284`

- 平台路径：`/openapi/merchants/v5/orderInfo`
- CLI 动作码：`orderInfo`
- 支持字段：
  - `issOrderNo`
  - `thirdOrderNo`
- 文档中 `issOrderNo` 表示闪送订单号，`thirdOrderNo` 表示第三方订单号，通常来自 `receiverList[].orderNo`。
- 常用响应字段：`orderStatus`、`orderStatusDesc`、`subOrderStatus`、`subOrderStatusDesc`、`courier`、`statusChangeLog`、`abortInfo`、费用字段。

订单状态枚举：

| status | 描述 |
| --- | --- |
| 20 | 派单中 |
| 30 | 待取货 |
| 40 | 闪送中 |
| 50 | 已完成 |
| 60 | 已取消 |

## abortOrder 取消订单

来源文档：`https://open.ishansong.com/joinGuide/289`

- 平台路径：`/openapi/merchants/v5/abortOrder`
- CLI 动作码：`abortOrder`
- 必要字段：`issOrderNo`
- 平台文档还提到可选字段 `deductFlag`；当前 CLI 主要按 `issOrderNo` 取消订单。取件后取消如涉及余额扣除确认，需以实际 CLI 支持能力和平台返回为准。
- 响应字段包含 `sendBackFee`、`deductAmount`、`abortType`、`punishType`、`abortReason`。

## 常用枚举

物品类型：

| 值 | 描述 |
| --- | --- |
| 1 | 文件 |
| 3 | 数码 |
| 5 | 蛋糕 |
| 6 | 餐饮 |
| 7 | 鲜花 |
| 9 | 汽配 |
| 10 | 其他 |
| 12 | 母婴 |
| 13 | 医药健康 |
| 15 | 商超 |
| 16 | 水果 |

费用类型示例：

| 值 | 描述 |
| --- | --- |
| 1 | 里程费 |
| 2 | 续重费 |
| 3 | 交通费 |
| 7 | 夜间费 |
| 9 | 加价费 |
| 15 | 保价费 |
| 24 | 增值服务费 |
| 108 | 尊享送服务费 |
