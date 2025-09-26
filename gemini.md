## 技术实现文档：macOS LiteLLM 日志查看器 "LiteLog" (V1.0)

### 1. 项目概述

**项目名称**: LiteLog

**目标**: 一款基于 Xcode 和 SwiftUI 构建的原生 macOS 应用程序，用于连接到用户的 LiteLLM 代理实例，方便地查看和管理通过不同 API Key 生成的请求日志。

**核心价值**: 提供一个比 Web UI 或命令行更流畅、更集成、更高效的日志监控体验，专注于 API Key 管理和日志审查。

### 2. 核心功能 (V1.0)

- **设置配置**: 用户可以在应用的设置界面中配置 LiteLLM 实例的 **Base URL** 和 **Admin API Key**。
    - 新增日志选项：可配置「回溯时长（小时）」与「分页条数（Page Size）」，用于控制查询窗口与每次加载数量（默认 24 小时 / 50 条）。
- **凭证存储**: Admin API Key 和 Base URL 都使用 `UserDefaults` 进行存储。移除了原定用于增强安全性的 `Keychain` 方案，以简化实现。
- **主窗口大小持久化**: 应用会记住用户上次调整的主窗口大小，并在下次启动时恢复。
- **虚拟 Key 列表**: 
    - 应用启动后，自动使用已配置的 Base URL 和 Admin Key 从 `/key/list` 接口获取所有虚拟 API Key。
    - 在左侧边栏中展示虚拟 Key 列表。每项会显示其别名 (`key_alias`)，如果别名不存在，则会显示其 `key_name` 作为备用。
- **日志缓存**: 当切换 API Key 时，应用会缓存已加载的日志，避免重复请求。只有在手动刷新或应用重置时才会重新从 API 获取日志。
- **日志分页**:
    - 中栏底部提供「Load Older」悬浮按钮，用于加载更早一段时间窗口内的日志（窗口跨度等于回溯时长）。
    - 分页为增量加载，不会打断当前滚动位置；加载中有内联小菊花提示。
    - 当内容不足一屏时，不高亮「Load Older」。
    - 顶部提供「Back to Latest」悬浮按钮，仅滚动回列表顶部，不触发刷新或重置时间窗口。
- **UI 优化 (V1.0 新增)**:
    - **现代化界面**: 采用 Linear 风格的深色主题设计，提升视觉体验。
    - **交互改进**: 所有列表项卡片支持全区域点击，不再局限于文本区域。
    - **视觉反馈**: 添加悬停效果、选中状态高亮、按钮动画等交互细节。
    - **组件统一**: 通过设计系统确保全应用的视觉一致性。
    - **悬浮控件**: 顶部/底部悬浮按钮（Back to Latest / Load Older），根据滚动位置自动显示与高亮。
- **日志详情视图增强**:
    - 在右侧「详情视图」面板中引入了日志载荷（请求/响应）的标签页视图，允许用户在「Formatted」（格式化）和「JSON」表示之间切换。
    - **「JSON」视图**: 显示美观的 JSON 格式数据，并提供一键复制到剪贴板功能。
    - **「Formatted」视图**: 智能解析请求和响应载荷，提供一个结构化的视图。
        - **工具定义卡片**: 当请求中包含工具定义时，这些工具会显示在视图顶部一个专属的“Tools”区域。每个工具都以一个可折叠的卡片形式展示，详细说明其功能描述和参数。如果该工具在最终响应中被调用，则会显示“CALLED”徽章。
        - **消息流**: 在工具区域下方，以聊天气泡形式展示消息流，按角色（System, User, Assistant）分组，每条消息都带有复制到剪贴板功能。当 Assistant 消息内容为空但包含工具调用时，Formatted 视图会清晰地展示这些工具调用信息。

- **状态持久化**: 应用通过 `UserDefaults` 记住用户上次选择的虚拟 Key，在下次启动时自动选中并加载其日志。
    - 额外持久化：回溯时长（`LiteLogLookbackHours`）与分页条数（`LiteLogPageSize`）。
- **基础交互**:
    - 提供两种手动刷新机制：
        - **刷新日志**: 主工具栏的刷新按钮，仅重新加载当前选中 Key 的日志。
        - **刷新 API Keys**: 左侧边栏的刷新按钮，用于重新加载整个 Key 列表（此操作也会附带刷新当前 Key 的日志）。
    - 在数据加载期间显示加载指示器 (Spinner)。
    - 在列表为空时显示明确的“暂无数据”或“未找到 API Key”等提示。
- **设置自动刷新**: 在设置界面保存配置后，主界面会自动刷新数据，无需手动重启应用。
- **API 兼容性**: 
    - 对 API 返回空数据的情况做了兼容处理，当服务器返回 200 OK 但响应体为空时，应用会视作空列表而不是解析失败。
    - 对 API 返回数据中 `key_alias` 为 `null` 的情况做了兼容。

### 3. 用户界面 (UI) 与用户体验 (UX)

- **设计系统 (V1.0)**: 
    - **设计风格**: 采用类 Linear 的现代化设计语言，深色主题，精简美观。
    - **颜色系统**: 基于 Linear 的配色方案，主色调为蓝色 (`rgb(61, 130, 255)`)，背景色采用深蓝黑渐变 (`rgb(5, 5, 10)` 到 `rgb(20, 23, 33)`)。
    - **组件样式**: 统一的卡片式设计，圆角为 6px，具有悬停效果和选中状态的视觉反馈。
    - **交互优化**: 所有卡片区域均支持全区域点击，提升用户体验。
    - **无边框窗口**: 采用透明标题栏设计 (`.windowStyle(.hiddenTitleBar)`)，移除了系统默认的窗口标题栏，使自定义的深色背景能延伸至整个窗口，提供更具沉浸感的现代视觉体验。

- **主窗口布局**: 采用经典的 `NavigationSplitView` 实现三栏式布局，**列宽不持久化**：
    - **左栏 (Sidebar)**: 显示虚拟 Key 列表，采用卡片式设计。每个 API Key 卡片显示名称/别名和消费金额，当前选中的 Key 有蓝色高亮边框和背景。在侧边栏顶部显示"API Keys"标题和计数，底部提供设置按钮。整个卡片区域可点击选择。
    - **中栏 (Content List)**: 显示所选 Key 的日志条目列表，采用现代化卡片设计。每条日志卡片显示状态徽章、模型名称、时间戳、耗时、消费和 Token 数量。卡片具有悬停效果，整个区域可点击。顶部显示"Logs"标题和日志计数。该栏的最小宽度为 450px，理想宽度为 500px。
        - 底部悬浮「Load Older」按钮：到达底部时高亮提示，内容不足一屏不高亮；点击后增量加载更早时间段日志。
        - 顶部悬浮「Back to Latest」按钮：离开顶部时显示，回到顶部自动隐藏；点击仅滚动，不触发网络刷新。
    - **右栏 (Detail View)**: 显示所选日志的详细信息，采用卡片分组布局。包含日志概览、详细信息和载荷数据三个卡片区域。其中详细信息区域会展示 Provider 和 API Base（仅域名）等。**载荷数据区域现在支持「Formatted」和「JSON」两种视图切换，其中「JSON」视图显示格式化后的 JSON 文本并提供复制功能，「Formatted」视图则以更智能的形式展示载荷：它会首先渲染一个包含所有已定义工具的可折叠“Tools”区域，然后在其下方以聊天气泡形式展示消息流，并能处理 Assistant 消息中内容为空但包含工具调用的情况。**当未选中日志时显示居中的提示文本。

- **设置界面**:
    - 采用现代化表单设计，使用自定义的 `LinearTextFieldStyle` 样式。
    - 通过菜单栏 (`LiteLog -> Settings...`) 或快捷键 (`⌘,`) 打开独立窗口。
    - 提供"Base URL"、"Admin API Key"、"Lookback（小时）"、"Page Size" 输入/控制，使用深色主题和蓝色焦点边框（Lookback 合理范围：1–168，默认 24；Page Size 合理范围：10–500，默认 50）。
    - 在 Admin API Key 下方显示隐私保护说明。
    - 窗口尺寸固定为合理范围，保存后自动刷新主界面数据。

- **组件库**:
    - **StatusBadge**: 状态徽章组件，成功为绿色，失败为红色，带有对应的背景色。
    - **LinearCardStyle**: 统一的卡片样式修饰器，支持交互状态。
    - **LinearButtonStyle**: 三种按钮样式 (primary/secondary/ghost)。
    - **LinearTextFieldStyle**: 自定义文本输入框样式。
    - **LinearPicker**: 自定义的分段选择器，用于在「Formatted」和「JSON」视图之间切换，提供 Linear 风格的视觉体验。
    - **SectionHeader**: 用于详情视图中各大区域（如 Tools, Messages, Request Payload）的统一标题样式。

- **关于窗口**:
    - 通过菜单栏 (`LiteLog -> About LiteLog`) 打开。
    - **显示应用图标**: 界面顶部显示应用的图标。
    - 显示应用名称、版本号和版权信息。
    - 版本号和版权信息从 `Info.plist` 动态读取。
    - **固定窗口尺寸**: 窗口尺寸固定为 400x300 像素，不可拖动调整大小，提供一致的视觉体验。
    - **优化内边距**: 界面内容（包括图标、文本）与窗口边缘保持 40 像素的水平内边距，以及 40 像素的顶部和底部内边距，确保视觉平衡。

- **状态指示**:
    - **加载状态**: 在对应区域显示旋转的加载指示器。
    - **空状态**: 使用统一的提示文本样式显示空状态信息。
    - **错误状态**: 在主窗口底部显示红色错误提示条。
    - **交互反馈**: 卡片悬停效果、按钮按压动画、选中状态高亮。

- **高级交互**:
    - **键盘导航**:
        - **功能**: 用户可以使用 `↑` 和 `↓` 键在中间的日志列表中导航，使用 `Enter` 键选中当前聚焦的日志条目。
        - **实现**: 在 `ContentViewModel` 中增加了 `focusedLogEntryId` 状态来追踪焦点。`ContentView` 通过 `@FocusState` 和 `.onKeyPress` 修饰符来捕获键盘事件并调用 `ViewModel` 中的导航逻辑。`LogEntryRowView` 根据传入的 `isFocused` 状态显示与鼠标悬停一致的视觉反馈。
    - **全局热键**:
        - **功能**: 用户可以通过全局快捷键 `Cmd+Shift+L` 在系统的任何地方快速显示或隐藏应用主窗口。
        - **实现**: 创建了一个独立的 `GlobalHotkeyMonitor` 服务类，使用 Carbon 框架的 `RegisterEventHotKey` API 注册全局热键。当热键触发时，该服务会发送一个 `toggleMainWindow` 的 `Notification`。`LiteLogApp` 在顶层接收此通知，并调用 `openWindow` 或 `orderOut` 来可靠地显示/隐藏由 `WindowGroup` 管理的窗口，实现了 AppKit 底层事件与 SwiftUI 上层窗口管理的清晰解耦。

### 4. 架构与关键实现细节

- **项目类型**: 基于 Xcode 项目 (.xcodeproj) 的标准 macOS 应用程序。项目已从原先的 Swift Package Manager (SPM) 结构迁移，以解决原生应用打包和配置的复杂性。
- **设计系统架构**: 
    - **DesignSystem.swift**: 中央化的设计系统，包含颜色、字体、间距、圆角等设计 Token。
    - **自定义样式**: 实现了 `LinearCardStyle`、`LinearButtonStyle`、`LinearTextFieldStyle` 等自定义 ViewModifier。
    - **组件复用**: `StatusBadge`、`KeyRowView` 等可复用组件，确保界面一致性。
    - **交互处理**: 使用 `.onTapGesture` 替代 Button 包装，实现全区域可点击的卡片交互。
- **自定义窗口样式**: 在 `LiteLogApp.swift` 中，通过对主 `WindowGroup` 应用 `.windowStyle(.hiddenTitleBar)` 修饰符，实现了无边框和透明标题栏的窗口效果，同时保留了标准的窗口控制按钮（红绿灯）和工具栏项。
- **状态管理**: 
    - 使用一个 `AppEnvironment` 的 `ObservableObject` 在根视图注入，用于管理全局状态，如 `APIService` 实例。
    - `ContentViewModel` 和 `SettingsViewModel` 分别管理主视图和设置视图的状态和业务逻辑。
        - ContentViewModel：读取并应用 Lookback/Page Size；为每个 Key 维护时间窗口 `[startDate, endDate]`；`loadOlder()` 将窗口向过去滑动一个 Lookback 跨度并增量追加（含去重）；使用 `isPaginating` 避免全屏 Loading；`manualRefresh()` 现在仅重置并重新加载当前 Key 的日志；新增 `refreshKeysAndLogs()` 方法，用于清空所有缓存并重新获取 Key 列表。
    - 使用 `NotificationCenter` 在设置保存后通知 `AppEnvironment` 重新加载 `APIService`。
    - **视图渲染策略**: 为了解决因状态提升到 `AppEnvironment` 后，主视图“过度观察”而导致的性能问题，`ContentView` 被拆分为独立的 `SidebarView` 和 `LogListView`。每个子视图仅观察其自身所需的数据（例如 `SidebarView` 只关心 `virtualKeys` 的变化），从而避免了不必要的全局刷新，保证了 UI 的流畅性。这体现了在 SwiftUI 中通过拆分视图层级来实现精准、高效渲染的最佳实践。同时，将 `currentLogEntries` 等派生数据作为 `AppEnvironment` 的计算属性，实现了业务逻辑的归一。
- **数据模型扩展**: 新增 `Payload.swift` 文件，定义了 `ChatMessage`、`ToolCall`、`FunctionCall`、`ChatRequestPayload` 和 `ChatResponsePayload` 等结构体。这些模型不仅用于解码，还将部分业务逻辑（如生成可复制的字符串 `copyableString`）封装在内，遵循了“将逻辑移向数据”的设计原则，以保持视图层的简洁。
- **视图重构 (LLOG-14 优化)**: 为了大幅提升详情视图的视觉质量和布局一致性，进行了多项重构：
    - **统一标题**: 创建了可复用的 `SectionHeader` 组件，并应用于所有详情页的大标题（如 Tools, Messages, Request Payload），确保了视觉风格的统一。
    - **优化工具调用**: 创建了独立的 `ToolCallView` 组件，以卡片化、带图标和结构化的形式展示 Assistant 消息中的工具调用，取代了原有的简陋文本样式。
    - **优化工具定义**: 重构了 `ToolsSectionView` 及其子视图 `ParameterRowView` 的内部布局，使用 `Grid` 替代了僵硬的 `HStack`，并修正了对齐与间距问题，使其在展开时能撑满宽度并保持优雅。
    - **优化消息卡片**: 彻底重构了 `MessageCard` 的布局，将“复制”按钮从卡片内部移至外部的“角色标题”行，从根本上解决了边距不一致和元素重叠的问题，使卡片成为一个布局纯粹、边距对称的内容容器。

- **数据与网络层**:
    - `APIService.fetchLogs` 更新：接受 `startDate`、`endDate`、`pageSize` 参数（时间格式 `yyyy-MM-dd HH:mm:ss`），外部可控时间范围与分页大小。
    - 列表顶部/底部的滚动位置检测采用“可见哨兵”方案：在顶部/底部放置 1pt 透明视图，通过 `onAppear/onDisappear` 更新 `isAtTop/isAtBottom`，避免坐标空间/通知在 macOS 上的不一致问题。

### 5. 数据模型 (Swift)

最终实现的 Swift 数据模型如下，以匹配实际的 API 响应和应用逻辑：

```swift
// 代表一个虚拟 API Key
struct VirtualKey: Codable, Identifiable, Hashable {
    var id: String { token }
    let token: String
    let keyName: String
    let keyAlias: String? // 设置为可选，以兼容 API 返回 null 的情况
    let spend: Double
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case token
        case keyName = "key_name"
        case keyAlias = "key_alias"
        case spend
        case createdAt = "created_at"
    }
}

// 代表一条日志记录
struct LogEntry: Codable, Identifiable, Hashable {
    var id: String { requestId }
    
    let requestId: String
    let status: String
    let model: String
    let startTime: String
    let endTime: String
    let spend: Double
    let totalTokens: Int?
    let promptTokens: Int?
    let completionTokens: Int?
    let user: String?
    let metadata: [String: AnyCodable]?
    let cacheHit: String?
    let customLlmProvider: String?
    let apiBase: String?
    let requestPayload: Data?
    let responsePayload: Data?

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case status, model, user, metadata
        case startTime = "startTime"
        case endTime = "endTime"
        case spend
        case totalTokens = "total_tokens"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case cacheHit = "cache_hit"
        case customLlmProvider = "custom_llm_provider"
        case apiBase = "api_base"
        case requestPayload = "proxy_server_request"
        case responsePayload = "response" // 已修正为正确的 "response"
    }
    
    // ... 自定义的 Codable 初始化方法和 AnyCodable 辅助结构体 ...
}

// 新增的载荷数据模型 (LiteLog/Models/Payload.swift)
struct ChatMessage: Codable, Hashable, Identifiable {
    var id = UUID()
    let role: String
    let content: String?
    let toolCalls: [ToolCall]?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCalls = "tool_calls"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
    }
}

struct ToolCall: Codable, Hashable, Identifiable {
    var id: String // This is the 'id' from the JSON, e.g., "call_vaIva6JAahiDBmj3Ut6xfFq0"
    let type: String
    let function: FunctionCall

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case function
    }
}

struct FunctionCall: Codable, Hashable {
    let name: String
    let arguments: String // Arguments are typically a JSON string
}

// For LLOG-12: Tool Definition Card
struct ToolDefinition: Codable, Hashable, Identifiable {
    var id = UUID()
    let type: String
    let function: FunctionDefinition
    
    enum CodingKeys: String, CodingKey {
        case type, function
    }
}

struct FunctionDefinition: Codable, Hashable {
    let name: String
    let description: String?
    let parameters: ParametersDefinition?
}

struct ParametersDefinition: Codable, Hashable {
    let type: String?
    let properties: [String: PropertyDefinition]?
    let required: [String]?
}

struct PropertyDefinition: Codable, Hashable {
    let type: String
    let description: String?
    let `enum`: [String]?
}


struct ChatRequestPayload: Codable {
    let messages: [ChatMessage]
    let tools: [ToolDefinition]?

    enum CodingKeys: String, CodingKey {
        case messages, tools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        tools = try container.decodeIfPresent([ToolDefinition].self, forKey: .tools)
    }
    
    // Add a default initializer to keep memberwise initializer for other parts of the app if needed
    init(messages: [ChatMessage], tools: [ToolDefinition]?) {
        self.messages = messages
        self.tools = tools
    }
}

struct ChatResponsePayload: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}
```

### 6. 技术要求与选型

- **目标平台**: macOS 14 (Sonoma) 或更高。
- **开发语言与框架**: Swift 与 SwiftUI。
- **项目管理**: Xcode (通过 .xcodeproj)。
- **应用名称**: `LiteLog`
- **依赖**: 
    - 无第三方依赖。