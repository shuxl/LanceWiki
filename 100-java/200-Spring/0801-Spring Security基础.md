# Spring Security基础

## 重点内容
- Spring Security核心概念和架构
- 认证（Authentication）和授权（Authorization）机制
- 安全过滤器链和SecurityContext
- 用户认证和密码编码
- 会话管理和记住我功能
- CSRF保护和XSS防护

## Spring Security基础概念或介绍

Spring Security是Spring生态系统中的安全框架，提供了全面的安全解决方案。它基于Spring框架，为Java应用提供认证、授权、会话管理、密码编码等安全功能。Spring Security采用过滤器链模式，通过一系列安全过滤器来处理HTTP请求，确保应用的安全性。

### 安全功能特点
1. **认证机制**：支持多种认证方式（表单、HTTP Basic、OAuth等）
2. **授权控制**：基于角色和权限的访问控制
3. **会话管理**：安全的会话创建、管理和销毁
4. **密码安全**：密码编码和验证机制
5. **CSRF防护**：跨站请求伪造防护
6. **XSS防护**：跨站脚本攻击防护

## 底层原理

### 关键类和接口

#### SecurityFilterChain接口
```java
public interface SecurityFilterChain {
    
    // 判断是否匹配请求
    boolean matches(HttpServletRequest request);
    
    // 获取过滤器链
    List<Filter> getFilters();
}
```

#### Authentication接口
```java
public interface Authentication extends Principal, Serializable {
    
    // 获取权限集合
    Collection<? extends GrantedAuthority> getAuthorities();
    
    // 获取凭证（通常是密码）
    Object getCredentials();
    
    // 获取详细信息
    Object getDetails();
    
    // 获取主体（通常是用户名）
    Object getPrincipal();
    
    // 是否已认证
    boolean isAuthenticated();
    
    // 设置认证状态
    void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException;
}
```

#### UserDetailsService接口
```java
public interface UserDetailsService {
    
    // 根据用户名加载用户详情
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;
}
```

### 关键类图

```
HttpServletRequest
    ↓
SecurityFilterChain
    ↓
FilterChainProxy
    ↓
SecurityContextPersistenceFilter
    ↓
UsernamePasswordAuthenticationFilter
    ↓
AuthenticationManager
    ↓
AuthenticationProvider
    ↓
UserDetailsService
    ↓
SecurityContext
```

### 核心代码讲解

#### 1. 安全过滤器链配置
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/user/**").hasRole("USER")
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/dashboard")
                .failureUrl("/login?error=true")
                .permitAll()
            )
            .logout(logout -> logout
                .logoutUrl("/logout")
                .logoutSuccessUrl("/login?logout=true")
                .invalidateHttpSession(true)
                .deleteCookies("JSESSIONID")
            )
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session
                .maximumSessions(1)
                .expiredUrl("/login?expired=true")
            );
        
        return http.build();
    }
}
```

#### 2. 自定义UserDetailsService
```java
@Service
public class CustomUserDetailsService implements UserDetailsService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
        
        return org.springframework.security.core.userdetails.User
            .withUsername(user.getUsername())
            .password(user.getPassword())
            .authorities(getAuthorities(user.getRoles()))
            .accountExpired(false)
            .accountLocked(false)
            .credentialsExpired(false)
            .disabled(!user.isEnabled())
            .build();
    }
    
    private Collection<? extends GrantedAuthority> getAuthorities(Collection<Role> roles) {
        return roles.stream()
            .map(role -> new SimpleGrantedAuthority("ROLE_" + role.getName()))
            .collect(Collectors.toList());
    }
}
```

#### 3. 密码编码器
```java
@Configuration
public class PasswordConfig {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

### 设计思想

#### 1. 过滤器链模式
通过一系列过滤器来处理安全相关的请求，每个过滤器负责特定的安全功能。

#### 2. 认证与授权分离
将认证（Authentication）和授权（Authorization）分离，提供灵活的安全控制。

#### 3. 无状态设计
支持无状态认证，便于分布式部署和扩展。

#### 4. 可扩展架构
提供丰富的扩展点，支持自定义认证和授权逻辑。

## 认证机制

### 表单认证
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .formLogin(form -> form
                .loginPage("/login")
                .loginProcessingUrl("/authenticate")
                .usernameParameter("username")
                .passwordParameter("password")
                .defaultSuccessUrl("/dashboard", true)
                .failureUrl("/login?error=true")
                .failureHandler(customAuthenticationFailureHandler())
                .successHandler(customAuthenticationSuccessHandler())
            );
        
        return http.build();
    }
    
    @Bean
    public AuthenticationSuccessHandler customAuthenticationSuccessHandler() {
        return new CustomAuthenticationSuccessHandler();
    }
    
    @Bean
    public AuthenticationFailureHandler customAuthenticationFailureHandler() {
        return new CustomAuthenticationFailureHandler();
    }
}
```

### HTTP Basic认证
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .httpBasic(basic -> basic
                .realmName("My Application")
                .authenticationEntryPoint(customBasicAuthenticationEntryPoint())
            );
        
        return http.build();
    }
    
    @Bean
    public AuthenticationEntryPoint customBasicAuthenticationEntryPoint() {
        BasicAuthenticationEntryPoint entryPoint = new BasicAuthenticationEntryPoint();
        entryPoint.setRealmName("My Application");
        return entryPoint;
    }
}
```

### JWT认证
```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Autowired
    private JwtTokenUtil jwtTokenUtil;
    
    @Autowired
    private UserDetailsService userDetailsService;
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                  HttpServletResponse response, 
                                  FilterChain filterChain) throws ServletException, IOException {
        
        String token = getTokenFromRequest(request);
        
        if (StringUtils.hasText(token) && jwtTokenUtil.validateToken(token)) {
            String username = jwtTokenUtil.getUsernameFromToken(token);
            UserDetails userDetails = userDetailsService.loadUserByUsername(username);
            
            UsernamePasswordAuthenticationToken authentication = 
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        
        filterChain.doFilter(request, response);
    }
    
    private String getTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
```

## 授权机制

### 基于角色的访问控制
```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/public/**").permitAll()
                .requestMatchers("/admin/**").hasRole("ADMIN")
                .requestMatchers("/user/**").hasAnyRole("USER", "ADMIN")
                .requestMatchers("/api/**").hasRole("API_USER")
                .anyRequest().authenticated()
            );
        
        return http.build();
    }
}
```

### 方法级安全
```java
@Service
public class UserService {
    
    @PreAuthorize("hasRole('ADMIN')")
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }
    
    @PreAuthorize("hasRole('USER') and #user.id == authentication.principal.id")
    public User updateUser(User user) {
        return userRepository.save(user);
    }
    
    @PreAuthorize("hasAuthority('READ_USER')")
    public User getUserById(Long id) {
        return userRepository.findById(id).orElse(null);
    }
    
    @PostAuthorize("returnObject.owner == authentication.name")
    public User getUserProfile() {
        return getCurrentUser();
    }
}
```

### 自定义权限评估
```java
@Component
public class CustomPermissionEvaluator implements PermissionEvaluator {
    
    @Override
    public boolean hasPermission(Authentication authentication, Object targetDomainObject, Object permission) {
        if (authentication == null || targetDomainObject == null || !(permission instanceof String)) {
            return false;
        }
        
        String targetType = targetDomainObject.getClass().getSimpleName().toUpperCase();
        return hasPrivilege(authentication, targetType, permission.toString().toUpperCase());
    }
    
    @Override
    public boolean hasPermission(Authentication authentication, Serializable targetId, String targetType, Object permission) {
        if (authentication == null || targetType == null || !(permission instanceof String)) {
            return false;
        }
        
        return hasPrivilege(authentication, targetType.toUpperCase(), permission.toString().toUpperCase());
    }
    
    private boolean hasPrivilege(Authentication authentication, String targetType, String permission) {
        for (GrantedAuthority grantedAuth : authentication.getAuthorities()) {
            if (grantedAuth.getAuthority().startsWith(targetType) && 
                grantedAuth.getAuthority().contains(permission)) {
                return true;
            }
        }
        return false;
    }
}
```

## 会话管理

### 会话配置
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .maximumSessions(1)
                .expiredUrl("/login?expired=true")
                .sessionRegistry(sessionRegistry())
            );
        
        return http.build();
    }
    
    @Bean
    public SessionRegistry sessionRegistry() {
        return new SessionRegistryImpl();
    }
}
```

### 记住我功能
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .rememberMe(remember -> remember
                .key("uniqueAndSecret")
                .tokenValiditySeconds(86400) // 24 hours
                .userDetailsService(userDetailsService)
                .rememberMeParameter("remember-me")
                .rememberMeCookieName("remember-me-cookie")
            );
        
        return http.build();
    }
}
```

## CSRF保护

### CSRF配置
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf
                .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
                .ignoringRequestMatchers("/api/**")
            );
        
        return http.build();
    }
}
```

### CSRF令牌处理
```html
<!-- 表单中的CSRF令牌 -->
<form action="/submit" method="post">
    <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}"/>
    <input type="text" name="username"/>
    <input type="password" name="password"/>
    <button type="submit">Submit</button>
</form>
```

## 安全配置最佳实践

### 密码安全
```java
@Configuration
public class SecurityConfig {
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
    
    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails user = User.builder()
            .username("user")
            .password(passwordEncoder().encode("password"))
            .roles("USER")
            .build();
        
        return new InMemoryUserDetailsManager(user);
    }
}
```

### 安全头配置
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .headers(headers -> headers
                .frameOptions().deny()
                .contentTypeOptions().and()
                .httpStrictTransportSecurity(hstsConfig -> hstsConfig
                    .maxAgeInSeconds(31536000)
                    .includeSubdomains(true)
                )
                .contentSecurityPolicy(csp -> csp
                    .policyDirectives("default-src 'self'")
                )
            );
        
        return http.build();
    }
}
```

### 异常处理
```java
@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {
    
    @Override
    public void handle(HttpServletRequest request, 
                      HttpServletResponse response, 
                      AccessDeniedException accessDeniedException) throws IOException, ServletException {
        
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.getWriter().write("Access Denied: " + accessDeniedException.getMessage());
    }
}
```

## Spring Security基础关联的其它知识

### 1. Spring Framework核心
- [Spring IoC容器](../0101-Spring%20IoC容器.md)
- [Spring Bean生命周期](../0102-Spring%20Bean生命周期.md)
- [Spring依赖注入](../0103-Spring依赖注入.md)

### 2. Spring Security进阶
- [认证机制](0802-认证机制.md)
- [授权机制](0803-授权机制.md)
- [安全配置](0804-安全配置.md)

### 3. Web安全
- [Spring MVC基础](../0201-Spring%20MVC基础.md)
- [RESTful API安全](../0203-RESTful%20API设计.md)

### 4. 相关技术
- [HTTP协议](../../500-基础理论/通用计算机知识/一篇搞懂TCP、HTTP、Socket、Socket连接池.md)
- [JWT令牌](../../300-中间件/jwt.md)
- [OAuth2认证](../../300-中间件/oauth2.md)
- [密码学基础](../../500-基础理论/密码学/密码学基础.md) 