# NEX-15: 多厂商 Payload 格式解析实施报告

**日期**: 2025-12-29  
**负责人**: Gemini Agent  
**状态**: 已完成 (Completed)

---

## 1. 背景与目标

### 1.1 问题陈述
LiteLog 原有的日志解析逻辑（`FormattedView`）与 OpenAI 的 API 格式强绑定。当用户使用 LiteLLM 网关访问 Google Gemini、Anthropic Claude 或 Amazon Bedrock 等非 OpenAI 模型时，由于这些厂商的 Request/Response JSON 结构差异巨大，导致 LiteLog 无法正确展示对话历史和工具调用详情，用户只能查看难以阅读的 Raw JSON。

### 1.2 目标
*   **支持多厂商格式**：实现对 Gemini 和 Claude 原生 API 格式的解析。
*   **统一展示体验**：将异构数据转换为统一的内部模型（`UnifiedPayload`），确保 UI 组件（对话气泡、工具卡片）对底层格式无感知。
*   **兼容 LiteLLM 特性**：处理 LiteLLM 网关特有的“Request 为上游格式，Response 为下游（OpenAI）格式”的混合日志结构。

---

## 2. 实施方案演进

### 2.1 初始设想
最初计划简单地修改现有的 `LogEntry` 和 `ChatMessage` 结构体，增加 `parts` (Gemini) 或 `content_blocks` (Claude) 字段。
*   **否定原因**：这会导致核心模型臃肿，且 UI 层需要编写大量 `if-else` 来处理不同字段，违背了开闭原则。

### 2.2 架构决策：防腐层 (Anti-Corruption Layer)
我们决定采用 **适配器模式 (Adapter Pattern)** 和 **策略模式 (Strategy Pattern)**。
*   **核心思想**：保持 `ChatMessage` 作为“标准内部模型”不变。引入 `PayloadParser` 协议，将外部脏数据“清洗”为内部标准数据。
*   **UI 零感知**：`FormattedView` 只接收 `UnifiedPayload`，完全不关心数据来源是 Google 还是 OpenAI。

---

## 3. 核心技术实现

### 3.1 统一模型 (Unified Models)
在 `Payload.swift` 中重构了基础模型，使其支持手动初始化，便于 Parser 构造数据。
*   `ChatMessage`: 统一了 Role (`user`/`assistant`/`tool`) 和 Content。
*   `ToolCall` / `ToolDefinition`: 统一了函数名、参数（JSON String）的表达。

### 3.2 解析器架构 (`PayloadParser.swift`)
我们实现了一个高度解耦的解析层：

1.  **`PayloadParser` Protocol**: 定义了 `parseRequest` 和 `parseResponse` 接口。
2.  **`PayloadParserFactory`**: 
    *   **双重检测机制**：首先检测 `provider` 字段（如 "google", "anthropic"）。如果 `provider` 字段模糊（如 "Amazon Bedrock"），则进一步检测 `model` 字段（如 "anthropic.claude-v2"）。
3.  **Concrete Parsers**:
    *   `OpenAIPayloadParser`: 处理标准及非标 OpenAI 格式。
    *   `GeminiPayloadParser`: 处理 Google API 的 `contents`/`parts` 结构。
    *   `ClaudePayloadParser`: 处理 Anthropic API 的 `content` 数组及 `tool_use` 块。

### 3.3 应对“现实世界的混乱” (The Real-World Mess)

在实施过程中，我们发现了大量不符合官方文档的“变体”格式（源于 LiteLLM 转换或上游 Agent 框架的不规范调用）。我们采取了**防御性编程**策略来逐一攻克：

#### 挑战 A：LiteLLM 的“双重人格”
*   **现象**：Request 是 Claude 原生格式，但 Response 却是 OpenAI 格式。
*   **对策**：`ClaudePayloadParser.parseResponse` 采用“回退策略”——先尝试用 OpenAI 解码器解析，成功则返回；失败则回退到 Claude 原生格式解析。

#### 挑战 B：Claude 的嵌套 `tool_result`
*   **现象**：Claude 的 `tool_result` 内容有时是字符串，有时是嵌套数组（`[{type: "text", text: "..."}]`），甚至导致 UI 显示 "Empty message"。
*   **对策**：引入 `ClaudeInnerContentWrapper`，自动识别 JSON 字段类型。如果是数组，递归提取所有 `text` 字段拼接成字符串。

#### 挑战 C：OpenAI 的“变体”格式 (Variant Formats)
*   **现象**：某些日志（可能来自 Azure 或 Bedrock Converse）Request 使用 `input` 而非 `messages`，Response 使用 `output` 而非 `choices`，且 Tool 定义是扁平化的。
*   **对策**：增强 `OpenAIPayloadParser`，定义 `VariantRequest` 和 `VariantResponse` 结构体。支持自动推断缺失的 `role`（如 `function_call` -> `assistant`），并兼容扁平化工具定义。

#### 挑战 D：UI 互斥显示 Bug
*   **现象**：当 Assistant 消息同时包含思维链（Content）和工具调用（Tool Calls）时，UI 只显示了 Content。
*   **对策**：修改 `MessageCard` 视图，将 `if-else` 互斥逻辑改为 `VStack` 顺序排列，确保两者能同时展示。

---

## 4. 关键代码片段

### 工厂模式 (Factory)
```swift
static func create(provider: String?, model: String?) -> PayloadParser {
    // 1. Try to detect by Provider
    if let provider = provider?.lowercased() { ... }
    
    // 2. Fallback: Detect by Model Name (解决 Provider 识别不准问题)
    if let model = model?.lowercased() {
        if model.contains("gemini") { return GeminiPayloadParser() }
        if model.contains("claude") { return ClaudePayloadParser() }
    }
    
    // 3. Default to OpenAI (and its variants)
    return OpenAIPayloadParser()
}
```

### 变体内容解析 (Variant Content Handling)
```swift
// 处理 content 既可能是 String 也可能是 Array 的情况
private struct VariantContentWrapper: Codable {
    let stringValue: String?
    let arrayValue: [VariantInnerContent]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            stringValue = str
            arrayValue = nil
        } else if let arr = try? container.decode([VariantInnerContent].self) {
            arrayValue = arr
            stringValue = nil
        } ...
    }
}
```

---

## 5. 总结与反思

### 5.1 成果
我们成功将一个原本只能解析标准 OpenAI 格式的系统，升级为一个**高鲁棒性的多模态日志解析器**。现在 LiteLog 能够优雅地展示：
*   标准的 OpenAI 调用。
*   Azure / Bedrock 等非标 OpenAI 变体。
*   Google Gemini 的 Function Call。
*   Anthropic Claude 的复杂 Tool Use 和思维链。

### 5.2 代码质量评估
*   **复杂度来源**：约 70% 的代码量用于处理边缘情况（Edge Cases）和兼容性逻辑。
*   **架构评价**：虽然代码量增加，但逻辑边界清晰。Parser 层的脏逻辑没有泄露到 UI 层，这是一次成功的重构。
*   **未来优化**：随着厂商增多，`PayloadParser.swift` 可能会变得过大，未来可考虑将每个 Parser 拆分为独立文件。

### 5.3 启示
在处理 LLM 日志时，**“宽容” (Lenience)** 是比“规范”更重要的品质。日志查看器的核心价值在于：无论上游 Agent 框架发出的请求多么不规范，只要模型能跑通，我们就应该尽力把它解析并呈现给用户。
