# RESTful API开发

## 重点
- REST架构风格的核心概念和设计原则
- Spring MVC对RESTful API的支持和实现机制
- HTTP状态码、请求方法和响应格式的规范使用
- RESTful API的设计模式和最佳实践

## RESTful API概念或介绍

### 什么是REST
REST（Representational State Transfer）是一种软件架构风格，用于设计网络应用程序的API。它基于HTTP协议，强调资源的表述性状态转移。

**REST的核心特点：**
- 无状态：每个请求包含所有必要信息
- 客户端-服务器：关注点分离
- 可缓存：响应可以被缓存
- 统一接口：使用标准HTTP方法
- 分层系统：支持代理、网关等中间层

### REST设计原则

#### 1. 资源导向
```
GET    /users          # 获取用户列表
GET    /users/123      # 获取特定用户
POST   /users          # 创建新用户
PUT    /users/123      # 更新用户
DELETE /users/123      # 删除用户
```

#### 2. 统一接口
- **GET**：获取资源
- **POST**：创建资源
- **PUT**：更新资源（完整更新）
- **PATCH**：部分更新资源
- **DELETE**：删除资源

#### 3. 无状态
每个请求都是独立的，不依赖之前的请求状态。

## Spring MVC REST支持

### 1. @RestController注解
```java
@RestController
@RequestMapping("/api/users")
public class UserRestController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        List<User> users = userService.findAll();
        return ResponseEntity.ok(users);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        User user = userService.findById(id);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(user);
    }
}
```

**底层实现：**
```java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Controller
@ResponseBody
public @interface RestController {
    @AliasFor(annotation = Controller.class)
    String value() default "";
}
```

### 2. HTTP方法注解
```java
@RestController
@RequestMapping("/api/users")
public class UserRestController {
    
    // GET /api/users
    @GetMapping
    public List<User> getUsers() {
        return userService.findAll();
    }
    
    // GET /api/users/{id}
    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.findById(id);
    }
    
    // POST /api/users
    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {
        User savedUser = userService.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
    }
    
    // PUT /api/users/{id}
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, 
                                         @RequestBody User user) {
        user.setId(id);
        User updatedUser = userService.update(user);
        return ResponseEntity.ok(updatedUser);
    }
    
    // DELETE /api/users/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
```

### 3. ResponseEntity类
```java
@RestController
public class ApiController {
    
    @GetMapping("/users/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        
        if (user == null) {
            // 404 Not Found
            return ResponseEntity.notFound().build();
        }
        
        // 200 OK
        return ResponseEntity.ok(user);
    }
    
    @PostMapping("/users")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        User savedUser = userService.save(user);
        
        // 201 Created
        return ResponseEntity.status(HttpStatus.CREATED)
                           .body(savedUser);
    }
    
    @PutMapping("/users/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id,
                                         @RequestBody User user) {
        try {
            user.setId(id);
            User updatedUser = userService.update(user);
            return ResponseEntity.ok(updatedUser);
        } catch (Exception e) {
            // 400 Bad Request
            return ResponseEntity.badRequest().build();
        }
    }
}
```

## RESTful API设计模式

### 1. 资源命名规范

#### 使用名词而非动词
```
✅ 正确：
GET    /users
POST   /users
GET    /users/123
PUT    /users/123
DELETE /users/123

❌ 错误：
GET    /getUsers
POST   /createUser
GET    /getUserById
PUT    /updateUser
DELETE /deleteUser
```

#### 使用复数形式
```
✅ 正确：
/users
/orders
/products

❌ 错误：
/user
/order
/product
```

### 2. 状态码使用规范

#### 成功响应
```java
@RestController
public class UserController {
    
    @GetMapping("/users/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        
        if (user == null) {
            return ResponseEntity.notFound().build(); // 404
        }
        
        return ResponseEntity.ok(user); // 200
    }
    
    @PostMapping("/users")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        User savedUser = userService.save(user);
        
        return ResponseEntity.status(HttpStatus.CREATED)
                           .body(savedUser); // 201
    }
    
    @DeleteMapping("/users/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteById(id);
        
        return ResponseEntity.noContent().build(); // 204
    }
}
```

#### 错误响应
```java
@RestController
public class UserController {
    
    @PostMapping("/users")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        try {
            // 验证用户数据
            if (user.getName() == null || user.getName().isEmpty()) {
                return ResponseEntity.badRequest().build(); // 400
            }
            
            User savedUser = userService.save(user);
            return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
            
        } catch (ValidationException e) {
            return ResponseEntity.badRequest().build(); // 400
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build(); // 500
        }
    }
}
```

### 3. 分页和排序
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping
    public ResponseEntity<Page<User>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sort) {
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(sort));
        Page<User> users = userService.findAll(pageable);
        
        return ResponseEntity.ok(users);
    }
}
```

### 4. 过滤和搜索
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping("/search")
    public ResponseEntity<List<User>> searchUsers(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String role) {
        
        List<User> users = userService.search(name, email, role);
        return ResponseEntity.ok(users);
    }
}
```

## 内容协商和媒体类型

### 1. 内容协商机制
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping(value = "/{id}", 
                produces = {MediaType.APPLICATION_JSON_VALUE, 
                           MediaType.APPLICATION_XML_VALUE})
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        return ResponseEntity.ok(user);
    }
    
    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE,
                 produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<User> createUser(@RequestBody User user) {
        User savedUser = userService.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
    }
}
```

### 2. 自定义媒体类型
```java
@RestController
public class UserController {
    
    @GetMapping(value = "/users/{id}", 
                produces = "application/vnd.company.user-v1+json")
    public ResponseEntity<User> getUserV1(@PathVariable Long id) {
        User user = userService.findById(id);
        return ResponseEntity.ok(user);
    }
    
    @GetMapping(value = "/users/{id}", 
                produces = "application/vnd.company.user-v2+json")
    public ResponseEntity<UserV2> getUserV2(@PathVariable Long id) {
        User user = userService.findById(id);
        UserV2 userV2 = convertToUserV2(user);
        return ResponseEntity.ok(userV2);
    }
}
```

## 异常处理

### 1. 全局异常处理
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleUserNotFound(UserNotFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            "User not found",
            ex.getMessage()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "Validation failed",
            ex.getMessage()
        );
        return ResponseEntity.badRequest().body(error);
    }
    
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "Internal server error",
            "An unexpected error occurred"
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
```

### 2. 自定义异常类
```java
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(Long id) {
        super("User not found with id: " + id);
    }
}

public class ValidationException extends RuntimeException {
    public ValidationException(String message) {
        super(message);
    }
}

public class ErrorResponse {
    private int status;
    private String error;
    private String message;
    
    // 构造函数、getter、setter
}
```

## HATEOAS支持

### 1. Spring HATEOAS基础
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping("/{id}")
    public EntityModel<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        
        return EntityModel.of(user,
            linkTo(methodOn(UserController.class).getUser(id)).withSelfRel(),
            linkTo(methodOn(UserController.class).getAllUsers()).withRel("users")
        );
    }
    
    @GetMapping
    public CollectionModel<EntityModel<User>> getAllUsers() {
        List<User> users = userService.findAll();
        
        List<EntityModel<User>> userModels = users.stream()
            .map(user -> EntityModel.of(user,
                linkTo(methodOn(UserController.class).getUser(user.getId())).withSelfRel()))
            .collect(Collectors.toList());
        
        return CollectionModel.of(userModels,
            linkTo(methodOn(UserController.class).getAllUsers()).withSelfRel());
    }
}
```

### 2. 自定义链接
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping("/{id}")
    public EntityModel<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        
        return EntityModel.of(user,
            linkTo(methodOn(UserController.class).getUser(id)).withSelfRel(),
            linkTo(methodOn(UserController.class).getUserOrders(id)).withRel("orders"),
            linkTo(methodOn(UserController.class).updateUser(id, null)).withRel("update"),
            linkTo(methodOn(UserController.class).deleteUser(id)).withRel("delete")
        );
    }
}
```

## API版本控制

### 1. URL版本控制
```java
@RestController
@RequestMapping("/api/v1/users")
public class UserControllerV1 {
    
    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.findById(id);
    }
}

@RestController
@RequestMapping("/api/v2/users")
public class UserControllerV2 {
    
    @GetMapping("/{id}")
    public UserV2 getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        return convertToUserV2(user);
    }
}
```

### 2. 请求头版本控制
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @GetMapping("/{id}")
    public ResponseEntity<?> getUser(@PathVariable Long id,
                                   @RequestHeader(value = "API-Version", 
                                                defaultValue = "v1") String version) {
        User user = userService.findById(id);
        
        if ("v1".equals(version)) {
            return ResponseEntity.ok(user);
        } else if ("v2".equals(version)) {
            UserV2 userV2 = convertToUserV2(user);
            return ResponseEntity.ok(userV2);
        } else {
            return ResponseEntity.badRequest().build();
        }
    }
}
```

## 性能优化

### 1. 缓存支持
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @Cacheable("users")
    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        User user = userService.findById(id);
        return ResponseEntity.ok(user);
    }
    
    @CacheEvict("users")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
```

### 2. 异步处理
```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @Async
    @GetMapping("/{id}")
    public CompletableFuture<ResponseEntity<User>> getUserAsync(@PathVariable Long id) {
        return CompletableFuture.supplyAsync(() -> {
            User user = userService.findById(id);
            return ResponseEntity.ok(user);
        });
    }
}
```

## RESTful API关联的其它知识

### 相关技术栈
- **Spring MVC基础**：[Spring MVC基础](0601-Spring%20MVC基础.md)
- **控制器开发**：[控制器开发](0602-控制器开发.md)
- **拦截器机制**：[拦截器机制](0604-拦截器机制.md)
- **安全框架**：[Spring Security基础](0801-Spring%20Security基础.md)

### 扩展阅读
- **视图解析器**：[视图解析器](0603-视图解析器.md)
- **AOP编程**：[Spring AOP编程](0301-AOP基础概念.md)
- **事务管理**：[Spring事务管理](0401-事务基础概念.md)
- **数据访问**：[Spring数据访问](0501-JDBC集成.md) 