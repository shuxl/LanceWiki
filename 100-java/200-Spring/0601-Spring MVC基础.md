# Spring MVC基础

## 重点
- Spring MVC的核心架构和设计思想
- DispatcherServlet的工作原理和请求处理流程
- HandlerMapping、HandlerAdapter、ViewResolver等核心组件
- Spring MVC的底层实现原理和关键类分析

## Spring MVC概念或介绍

### 什么是Spring MVC
Spring MVC是Spring框架提供的一个基于MVC设计模式的Web应用开发框架。它是Spring框架的一个模块，专门用于构建Web应用程序。

**核心特点：**
- 基于MVC（Model-View-Controller）设计模式
- 支持RESTful风格的Web服务
- 与Spring框架无缝集成
- 支持多种视图技术（JSP、Thymeleaf、JSON等）
- 提供强大的数据绑定和验证功能

### MVC设计模式
MVC是一种软件架构模式，将应用程序分为三个核心组件：

1. **Model（模型）**：数据和业务逻辑
2. **View（视图）**：用户界面
3. **Controller（控制器）**：处理用户请求，协调Model和View

## Spring MVC架构设计

### 整体架构
```
┌─────────────────────────────────────────────────────────────┐
│                    Spring MVC 架构                          │
├─────────────────────────────────────────────────────────────┤
│  Client (浏览器)                                           │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │  DispatcherServlet │  ← 前端控制器                      │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │  HandlerMapping │  ← 处理器映射                        │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │ HandlerAdapter  │  ← 处理器适配器                      │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │   Controller    │  ← 控制器                            │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │     Service     │  ← 业务逻辑层                        │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │      DAO        │  ← 数据访问层                        │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │  ViewResolver   │  ← 视图解析器                        │
│  └─────────────────┘                                      │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────────┐                                      │
│  │      View       │  ← 视图                              │
│  └─────────────────┘                                      │
└─────────────────────────────────────────────────────────────┘
```

### 核心组件

#### 1. DispatcherServlet（前端控制器）
- **作用**：接收所有HTTP请求，统一分发
- **职责**：请求分发、异常处理、文件上传等

#### 2. HandlerMapping（处理器映射）
- **作用**：根据请求URL找到对应的Handler
- **实现**：RequestMappingHandlerMapping等

#### 3. HandlerAdapter（处理器适配器）
- **作用**：调用具体的Handler方法
- **实现**：RequestMappingHandlerAdapter等

#### 4. ViewResolver（视图解析器）
- **作用**：解析视图名称，找到对应的View对象
- **实现**：InternalResourceViewResolver等

## Spring MVC底层原理

### 关键类分析

#### 1. DispatcherServlet类结构
```java
public class DispatcherServlet extends FrameworkServlet {
    
    // 核心组件
    private List<HandlerMapping> handlerMappings;
    private List<HandlerAdapter> handlerAdapters;
    private List<ViewResolver> viewResolvers;
    
    // 请求处理的核心方法
    protected void doDispatch(HttpServletRequest request, 
                            HttpServletResponse response) throws Exception {
        // 1. 获取处理器
        HandlerExecutionChain mappedHandler = getHandler(request);
        
        // 2. 获取处理器适配器
        HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());
        
        // 3. 执行处理器
        ModelAndView mv = ha.handle(request, response, mappedHandler.getHandler());
        
        // 4. 处理视图
        processDispatchResult(request, response, mappedHandler, mv, dispatchException);
    }
}
```

#### 2. HandlerMapping接口
```java
public interface HandlerMapping {
    // 根据请求获取处理器执行链
    HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception;
}
```

#### 3. HandlerAdapter接口
```java
public interface HandlerAdapter {
    // 判断是否支持该处理器
    boolean supports(Object handler);
    
    // 执行处理器方法
    ModelAndView handle(HttpServletRequest request, 
                       HttpServletResponse response, 
                       Object handler) throws Exception;
}
```

### 请求处理流程详解

#### 1. 请求接收阶段
```java
// DispatcherServlet.doService()
protected void doService(HttpServletRequest request, 
                        HttpServletResponse response) throws Exception {
    // 设置请求属性
    request.setAttribute(WEB_APPLICATION_CONTEXT_ATTRIBUTE, getWebApplicationContext());
    
    // 调用doDispatch处理请求
    doDispatch(request, response);
}
```

#### 2. 处理器查找阶段
```java
// DispatcherServlet.getHandler()
protected HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {
    // 遍历所有HandlerMapping
    for (HandlerMapping hm : this.handlerMappings) {
        HandlerExecutionChain handler = hm.getHandler(request);
        if (handler != null) {
            return handler;
        }
    }
    return null;
}
```

#### 3. 处理器适配阶段
```java
// DispatcherServlet.getHandlerAdapter()
protected HandlerAdapter getHandlerAdapter(Object handler) throws ServletException {
    // 遍历所有HandlerAdapter
    for (HandlerAdapter ha : this.handlerAdapters) {
        if (ha.supports(handler)) {
            return ha;
        }
    }
    throw new ServletException("No adapter for handler [" + handler + "]");
}
```

#### 4. 方法执行阶段
```java
// RequestMappingHandlerAdapter.handleInternal()
protected ModelAndView handleInternal(HttpServletRequest request,
                                   HttpServletResponse response,
                                   HandlerMethod handlerMethod) throws Exception {
    // 参数解析
    Object[] args = getMethodArgumentValues(request, response, handlerMethod);
    
    // 方法调用
    Object result = handlerMethod.invoke(args);
    
    // 返回值处理
    return getModelAndView(result, handlerMethod);
}
```

### 设计思想

#### 1. 前端控制器模式
- **思想**：所有请求都通过一个统一的入口点处理
- **优势**：集中处理、统一管理、便于扩展

#### 2. 策略模式
- **应用**：HandlerMapping、HandlerAdapter、ViewResolver都使用策略模式
- **优势**：可以灵活切换不同的实现策略

#### 3. 模板方法模式
- **应用**：DispatcherServlet的doDispatch方法定义了处理流程的骨架
- **优势**：子类可以重写特定步骤，但整体流程不变

#### 4. 适配器模式
- **应用**：HandlerAdapter适配不同类型的处理器
- **优势**：统一调用接口，支持多种处理器类型

## 配置示例

### XML配置方式
```xml
<web-app>
    <!-- 配置DispatcherServlet -->
    <servlet>
        <servlet-name>dispatcher</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <load-on-startup>1</load-on-startup>
    </servlet>
    
    <servlet-mapping>
        <servlet-name>dispatcher</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```

### Java配置方式
```java
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/").setViewName("home");
    }
    
    @Bean
    public ViewResolver viewResolver() {
        InternalResourceViewResolver resolver = new InternalResourceViewResolver();
        resolver.setPrefix("/WEB-INF/views/");
        resolver.setSuffix(".jsp");
        return resolver;
    }
}
```

## Spring MVC关联的其它知识

### 相关技术栈
- **视图技术**：[Thymeleaf模板引擎](../old/120-Spring-old/spring/spring.md)
- **数据绑定**：[Spring数据绑定机制](0103-Spring依赖注入.md)
- **AOP支持**：[Spring AOP编程](0301-AOP基础概念.md)
- **事务管理**：[Spring事务管理](0401-事务基础概念.md)

### 扩展阅读
- **RESTful API**：[RESTful API开发](0605-RESTful%20API开发.md)
- **拦截器机制**：[拦截器机制](0604-拦截器机制.md)
- **视图解析**：[视图解析器](0603-视图解析器.md)
- **控制器开发**：[控制器开发](0602-控制器开发.md) 