[English](README.md) | [中文](README_zh.md)

---
# LiteLog

**一款专为 LiteLLM 打造的，设计精美、体验流畅的原生 macOS 日志查看器。**

LiteLog 提供了一个比 Web UI 或命令行更高效、更集成的日志监控体验，让你能专注于 API Key 管理和日志审查，同时享受原生应用带来的流畅和美感。

![LiteLog 截图](assets/screenshot.png)

---

### ✨ 设计理念

LiteLog 的设计深受 [Linear](https://linear.app) 的启发，致力于在开发者工具中融入现代化、简洁且高效的设计语言。我们相信，优秀的工具不仅功能强大，更应赏心悦目。

- **现代化界面**: 采用类 Linear 风格的深色主题，提供沉浸式的视觉体验。
- **无边框设计**: 透明的标题栏让内容延伸至整个窗口，打破了传统窗口的束缚。
- **丰富的交互**: 精心设计的悬停、选中、点击效果，让每一次操作都清晰、跟手。
- **设计系统**: 通过统一的颜色、圆角和组件规范，确保了应用内视觉和交互的一致性。

### 核心功能

- **原生 macOS 体验**: 基于 SwiftUI 构建，充分利用系统特性，保证了低资源占用和出色的性能。
- **API Key 管理**: 自动从 LiteLLM 实例获取并展示所有虚拟 API Key，支持按别名或名称显示。
- **日志审查**:
    - 清晰地展示每个 Key 对应的日志列表，包含状态、模型、耗时、费用等关键信息。
    - **增强的载荷视图**: 点击单条日志可查看请求和响应的完整载荷 (Payload)，并提供全新的「Formatted」（格式化）和「JSON」视图。
        - **「JSON」视图**: 呈现美观的 JSON 格式数据，并提供一键复制功能。
        - **「Formatted」视图 (阶段一)**: 以聊天气泡形式显示从载荷中提取的聊天消息，按角色（System, User, Assistant）分组，每条消息都带有复制到剪贴板功能。**现在，当 Assistant 消息内容为空但包含工具调用时，Formatted 视图会清晰地展示这些工具调用信息。**
    - **直观的视图切换**: 使用自定义的 Linear 风格选择器，轻松切换「Formatted」和「JSON」载荷视图。
- **状态持久化**:
    - 自动保存 LiteLLM 的 Base URL 和 Admin API Key。
    - 记住用户上次选择的 API Key，启动时自动加载。
    - 记住主窗口的尺寸，无需反复调整。
- **智能缓存**: 切换 API Key 时缓存已加载的日志，避免不必要的网络请求，提升浏览速度。
- **简单配置**: 在独立的设置窗口中轻松配置连接参数，保存后主界面自动刷新，无需重启。
- **时间范围与分页**: 支持配置回溯时长（小时）与分页条数。底部悬浮「加载更早」增量加载更早日志（到达底部高亮；内容不足一屏不高亮）；顶部悬浮「回到最新」仅滚动到顶部，不刷新。

### 🚀 高级用户体验
- **键盘导航**: 使用箭头（`↑`/`↓`）在日志列表中导航，并使用 `Enter` 键选中条目。
- **全局热键**: 通过全局快捷键（`Cmd+Shift+L`）在 macOS 的任何地方快速显示或隐藏应用窗口。

### 🛠️ 技术栈

- **语言**: Swift
- **框架**: SwiftUI
- **目标平台**: macOS 14 (Sonoma) 及更高版本
- **项目管理**: Xcode
- **依赖**: 无任何第三方依赖，保持轻量和纯粹。

### 🚀 如何开始

#### 1. 环境要求
- macOS 14 (Sonoma) 或更高版本
- Xcode 15 或更高版本

#### 2. 构建和运行
1. 克隆本仓库到本地：
   ```bash
   git clone https://github.com/huangyafei/litelog.git
   ```
2. 使用 Xcode 打开项目文件 `LiteLog.xcodeproj`。
3. 在 Xcode 顶部选择 `LiteLog` scheme 和你的 Mac 设备。
4. 点击 "Build and Run" 按钮 (或使用快捷键 `⌘ + R`)。

#### 3. 配置应用
1. 应用启动后，通过菜单栏 `LiteLog -> Settings...` (或快捷键 `⌘ + ,`) 打开设置窗口。
2. 填入你的 LiteLLM 实例的 **Base URL** (例如 `http://localhost:4000`)。
3. 填入你的 LiteLLM **Admin API Key**。
4. 可选：调整日志选项，包括 **回溯时长（小时）** 和 **分页条数（Page Size）**，用于每次拉取及“加载更早”操作。
5. 点击 "Save" 按钮。应用将自动使用新配置刷新数据。

### 🤝 贡献

欢迎任何形式的贡献！如果你有好的想法、建议或发现了 Bug，请随时提交 [Issues](https://github.com/huangyafei/litelog/issues) 或 [Pull Requests](https://github.com/huangyafei/litelog/pulls)。

### 📄 许可证

本项目采用 [MIT License](LICENSE) 开源。
