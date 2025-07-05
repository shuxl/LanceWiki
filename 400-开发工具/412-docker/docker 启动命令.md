+ 查看容器和启动容器
	+ docker ps -a 
	+ docker start 【容器id】
# 1 实例操作

```
启动：docker start 【容器id】， 
启动容器：docker run -it openjdk:8-jdk-alpine /bin/sh
附着容器： docker attach 【容器id】
内部启动：docker exec -it 【容器id】 /bin/bash
删除容器：docker rm 【容器id】 
删除 所有容器 ：docker rm `docker ps -a -q` -q 只返回容器id
```

# 2 镜像操作

```
删除镜像：docker rmi docker.io/jenkins/jenkins:lts
批量删除镜像：docker rmi `docker images -q`
查看镜像：docker images
```

# 3 简单命令

```
-- 查看启动的镜像
docker ps -a

```

# 4 查询仓库

```
docker search mysql
```

# 5 配置镜像加速地址

默认地址

```
{
  "features": {
    "buildkit": true
  },
  "experimental": false
}
```

建议地址

```
{
  "experimental": false,
  "debug": true,
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```