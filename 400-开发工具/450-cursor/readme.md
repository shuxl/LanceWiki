# Cursor 开发工具文档

本目录包含 Cursor IDE 相关的配置和使用文档。

## 文档列表

### 1. [Java 开发环境配置](./cursor的java开发环境修正的方式.md)
- Maven 配置问题解决
- 依赖解析问题修复
- Cursor 中 Java 项目的正确配置方法

### 2. [前后端协同开发规范](./Cursor前后端协同开发规范.md)
- 基于 OpenAPI 3.0 规范的接口定义方法
- 前后端 Agent 协同开发的工作流程
- 使用 OpenAPI 规范实现接口约定和代码生成
- 在 Cursor 中高效进行前后端联调的实践方法

## 示例文件

### [OpenAPI 规范示例](./示例/openapi-example.yaml)
完整的 OpenAPI 3.0 规范示例，包含：
- 用户管理相关的 REST 接口定义
- 数据模型定义（User、CreateUserRequest 等）
- 统一的响应格式和错误处理
- 安全认证配置

### [后端代码生成示例](./示例/后端代码生成示例.md)
展示如何根据 OpenAPI 规范生成后端代码：
- Spring Boot Controller 生成
- DTO 类生成
- Service 层代码结构
- SpringDoc 配置

### [前端代码生成示例](./示例/前端代码生成示例.md)
展示如何根据 OpenAPI 规范生成前端代码：
- TypeScript 类型定义
- API 调用函数（axios）
- React Hook 封装
- 使用示例

### [配置文件示例](./示例/配置文件示例.md)
前后端协同开发所需的配置文件：
- `.cursorignore`：排除不需要索引的文件
- `.cursorrules`：统一开发规范
- `.vscode/settings.json`：Cursor 项目配置
- `package.json`、`pom.xml` 等依赖配置

## 快速开始

### 1. 配置 Java 开发环境
如果遇到 Java Maven 项目的问题，请参考 [Java 开发环境配置](./cursor的java开发环境修正的方式.md)。

### 2. 开始前后端协同开发
1. 阅读 [前后端协同开发规范](./Cursor前后端协同开发规范.md)
2. 参考 [OpenAPI 规范示例](./示例/openapi-example.yaml) 创建接口规范
3. 使用示例中的提示词让 Agent 生成前后端代码
4. 根据 [配置文件示例](./示例/配置文件示例.md) 配置项目

## 相关链接

- [RESTful API 开发](../../100-java/200-Spring/0605-RESTful%20API开发.md)
- [SpringDoc 迁移指南](../../100-java/250-swagger/SpringFox到SpringDoc迁移指南.md)
- [详细设计模版](../../../【其它】/模版/详细设计模版.md)

