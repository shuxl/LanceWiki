# 1 使用场景
统一管理包依赖到同一个版本，子项目只需要指定定义，不需要自己指定版本了
# 2 举例理解
使用maven是为了更好的帮项目管理包依赖，maven的核心就是pom.xml。当我们需要引入一个jar包时，在pom文件中加上<dependency></dependency>就可以从仓库中依赖到相应的jar包。

## 2.1 场景一
现在有这样一个场景，有两个web项目A、B，一个java项目C，它们都需要用到同一个jar包：common.jar。如果分别在三个项目的pom文件中定义各自对common.jar的依赖，那么当common.jar的版本发生变化时，三个项目的pom文件都要改，项目越多要改的地方就越多，很麻烦。这时候就需要用到parent标签, 我们创建一个parent项目，打包类型为pom（**parent项目只能是pom，不包含任何代码**），parent项目中不存放任何代码，只是管理多个项目之间公共的依赖。在parent项目的pom文件中定义对common.jar的依赖，ABC三个子项目中只需要定义<parent></parent>，parent标签中写上parent项目的pom坐标就可以引用到common.jar了。

**注意，ABC三个子项目如果使用parent中定义的类，还是需要添加对parent的依赖**
```
即，各个子项目，需要添加对parent 的依赖
<dependency>Parent</denpendency>
```

## 2.2 场景二
上面的问题解决了，我们在切换一个场景，有一个springmvc.jar，只有AB两个web项目需要，C项目是java项目不需要，那么又要怎么去依赖。如果AB中分别定义对springmvc.jar的依赖，当springmvc.jar版本变化时修改起来又会很麻烦。解决办法是在parent项目的pom文件中使用<dependencyManagement></dependencyManagement>将springmvc.jar管理起来，如果有哪个子项目要用，那么子项目在自己的pom文件中使用

```xml
<dependency>
    <groupId></groupId>
      <artifactId></artifactId>
</dependency>
```

标签中写上springmvc.jar的坐标，不需要写版本号，可以依赖到这个jar包了。这样springmvc.jar的版本发生变化时只需要修改parent中的版本就可以了。

## 2.3 总结
1. 当前项目或者子项目中需要哪个依赖，只需写对应坐标，不用写版本，版本统一在**当前项目或父项目的\<dependencyManagement\>中管理（也就是说\<dependencyManagement\>在本项目中引用的依赖也只是声明，本项目要想使用依赖，也需要在\<dependency\>中引用，但是可以不写明版本），子项目不需要该依赖，在子项目的pom中不写依赖的坐标即可
2. 最开始，知道dependencyManagement是管理jar包版本的，如果在父项目中的该节点下声明了包的版本，子项目中在Dependencies中引用该包时就不需要声明版本了，这样保证多个子项目能够使用相同的包版本。  
3. dependencyManagement不实际下载jar包，只会声明包的版本。**如果Dependencies中声明了包的版本，则会覆盖dependencyManagement声明的版本**。
4. 类似的还有\<pluginManagement\>
5. 后续子项目如果不想继续使用父项目定义的版本，需要通过exclusion 排除

