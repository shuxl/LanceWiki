## 0.1 [ Spring在代码中获取bean的几种方式 ][Spring_bean_] ##

方法一：在初始化时保存ApplicationContext对象   
方法二：通过Spring提供的utils类获取ApplicationContext对象   
方法三：继承自抽象类ApplicationObjectSupport   
方法四：继承自抽象类WebApplicationObjectSupport   
方法五：实现接口ApplicationContextAware   
方法六：通过Spring提供的ContextLoader

**获取spring中bean的方式总结： **  


##### 0.1.1.1.1 方法一：在初始化时保存ApplicationContext对象 #####

    ApplicationContext ac = new FileSystemXmlApplicationContext("applicationContext.xml"); 
    ac.getBean("userService");//比如：<bean id="userService" class="com.cloud.service.impl.UserServiceImpl"></bean>

说明：这样的方式适用于採用Spring框架的独立应用程序，须要程序通过配置文件手工初始化Spring的情况。

##### 0.1.1.1.2 方法二：通过Spring提供的工具类获取ApplicationContext对象       #####

    ApplicationContext ac1 = WebApplicationContextUtils.getRequiredWebApplicationContext(ServletContext sc); 
    ApplicationContext ac2 = WebApplicationContextUtils.getWebApplicationContext(ServletContext sc); 
    ac1.getBean("beanId"); 
    ac2.getBean("beanId");

说明：这样的方式适合于採用Spring框架的B/S系统，通过ServletContext对象获取ApplicationContext对象。然后在通过它获取须要的类实例。上面两个工具方式的差别是，前者在获取失败时抛出异常。后者返回null。

##### 0.1.1.1.3 方法三：继承自抽象类ApplicationObjectSupport #####

  
说明：抽象类ApplicationObjectSupport提供getApplicationContext()方法。能够方便的获取ApplicationContext。

Spring初始化时。会通过该抽象类的setApplicationContext(ApplicationContext context)方法将ApplicationContext 对象注入。
```
@Component
public class ApplicationContextUtil2 extends ApplicationObjectSupport {
    public Map<String, BaseMapper> getTables() {
        return super.getApplicationContext().getBeansOfType(BaseMapper.class);
    }
}
```

##### 0.1.1.1.4 方法四：继承自抽象类WebApplicationObjectSupport #####

  
说明：类似上面方法。调用getWebApplicationContext()获取WebApplicationContext

##### 0.1.1.1.5 方法五：实现接口ApplicationContextAware #####

  
说明：实现该接口的setApplicationContext(ApplicationContext context)方法，并保存ApplicationContext 对象。Spring初始化时，会通过该方法将ApplicationContext对象注入。

下面是实现ApplicationContextAware接口方式的代码，前面两种方法类似：

    public class SpringContextUtil implements ApplicationContextAware 
    { 
        // Spring应用上下文环境 
        private static ApplicationContext applicationContext;
         
        /**
          * 实现ApplicationContextAware接口的回调方法。设置上下文环境
           * 
           * @param applicationContext 
        */ 
        public void setApplicationContext(ApplicationContext applicationContext) {
             SpringContextUtil.applicationContext = applicationContext;
        }

        /**
         * @return ApplicationContext
        */ 
        public static ApplicationContext getApplicationContext() {
             return applicationContext; 
        } 
        
        /**
         * 获取对象
         * 
         * @param name 
         * @return Object 
         * @throws BeansException
        */ 
        public static Object getBean(String name) throws BeansException {
             return applicationContext.getBean(name);
        }
    }

尽管，spring提供的后三种方法能够实如今普通的类中继承或实现对应的类或接口来获取spring 的ApplicationContext对象，可是在使用是一定要注意实现了这些类或接口的普通java类一定要在Spring 的配置文件applicationContext.xml文件里进行配置。否则获取的ApplicationContext对象将为null。

##### 0.1.1.1.6 方法六：通过Spring提供的ContextLoader #####

    WebApplicationContext wac = ContextLoader.getCurrentWebApplicationContext();
    wac.getBean(beanID);

最后提供一种不依赖于servlet,不须要注入的方式。可是须要注意一点，在server启动时。Spring容器初始化时，不能通过下面方法获取Spring 容器，细节能够查看spring源代码org.springframework.web.context.ContextLoader。

好文要顶 关注我 收藏该文 ![icon_weibo_24.png][] ![wechat.png][]

[![sample_face.gif][]][sample_face.gif 1]

[yjbjingcha][sample_face.gif 1]  
[关注 - 0][- 0]  
[粉丝 - 19][- 19]

\+加关注

9

1

[« ][Link 1] 上一篇： [CSDN开源夏令营 基于Compiz的switcher插件设计与实现之compiz特效插件介绍及特效实现][Link 1]  
[» ][Link 2] 下一篇： [iOS开发 - 获取真机沙盒数据][Link 2]

posted on 2017-04-23 13:11  [yjbjingcha][]  阅读(112822)  评论(3)  [编辑][Link 3]  收藏  举报


[Spring_bean_]: https://www.cnblogs.com/yjbjingcha/p/6752265.html
[icon_weibo_24.png]: https://common.cnblogs.com/images/icon_weibo_24.png
[wechat.png]: https://common.cnblogs.com/images/wechat.png
[sample_face.gif]: https://pic.cnblogs.com/face/sample_face.gif
[sample_face.gif 1]: https://home.cnblogs.com/u/yjbjingcha/
[- 0]: https://home.cnblogs.com/u/yjbjingcha/followees/
[- 19]: https://home.cnblogs.com/u/yjbjingcha/followers/
[Link 1]: https://www.cnblogs.com/yjbjingcha/p/6752162.html
[Link 2]: https://www.cnblogs.com/yjbjingcha/p/6752268.html
[yjbjingcha]: https://www.cnblogs.com/yjbjingcha/
[Link 3]: https://i.cnblogs.com/EditPosts.aspx?postid=6752265