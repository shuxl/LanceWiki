# Cursor 前后端协同开发规范

## 重点
- 基于 OpenAPI 3.0 规范的接口定义方法
- 前后端 Agent 协同开发的工作流程
- 使用 OpenAPI 规范实现接口约定和代码生成
- 在 Cursor 中高效进行前后端联调的实践方法

## 前后端协同开发概念或介绍

### 什么是前后端协同开发
前后端协同开发是指前端和后端开发人员（或 Agent）基于统一的接口规范，并行开发各自的功能模块，通过标准化的接口定义确保前后端代码的一致性和可维护性。

### 为什么需要接口规范
1. **避免接口不一致**：前后端基于同一份规范开发，减少联调时的接口不匹配问题
2. **提高开发效率**：前端可以在后端接口未完成时，基于规范进行 Mock 数据开发
3. **自动化代码生成**：根据 OpenAPI 规范自动生成前后端代码，减少重复工作
4. **文档自动生成**：接口文档自动从规范中生成，保持文档与代码同步

-[ ] 问题：在前后端协作是，如果协作文档更新了，如何保障前后端同步更新，是否需要一个协作文档，用这个文档来记录变更，以及前后端需要更新的内容，以及是否完成相应的更新操作

### OpenAPI 规范的优势
- **行业标准**：OpenAPI 3.0 是 RESTful API 的行业标准规范
- **工具生态完善**：支持代码生成、文档生成、Mock 服务等多种工具
- **Agent 友好**：结构化的 YAML/JSON 格式，便于 AI Agent 理解和处理
- **版本管理**：可以像代码一样进行版本控制和变更追踪

## 项目结构规范

### 推荐目录结构
```
project-root/
├── backend/                    # 后端工程
│   ├── src/
│   ├── pom.xml/package.json
│   └── ...
├── frontend/                   # 前端工程
│   ├── src/
│   ├── package.json
│   └── ...
├── docs/                       # 共享文档目录
│   ├── api/                    # API 接口规范目录
│   │   ├── openapi.yaml        # OpenAPI 主规范文件
│   │   └── schemas/            # 数据模型定义目录
│   │       ├── user.schema.yaml
│   │       └── common.schema.yaml
│   └── design/                 # 设计文档
└── README.md
```

### 关键文件说明
- **`docs/api/openapi.yaml`**：主 OpenAPI 规范文件，定义所有接口
- **`docs/api/schemas/`**：数据模型定义，使用 `$ref` 引用
- **`.cursorignore`**：排除不需要索引的文件，提升性能

## OpenAPI 规范定义

### 基本结构
OpenAPI 规范文件包含以下主要部分：
1. **openapi**：规范版本（推荐 3.0.0）
2. **info**：API 基本信息（标题、版本、描述）
3. **servers**：服务器地址列表
4. **paths**：接口路径定义
5. **components**：可复用的组件（schemas、parameters、responses 等）

### 规范文件示例
详细示例请参考：[OpenAPI 规范示例](./示例/openapi-example.yaml)

完整的代码生成示例请参考：
- [后端代码生成示例](./示例/后端代码生成示例.md)
- [前端代码生成示例](./示例/前端代码生成示例.md)
- [配置文件示例](./示例/配置文件示例.md)

### 数据模型定义规范
1. **使用独立的 schema 文件**：将复杂的数据模型定义在 `schemas/` 目录下
2. **使用 `$ref` 引用**：在主规范文件中通过 `$ref` 引用 schema 文件
3. **命名规范**：使用 PascalCase 命名模型（如 `User`、`OrderItem`）
4. **字段说明**：每个字段必须包含 `type`、`description` 和 `example`

## 工作流程

### 阶段一：接口设计
1. **需求分析**：明确接口功能、参数、返回值
2. **编写 OpenAPI 规范**：在 `docs/api/openapi.yaml` 中定义接口
3. **评审确认**：前后端共同评审接口规范

**给 Agent 的提示词示例：**
```
根据以下需求，在 docs/api/openapi.yaml 中定义用户管理相关的接口：
1. 获取用户列表（支持分页和搜索）
2. 根据 ID 获取用户详情
3. 创建新用户
4. 更新用户信息
5. 删除用户

请遵循 OpenAPI 3.0 规范，包含完整的请求参数、响应结构和错误码定义。
```

### 阶段二：后端开发
1. **读取 OpenAPI 规范**：后端 Agent 读取规范文件
2. **生成 Controller 代码**：根据规范生成 Spring Boot Controller
3. **生成 DTO 类**：根据 schemas 生成请求和响应 DTO
4. **实现业务逻辑**：在 Service 层实现具体业务逻辑
5. **集成 SpringDoc**：自动生成 Swagger 文档

**给后端 Agent 的提示词示例：**
```
根据 docs/api/openapi.yaml 中的用户管理接口规范，生成以下代码：
1. UserController：实现所有用户相关的 REST 接口
2. UserDTO、CreateUserRequest、UpdateUserRequest：请求和响应 DTO
3. UserService 接口和实现类：业务逻辑层

要求：
- 使用 Spring Boot 和 SpringDoc 注解
- 添加完整的参数校验（使用 @Valid）
- 统一的异常处理和响应格式
- 添加 Swagger 注解以便生成 API 文档
```

### 阶段三：前端开发
1. **读取 OpenAPI 规范**：前端 Agent 读取规范文件
2. **生成 TypeScript 类型**：根据 schemas 生成 TypeScript 接口定义
3. **生成 API 调用函数**：生成基于 axios/fetch 的 API 调用代码
4. **实现页面组件**：使用生成的类型和 API 函数实现页面

**给前端 Agent 的提示词示例：**
```
根据 docs/api/openapi.yaml 中的用户管理接口规范，生成以下代码：
1. types/user.ts：用户相关的 TypeScript 类型定义
2. api/userApi.ts：用户相关的 API 调用函数（使用 axios）
3. hooks/useUser.ts：React Hook 封装用户 API 调用

要求：
- 完整的 TypeScript 类型定义
- 统一的错误处理
- 支持请求和响应拦截器
- 使用 async/await 语法
```

### 阶段四：联调测试
1. **启动后端服务**：后端启动后，Swagger UI 自动生成文档
2. **验证接口规范**：前端 Agent 可以读取 Swagger 文档验证接口
3. **发现问题**：如果接口不一致，更新 OpenAPI 规范
4. **重新生成代码**：根据更新的规范重新生成前后端代码

## Cursor 配置建议

### .cursorignore 配置
在项目根目录创建 `.cursorignore` 文件，排除不需要索引的文件：

```
# 依赖目录
node_modules/
target/
dist/
build/
.mvn/

# 构建产物
*.class
*.jar
*.war

# 日志文件
*.log

# IDE 配置
.idea/
.vscode/
*.iml

# Git
.git/
.gitignore

# 其他
.DS_Store
```

### .cursorrules 配置
在项目根目录创建 `.cursorrules` 文件，统一开发规范：

```
# 接口开发规范
- 所有接口定义必须符合 OpenAPI 3.0 规范
- 接口文档存放在 docs/api/ 目录
- 前后端代码生成必须基于 OpenAPI 规范文件
- 数据模型定义使用独立的 schema 文件

# 代码生成规范
- 后端 Controller 必须使用 SpringDoc 注解
- 前端 API 调用必须使用 TypeScript 类型
- 所有接口必须包含完整的错误处理

# 命名规范
- API 路径使用小写字母和连字符（kebab-case）
- 数据模型使用 PascalCase
- TypeScript 接口使用 PascalCase
- Java 类使用 PascalCase
```

## 工具推荐

### 1. OpenAPI Generator
**用途**：根据 OpenAPI 规范生成前后端代码

**安装**：
```bash
# 使用 npm 安装
npm install @openapitools/openapi-generator-cli -g

# 或使用 Docker
docker pull openapitools/openapi-generator-cli
```

**使用示例**：
```bash
# 生成 Spring Boot 后端代码
openapi-generator generate \
  -i docs/api/openapi.yaml \
  -g spring \
  -o backend/generated

# 生成 TypeScript 前端代码
openapi-generator generate \
  -i docs/api/openapi.yaml \
  -g typescript-axios \
  -o frontend/generated
```

### 2. SpringDoc OpenAPI
**用途**：Spring Boot 项目自动生成 OpenAPI 文档

**依赖配置**（Maven）：
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.2.0</version>
</dependency>
```

**配置示例**：
```yaml
springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
```

### 3. Swagger Editor
**用途**：在线编辑和预览 OpenAPI 规范

**访问地址**：https://editor.swagger.io/

**使用场景**：
- 编写和验证 OpenAPI 规范
- 预览 API 文档
- 生成客户端代码

## 最佳实践

### 1. 接口设计原则
- **RESTful 风格**：遵循 REST 设计原则，使用标准 HTTP 方法
- **资源导向**：URL 使用名词而非动词（如 `/users` 而非 `/getUsers`）
- **统一响应格式**：使用统一的响应包装类
- **错误码规范**：定义清晰的错误码和错误信息

### 2. 版本管理
- **API 版本控制**：在 URL 中包含版本号（如 `/api/v1/users`）
- **规范文件版本**：OpenAPI 规范文件使用 Git 进行版本管理
- **变更记录**：在规范文件中记录接口变更历史

### 3. 文档维护
- **及时更新**：接口变更时同步更新 OpenAPI 规范
- **示例数据**：在规范中提供完整的示例数据
- **描述清晰**：每个接口和字段都要有清晰的描述

### 4. Agent 协作
- **明确分工**：后端 Agent 负责接口实现，前端 Agent 负责调用封装
- **规范优先**：所有代码生成都基于 OpenAPI 规范
- **及时同步**：规范变更后，及时通知相关 Agent 重新生成代码

## 常见问题

### Q1: 前后端放在一个工作空间会影响性能吗？
**A**: 对于中小型项目（< 10万行代码），影响很小。建议使用 `.cursorignore` 排除不必要的文件，提升索引效率。

### Q2: 如何确保前后端 Agent 使用同一份规范？
**A**: 将 OpenAPI 规范文件放在 `docs/api/` 目录，在提示词中明确指定文件路径。使用 `.cursorrules` 统一规范要求。

### Q3: 接口变更后如何同步？
**A**: 
1. 更新 `docs/api/openapi.yaml` 规范文件
2. 后端 Agent 根据新规范更新 Controller 和 DTO
3. 前端 Agent 根据新规范更新 TypeScript 类型和 API 调用
4. 使用 Git 提交变更，便于追踪

### Q4: 如何验证接口实现是否符合规范？
**A**: 
1. 后端启动后，访问 Swagger UI 查看自动生成的文档
2. 使用 OpenAPI Generator 生成客户端代码，与前端代码对比
3. 使用 Postman 等工具导入 OpenAPI 规范进行测试

### Q5: 复杂的数据模型如何组织？
**A**: 
1. 将复杂模型定义在 `docs/api/schemas/` 目录下的独立文件
2. 在主规范文件中使用 `$ref` 引用
3. 使用 `components/schemas` 定义可复用的模型

## Cursor 前后端协同开发关联的其它知识

### 相关技术文档
- [RESTful API 开发](../100-java/200-Spring/0605-RESTful%20API开发.md)
- [SpringDoc 迁移指南](../100-java/250-swagger/SpringFox到SpringDoc迁移指南.md)
- [详细设计模版](../../【其它】/模版/详细设计模版.md)

### 相关工具文档
- [Git 常用命令](../422-git/git%20常用命令.md)
- [Cursor Java 开发环境配置](./cursor的java开发环境修正的方式.md)

### 扩展阅读
- [OpenAPI 3.0 规范官方文档](https://swagger.io/specification/)
- [SpringDoc OpenAPI 官方文档](https://springdoc.org/)
- [OpenAPI Generator 文档](https://openapi-generator.tech/)

