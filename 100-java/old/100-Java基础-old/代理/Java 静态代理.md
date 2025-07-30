代理类和委托类在代码运行前关系就确定了,也就是说在代理类的代码一开始就已经存在了。

# 1 调用示例
以下是一个代码示例：对原始的登陆UserServiceImpl代码进行代理，进行前、后置增强
``` java
package com.shuxl.proxy;  
  
/**  
 * 代理模式示例  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:42  
 * @since 1.0.0  
 */public class ProxyExample {  
    public static void main(String[] args) {  
        // 创建真实对象  
        IUserService realService = new UserServiceImpl();  
  
        // 创建代理对象，并注入真实对象  
        IUserService proxy = new ProxyUserServiceImpl(realService);  
  
        // 通过代理对象执行业务  
        boolean loginResult1 = proxy.login("admin", "123456");  
        boolean loginResult2 = proxy.login("guest", "111111");  
    }  
}
```

```
代理开始 - 登录操作 | 时间：1743594177181
真实登录：登录成功
代理结束 - 登录操作 | 耗时：0ms
登录结果：成功
代理开始 - 登录操作 | 时间：1743594177181
真实登录：用户名或密码错误
代理结束 - 登录操作 | 耗时：1ms
登录结果：失败
```

## 1.1 类代码
``` java
package com.shuxl.proxy;  
  
/**  
 * 定义业务接口  
 *  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:39  
 * @since 1.0.0  
 */interface IUserService {  
    boolean login(String username, String password);  
}
```

``` java
package com.shuxl.proxy;  
  
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
}
```

``` java
package com.shuxl.proxy;  
  
/**  
 *  代理对象（静态代理）  
 *  
 * @author shuxiaolong  
 * @date 4/2/25 PM7:40  
 * @since 1.0.0  
 */public class ProxyUserServiceImpl implements IUserService {  
    private IUserService userService;  
  
    public ProxyUserServiceImpl(IUserService target) {  
        this.userService = target;  
    }  
  
    @Override  
    public boolean login(String username, String password) {  
        // 前置增强处理  
        long startTime = System.currentTimeMillis();  
        System.out.println("代理开始 - 登录操作 | 时间：" + startTime);  
  
        // 调用真实对象的方法  
        boolean result = userService.login(username, password);  
  
        // 后置增强处理  
        long endTime = System.currentTimeMillis();  
        System.out.println("代理结束 - 登录操作 | 耗时：" + (endTime - startTime) + "ms");  
        System.out.println("登录结果：" + (result ? "成功" : "失败"));  
  
        // 返回最终结果  
        return result;  
    }  
}
```