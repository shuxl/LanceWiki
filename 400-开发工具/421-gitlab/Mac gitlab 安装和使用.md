# 1 gitlab 安装
+ docker安装时，ssh协议貌似走不通
	+ 测试：部署时采用域名的方式，看看是否可以，参考 [地址](https://blog.csdn.net/ruanchengshen/article/details/134621104) 中的安装命令
+ docker安装时，http协议提交代码时，文件数量多了，会出错-500异常
## 1.1 安装步骤
### 1.1.1 启动
备注：这里的hostname，如果换成域名会怎么样
``` 
sudo docker run --detach \
--hostname locahost \
--publish 80:80 \
--publish 443:443 \
--publish 22:22 \
--name gitlab_pssd \
--volume /Volumes/SxlPSSD/docker/gitlab/etc-gitlab:/etc/gitlab \
--volume /Volumes/SxlPSSD/docker/gitlab/var-log-gitlab:/var/log/gitlab \
--volume /Volumes/SxlPSSD/docker/gitlab/var-opt-gitlab:/var/opt/gitlab \
yrzr/gitlab-ce-arm64v8
```

```
sudo docker run --detach \
--hostname localhost \
--publish 80:80 \
--publish 443:443 \
--publish 22:22 \
--name gitlab_ssd \
--volume /Volumes/SxlPSSD/docker/gitlab_mac/etc-gitlab:/etc/gitlab \
--volume /Volumes/SxlPSSD/docker/gitlab_mac/var-log-gitlab:/var/log/gitlab \
--volume /Volumes/SxlPSSD/docker/gitlab_mac/var-opt-gitlab:/var/opt/gitlab \
yrzr/gitlab-ce-arm64v8
```

安装到外接盘的命令
```
sudo docker run --detach \

--hostname locahost \

--publish 9080:80 \

--publish 9443:443 \

--publish 9022:22 \

--name gitlab_pssd \

--volume /Volumes/SxlPSSD/docker/gitlab/etc-gitlab:/etc/gitlab \

--volume /Volumes/SxlPSSD/docker/gitlab/var-log-gitlab:/var/log/gitlab \

--volume /Volumes/SxlPSSD/docker/gitlab/var-opt-gitlab:/var/opt/gitlab \

yrzr/gitlab-ce-arm64v8
```
### 1.1.2 访问地址
+ http://localhost:9080/
### 1.1.3 首次登陆和修改初始密码
+ 账号root，密码为：/etc/gitlab/initial_root_password文件中的初始密码
+ 登陆后修改密码后，可以永久使用
## 1.2 配置acess token
![](img/Pasted%20image%2020250310155253.png)

## 1.3 给账号配置ssh key

## 1.4 安装问题
