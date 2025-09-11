## 技术实现文档：macOS LiteLLM 日志查看器 "LiteLog" (V1.0)

### 1. 项目概述

**项目名称**: LiteLog

**目标**: 一款基于 Swift Package Manager 构建的原生 macOS 应用程序，用于连接到用户的 LiteLLM 代理实例，方便地查看和管理通过不同 API Key 生成的请求日志。

**核心价值**: 提供一个比 Web UI 或命令行更流畅、更集成、更高效的日志监控体验，专注于 API Key 管理和日志审查。

### 2. 核心功能 (V1.0)

- **设置配置**: 用户可以在应用的设置界面中配置 LiteLLM 实例的 **Base URL** 和 **Admin API Key**。
- **凭证存储**: Admin API Key 和 Base URL 都使用 `UserDefaults` 进行存储。移除了原定用于增强安全性的 `Keychain` 方案，以简化实现。
- **虚拟 Key 列表**: 
    - 应用启动后，自动使用已配置的 Base URL 和 Admin Key 从 `/key/list` 接口获取所有虚拟 API Key。
    - 在左侧边栏中展示虚拟 Key 列表。每项会显示其别名 (`key_alias`)，如果别名不存在，则会显示其 `key_name` 作为备用。
- **日志查看**:
    - 当用户在左侧边栏选择一个虚拟 Key 时，应用向 `/spend/logs/ui` 接口发起请求，获取该 Key 的日志。
    - 在中间栏以列表形式展示日志摘要。
    - 当用户点击某条日志时，在右侧详情栏展示该日志的完整信息，特别是格式化后的请求和响应 JSON。
- **状态持久化**: 应用通过 `UserDefaults` 记住用户上次选择的虚拟 Key，在下次启动时自动选中并加载其日志。
- **基础交互**:
    - 提供手动刷新按钮，用于重新加载 Key 列表和日志列表。
    - 在数据加载期间显示加载指示器 (Spinner)。
    - 在列表为空时显示明确的“暂无数据”或“未找到 API Key”等提示。
- **设置自动刷新**: 在设置界面保存配置后，主界面会自动刷新数据，无需手动重启应用。
- **API 兼容性**: 
    - 对 API 返回空数据的情况做了兼容处理，当服务器返回 200 OK 但响应体为空时，应用会视作空列表而不是解析失败。
    - 对 API 返回数据中 `key_alias` 为 `null` 的情况做了兼容。

### 3. 用户界面 (UI) 与用户体验 (UX)

- **主窗口布局**: 采用经典的 `NavigationSplitView` 实现三栏式布局：
    - **左栏 (Sidebar)**: 显示虚拟 Key 列表。当前选中的 Key 有高亮状态。在侧边栏左下角提供一个设置按钮，点击可快速打开设置界面。
    - **中栏 (Content List)**: 显示所选 Key 的日志条目列表。每条日志简洁地显示 **状态** (成功/失败)、**模型名称**、**请求时间**、**费用** 和 **耗时**。
    - **右栏 (Detail View)**: 显示中栏所选日志的全部详情。其中，请求和响应的 Payload 以**带有语法高亮**的 JSON 字符串形式展示在背景色为 **RGB(15, 17, 25)** 的滚动视图中，并在右上角提供**拷贝图标**，点击可复制内容。
- **设置界面**:
    - 通过菜单栏 (`LiteLog -> Settings...`) 或快捷键 (`⌘,`) 打开一个独立的设置窗口。
    - 提供“Base URL”和“Admin API Key”的输入框，并提供“保存”和“取消”按钮。
    - 保存成功后，发送全局通知，主界面收到通知后会自动刷新数据。
- **状态指示**:
    - **加载状态**: 在左栏、中栏加载数据时，在其视图中央显示一个旋转的加载动画 (Spinner)。
    - **空状态**: 当列表为空时，在对应区域中央显示提示文字。
    - **错误状态**: 当 API 请求失败时，在主窗口底部显示红色的错误信息条，内容为具体的错误描述。

### 4. 架构与关键实现细节

- **项目类型**: 基于 Swift Package Manager (SPM) 的可执行程序，未使用传统的 Xcode Project (.xcodeproj)。
- **应用激活问题与解决方案**: 
    - **问题**: 直接通过 SPM 构建的 App 在 `swift run` 时无法成为前台激活应用，导致菜单栏不显示。
    - **解决方案**: 采用了两种方式确保应用被识别为标准的前台应用：
        1.  **嵌入 Info.plist**: 在 `Package.swift` 中通过 `linkerSettings` 的 `-sectcreate` 标志，强制将一个自定义的 `Info.plist` 文件嵌入到编译好的可执行文件中。该 `Info.plist` 文件中明确设置 `LSApplicationActivationPolicy` 为 `regular`。
        2.  **代码强制激活**: 在 `LiteLogApp.swift` 的 `init()` 方法中，通过代码 `NSApplication.shared.setActivationPolicy(.regular)` 和 `NSApplication.shared.activate(ignoringOtherApps: true)` 再次强制设置和激活应用，作为双重保障。
- **状态管理**: 
    - 使用一个 `AppEnvironment` 的 `ObservableObject` 在根视图注入，用于管理全局状态，如 `APIService` 实例。
    - `ContentViewModel` 和 `SettingsViewModel` 分别管理主视图和设置视图的状态和业务逻辑。
    - 使用 `NotificationCenter` 在设置保存后通知 `AppEnvironment` 重新加载 `APIService`。

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
        case requestPayload = "proxy_server_request"
        case responsePayload = "response" // 已修正为正确的 "response"
    }
    
    // ... 自定义的 Codable 初始化方法和 AnyCodable 辅助结构体 ...
}
```

### 6. 技术要求与选型

- **目标平台**: macOS 14 (Sonoma) 或更高。
- **开发语言与框架**: Swift 与 SwiftUI。
- **项目管理**: Swift Package Manager (SPM)。
- **应用名称**: `LiteLog`
- **依赖**: 
    - `Cocoa`: 在 `Package.swift` 中明确链接，以辅助解决应用激活问题。
    - `Splash`: 用于代码语法高亮。
    - 无其他第三方依赖。