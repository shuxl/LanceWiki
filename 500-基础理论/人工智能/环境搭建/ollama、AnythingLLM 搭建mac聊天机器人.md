# 1 AnythingLLM是什么
## 1.1 核心功能与操作流程

1.  **知识库管理**
    -   **创建工作区**：新建独立工作区管理不同文档，避免上下文混淆。
    -   **文档导入**：支持 PDF、TXT、DOCX、Excel 等格式，通过“导入数据”按钮上传文件。
2.  **智能交互功能**
    -   **文档问答**：上传文档后，通过对话模式提取信息（如“总结这篇报告的核心观点”）。
    -   **查询模式**：直接提问获取文档关键内容，无上下文关联。
3.  **AI 代理定制**
    -   为不同场景创建专用代理（如代码解析、PDF 摘要），独立配置模型和规则。
# 2 ollama 
Ollama 是一个本地运行大语言模型（LLM）的工具，支持 macOS、Linux 和 Windows（WSL2）。它可以让你在自己的电脑上运行 AI 模型，而无需云端 API，适用于聊天、代码生成、文本处理等任务。

## 2.1 **如何在 macOS 上使用 Ollama？**

**1. 安装 Ollama**
在 macOS 上，你可以使用 Homebrew 进行安装：
```
brew install ollama
```
或者，直接从官方下载安装包：[https://ollama.com/download](https://ollama.com/download)
安装完成后，可以运行以下命令来检查是否安装成功：
```
ollama --version
```

---

**2. 下载并运行模型**
Ollama 支持多个开源 LLM，如 Mistral、Llama2、Gemma 等。
**运行一个模型（如 Mistral）：**
```
ollama run mistral
```
（如果本地没有 mistral，Ollama 会自动下载）
在终端中输入你的问题，Ollama 会返回 AI 生成的回答。

---

**3. 常用命令**
**（1）查看本地已有模型**
```
ollama list
```
**（2）下载指定模型**
```
ollama pull gemma
```
**（3）删除模型**
```
ollama rm mistral
```
**（4）使用 API**
Ollama 提供 REST API，可以在代码中调用：
```
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "What is Java?",
  "stream": false
}'
```

---

**4. 自定义模型**
你可以创建一个 Modelfile，基于现有模型进行微调。例如：
```
FROM mistral
SYSTEM "You are a senior Java developer."
```
然后运行：
```
ollama create my-java-expert -f ./Modelfile
```
使用：
```
ollama run my-java-expert
```

---

**适用场景**
• **本地 AI 聊天**（无需联网）
• **代码辅助**
• **文档摘要**
• **自动化任务**
• **嵌入到应用程序**

---

**总结**
1. **安装 Ollama**：brew install ollama
2. **运行模型**：ollama run mistral
3. **管理模型**：ollama list / ollama pull gemma / ollama remove mistral
4. **调用 API**：使用 curl 或集成到应用程序
  