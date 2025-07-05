
# 1 Proxy类的代理
- JDK动态代理只能代理有接口的类,并且是能代理接口方法,不能代理一般的类中的方法
- 提供了一个使用InvocationHandler作为参数的构造方法。在代理类中做一层包装,业务逻辑在invoke方法中实现
- 重写了Object类的equals、hashCode、toString，它们都只是简单的调用了InvocationHandler的invoke方法，即可以对其进行特殊的操作，也就是说JDK的动态代理还可以代理上述三个方法
- 在invoke方法中我们甚至可以不用Method.invoke方法调用实现类就返回。这种方式常常用在RPC框架中,在invoke方法中发起通信调用远端的接口等

## 1.1 调用示例
``` java
package com.shuxl.proxy;  
  
import java.lang.reflect.Proxy;  
  
/**  
 * 代理模式示例  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:42  
 * @since 1.0.0  
 */public class DynamicProxyDemo {  
    public static void main(String[] args) {  
        // 创建真实对象  
        IUserService realService = new UserServiceImpl();  
  
        // 创建动态代理  
        IUserService proxyInstance = (IUserService) Proxy.newProxyInstance(  
                realService.getClass().getClassLoader(), // 类加载器  
                realService.getClass().getInterfaces(),  // 实现的接口  
                new ServiceInvocationHandler(realService) // 代理处理器  
        );  
  
        // 通过代理对象执行操作  
        proxyInstance.login("admin", "123456");  
        proxyInstance.login("guest", "111111");  
        proxyInstance.logout();  
  
        // 展示代理类信息  
        System.out.println("\n代理类实际类型: " + proxyInstance.getClass().getName());  
        System.out.println("代理类父类: " + proxyInstance.getClass().getSuperclass());  
        System.out.println("代理类实现的接口: ");  
        for (Class<?> clazz : proxyInstance.getClass().getInterfaces()) {  
            System.out.println("  " + clazz.getName());  
        }  
    }  
}
```

```

[动态代理] 开始执行方法: login
真实登录：登录成功
[动态代理] 方法执行完成: login
├─ 返回结果: true
└─ 执行耗时: 0ms

[动态代理] 开始执行方法: login
真实登录：用户名或密码错误
[动态代理] 方法执行完成: login
├─ 返回结果: false
└─ 执行耗时: 0ms

[动态代理] 开始执行方法: logout
执行真实退出操作
[动态代理] 方法执行完成: logout
├─ 返回结果: null
└─ 执行耗时: 0ms

代理类实际类型: com.shuxl.proxy.$Proxy0
代理类父类: class java.lang.reflect.Proxy
代理类实现的接口: 
  com.shuxl.proxy.IUserService
```

## 1.2 代码
``` java
/**  
 * 定义业务接口  
 *  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:39  
 * @since 1.0.0  
 */interface IUserService {  
    boolean login(String username, String password);  
    void logout();  
}
```

``` java
/**  
 * 真实对象（被代理对象）  
 *  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:39  
 * @since 1.0.0  
 */public class UserServiceImpl implements IUserService {  
    @Override  
    public boolean login(String username, String password) {  
        // 模拟真实登录逻辑  
        if ("admin".equals(username) && "123456".equals(password)) {  
            System.out.println("真实登录：登录成功");  
            return true;        }  
        System.out.println("真实登录：用户名或密码错误");  
        return false;    }  
  
    @Override  
    public void logout() {  
        System.out.println("执行真实退出操作");  
    }  
}
```

``` java  
import java.lang.reflect.InvocationHandler;  
import java.lang.reflect.Method;  
  
/**  
 *  动态代理处理器  
 *  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:40  
 * @since 1.0.0  
 */public class ServiceInvocationHandler implements InvocationHandler {  
  
    // 被代理的真实对象  
    private final Object target;  
  
    public ServiceInvocationHandler(Object target) {  
        this.target = target;  
    }  
  
    @Override  
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {  
        // 方法执行前增强  
        System.out.println("\n[动态代理] 开始执行方法: " + method.getName());  
        long startTime = System.currentTimeMillis();  
  
        // 调用真实对象的方法  
        Object result = method.invoke(target, args);  
  
        // 方法执行后增强  
        long duration = System.currentTimeMillis() - startTime;  
        System.out.println("[动态代理] 方法执行完成: " + method.getName());  
        System.out.println("├─ 返回结果: " + result);  
        System.out.println("└─ 执行耗时: " + duration + "ms");  
  
        return result;  
    }  
}
```