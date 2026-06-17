# Cursor Java 开发环境修正指南

## 问题背景
在 Cursor 中开发 Java Maven 项目时，遇到依赖解析和 Maven 配置问题。

## 修复步骤

### 1. 配置项目级 Maven Settings
**问题**: 需要使用特定的 Maven settings.xml 文件
**解决方案**: 在项目根目录创建 `.mvn/maven.config`
```bash
mkdir -p .mvn
echo "-s /Users/m684620/work/maven/huizhi/settings-specialist.xml" > .mvn/maven.config
```
**验证**: 
```bash
mvn -X help:effective-settings -Doutput=effective-settings.xml
```

### 2. 配置 Cursor 的 Maven 可执行文件路径
**问题**: Cursor 需要知道 Maven 可执行文件位置
**解决方案**: 创建项目级配置 `.vscode/settings.json`
```json
{
  "maven.executable.path": "/Users/m684620/work/maven/apache-maven-3.8.8/bin/mvn"
}
```
或者使用项目自带的 Maven Wrapper:
```json
{
  "maven.executable.path": "${workspaceFolder}/mvnw"
}
```

### 3. 解决依赖缺失问题
**问题**: `Missing artifact com.viatris.framework:viatris-starter-common:jar:0.0.12.3`
**解决方案**: 在根 `pom.xml` 的 `dependencyManagement` 中添加版本管理
```xml
<dependency>
    <groupId>com.viatris.framework</groupId>
    <artifactId>viatris-starter-common</artifactId>
    <version>${viatris-starter-web.version}</version>
</dependency>
```

### 4. 解决导入包无法解析问题
**问题**: `The import com.viatris.common cannot be resolved`
**解决方案**: 在子模块 `pom.xml` 中显式添加依赖
```xml
<dependency>
    <groupId>com.viatris.framework</groupId>
    <artifactId>viatris-common</artifactId>
</dependency>
```

### 5. 强制刷新依赖
**命令**: 
```bash
mvn -U -DinteractiveMode=false -pl [模块名] -am -DskipTests dependency:resolve
```

### 6. 确保使用 JDK 而非 JRE
**检查**: 
```bash
mvn -v
```
**修正** (macOS):
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
```

## 通用排查流程

1. **检查 Maven 配置**: 确认 settings.xml 路径和内容
2. **检查依赖管理**: 查看根 pom.xml 的 dependencyManagement
3. **检查子模块依赖**: 确认子模块 pom.xml 中的依赖声明
4. **强制刷新**: 使用 `-U` 参数强制更新依赖
5. **检查 Java 环境**: 确认使用 JDK 而非 JRE
6. **IDE 刷新**: 在 Cursor 中执行 Maven 项目重导入

## 关键文件位置
- 项目级 Maven 配置: `.mvn/maven.config`
- Cursor 项目配置: `.vscode/settings.json`
- 根依赖管理: `pom.xml` (dependencyManagement 节点)
- 子模块依赖: `[模块名]/pom.xml` (dependencies 节点)

## 常用验证命令
```bash
# 检查 Maven 版本和 Java 环境
mvn -v

# 查看有效配置
mvn help:effective-settings -Doutput=effective-settings.xml

# 强制刷新依赖
mvn -U dependency:resolve

# 编译特定模块
mvn -pl [模块名] -am compile
```
