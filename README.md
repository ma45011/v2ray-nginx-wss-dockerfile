# v2ray-nginx-wss-dockfile

Surfing...


通过本项目的`dockerfile`, 你可以使用`docker`快速搭建`v2ray+nginx+websocket+tls`服务, 要达成这一目标, 需要如下前置条件:

1. 一台VPS, 可以运行`docker`
2. 一个域名, 该域名必须解析到VPS的IP地址
3. 连接VPS命令行的权限


---

### 简介

在远程登录至vps的命令行之后, 构建一个`v2ray+nginx+wss`服务分为三步:

1. 安装docker(`约60秒`)
2. 获得镜像(`约30秒`)
3. 运行容器(`约10秒`)

当然, 如果你是第一次使用本项目, 你并不能真的在2分钟之内完成服务的构建, 因为绝大多数时间的耗费是在你的操作上, 而非程序的运行上. 

使用本项目搭建服务的好处在于你不必自己进行安装nginx, v2ray, 申请证书, 开启ssl, 设置反向代理,等等一系列操作, 而可以简单通过几行命令就可以搭建整套服务. 

所有源码均公开在此处, 所有的依赖项均为docker官方镜像(nginx)以及本项目内的文件, 因此也没有任何留下后门的空间, 安全方面可以保证.

---

### 安装docker

对于`CentOS/RHEL`系统(推荐), 执行如下命令:

```bash
yum -y install docker wget && systemctl start docker && systemctl enable docker
```

对于`Debian/Ubuntu`系统, 执行如下命令:

```bash
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt -y install docker-ce wget && systemctl start docker && systemctl enable docker
```

(我这里并非Debian系统, 因此以上命令并没有实际测试, 如果安装出现任何问题请在搜索'ubuntu/debian如何安装docker'解决, 总之, 成功安装docker即可)

如果已有docker, 可以跳过这一步(记得设置docker服务开机启动).

---

### 获得镜像

获得镜像有两种方式:

1. 拉取已上传至`DockerHub`的本项目镜像 (推荐).
2. 使用本项目的`dockerfile`自行构建镜像

#### 直接使用已发布的镜像

```bash
# 拉取镜像
docker pull docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi 

# 重命名本地镜像, 以与后文的示例命令保持一致
docker tag docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi v2ray-nginx-wss-nezumi

# 删除原镜像以确保所有镜像正常删除
docker rmi docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi
```

在`Dockerhub`上可以查看`dockerfile`, 与本项目是保持一致的, 即该镜像是完全由本项目的dockerfile直接构建而成, 因此无需有安全上的疑虑.


#### 自行构建镜像

```bash
# 下载本项目的dockerfile
wget https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/dockerfile -O dockerfile

# 构建镜像, 可能需要一段时间
docker build . -t v2ray-nginx-wss-nezumi 
```

---

### 运行容器

在构建`nginx+v2ray+wss`服务之前, 你最好先确定三个元素:

1. 域名, 用来申请证书和伪装的域名, 你必须拥有该域名且域名必须解析到当前主机(即正在搭建代理服务的远程主机).
2. 路径, 用来穿透`Nginx`到达`v2ray`服务的路径, 自由发挥.
3. 密码, `v2ray`用来加密和解密的密码, 必须为`uuid`格式.

如果你对`uuid`的格式并不熟悉, 可以访问[此网站-在线uuid生成](https://www.uuidgenerator.net/)获得一个随机生成的`uuid`格式的字符串.

例如, 你的域名为`www.example.com`, 路径设置为`KanagawaNezumi`, 密码设置为`c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a`, 那么运行代码如下

```bash
docker run \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=www.example.com \
  -e ACCESS=KanagawaNezumi \
  -e UID=c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a \
  --restart=always \
  --name v2ray-nginx-wss-nezumi-c \
  v2ray-nginx-wss-nezumi

# 请替换为你自己的域名, 路径, 及密码
```
(环境变量列表及其解释在下一节)

在运行容器的初始化阶段, 会自动申请证书, 并为`nginx`服务器开启强制`ssl`, 设置反向代理, 并在容器内启动`v2ray`服务, 并在最后自动生成并打印**客户端推荐配置**, 可以直接复制使用.

在镜像运行起来之后, 尝试使用推荐的客户端配置启动客户端, 并在设置好socks代理后访问`google`, 如果成功, 断开命令行即可(容器不会被中断).

关于可用的`v2ray`客户端软件, 以及如何让浏览器使用socks代理, 前者请查阅[官方文档](https://www.v2ray.com/awesome/tools.html)和[V2Ray 白话文教程](https://toutyrater.github.io/prep/install.html#%E5%AE%A2%E6%88%B7%E7%AB%AF%E5%AE%89%E8%A3%85), 或是直接进入到[此处](https://github.com/v2ray/v2ray-core/releases)下载, 后者并非什么敏感话题, 在任意搜索引擎上搜索即可, 因为这些与本项目无关, 因此不再赘述.

ps: 推荐的客户端配置中, v2ray客户端所提供的服务运行于本机的`1080`端口, 即socks代理的目标网址为`127.0.0.1:1080`, 这一点在配置socks代理时非常重要, 特此说明.

ps2: 推荐的客户端配置中, 设置了简单的路由过滤, 访问国内网址时默认直连, 国外网址则通过代理访问.

---

### 环境变量列表及解释

在`docker run`时, 本镜像所提供的环境变量如下:

- `DOMAIN` 必选, 你拥有的解析到当前主机的域名, 唯一一个必须指定的变量
- `ACCESS` 可选, 用于穿透`Nginx`访问`v2ray`的路径, 默认值: `v2ray`
- `UID` 可选, 用于`vmess`加密和解密的密码, 必须符合`uuid`格式, 默认值: 随机`uuid`
- `URL` 可选, 伪装页的下载地址, 默认值: https://github.com/trending, 如果不需要, 请设置为`none`
- `EMAIL` 可选, 申请证书需要使用的邮箱, 不会被验证, 默认值: example@gmail.com

其中只有`DOMAIN`是必须被指定的, 但还是建议你至少指定`DOMAIN`, `ACCESS` 和 `UID`, 分别对应以上所解释的域名, 路径, 密码三者.


---

### 处理错误

如果在某些中间环节执行了误操作导致问题, 你都可以使用如下命令将所有容器和镜像清除:

```bash
docker stop $(docker ps -a -q) # 终止所有容器
docker rm $(docker ps -a -q) # 移除所有容器
docker rmi $(docker images -q) # 移除所有镜像
```

然后从 **第2步:获得镜像** 处重新进行. 如果出现了其他错误, 也应当执行以上命令, 并尝试重新进行, 如果仍然出错, 请提交issue.

---

### 使用已存在的证书

对于已经从`Let's Encrypt`申请过证书的用户, 可以将证书映射进容器, 容器在运行时不会重新申请证书.

```bash
docker run \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=www.example.com \
  -e ACCESS=KanagawaNezumi \
  -e UID=c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a \
  -e URL=https://github.com/KanagawaNezumi \
  -e EMAIL=example@gamil.com \
  -v /etc/letsencrypt/live/www.example.com/fullchain.pem:/etc/letsencrypt/live/www.example.com/fullchain.pem \
  -v /etc/letsencrypt/live/www.example.com/privkey.pem:/etc/letsencrypt/live/www.example.com/privkey.pem \
  --restart=always \
  --name v2ray-nginx-wss-nezumi-c \
  v2ray-nginx-wss-nezumi

# 请替换为你自己的域名, 路径, 及密码
```

---

### 自定义伪装页

伪装页在直接访问域名时作为首页展示, 通常会设置为某个外文界面, 一个合理的, 独特的外文伪装页可以让你的网站看起来更像是一个正常的外国小型网站, 这也正是伪装的目的所在.

在运行容器时, 可以使用环境变量`URL`指定一个网址, 对应网页随即被下载并作为`nginx`的默认首页文件, 如果无需这种行为, `URL`必须被设置为`none`

```bash
-e URL=none \
```

如果打算使用自定义伪装页, 应当将首页文件映射至容器内的`/usr/share/nginx/html`目录内, 且务必在启动容器时将环境变量`URL`设为`none`(否则仍然会对首页文件进行覆盖).

---

### 稳定的服务

一旦容器开始运行, 你可以随时中止, 启动, 重启该容器, 不会发生任何错误(任何在初次启动时生成的随机值均会被记录, 不会再次生成):

```bash
# 中止该容器, 服务会随之停止
docker stop v2ray-nginx-wss-nezumi-c 

# 启动中止状态的容器, 继续提供服务
docker start v2ray-nginx-wss-nezumi-c

# 重启该容器
docker restart v2ray-nginx-wss-nezumi-c 
```

在前文的示例命令中已经设置`--restart=always`, 因此容器在意外中止时会被`docker守护进程`自动重启, 而`docker守护进程`是随系统启动的, 因此理论上只要服务器能正常启动, 容器也会一直维持.

---

### 提高用户体验

为了降低延迟和增加网速, 推荐安装谷歌`BBR`:

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

`BBR`安装完毕后需要重启服务器生效, 前文的示例命令已指定容器自动重启, 因此在服务器重启后, 容器会随之恢复执行, 如果容器未能自行启动, 请使用上一节的启动/重启容器的命令进行手动启动.

---

### 安全与效率

在使用`nginx+v2ray+wss`时, 你发送的信息通常会被三次加密, 包括两层`tls`加密(与代理的tls加密以及在此基础上与真实目的网站之间的tls加密)和一层`vmess`协议的加密. 理论上来说, `tls`加密是不可破解的, 而只要`v2ray`的密码(id)不暴露, `vmess`协议的加密也是极难破解的, 因此安全性完全可以保证.

网络中的监听者/观察者只能观察到你在访问自己的域名, 但除此之外的任何信息不会被暴露, 包括你正在访问的路径, 发送的任何信息, 以及你`真正的`目标网址. 而且由于`nginx`作为前端服务器, `v2ray`仅对容器内的进程提供服务, 在容器外部完全无法察觉, 因此即使观察者主动探测也无法获得任何可疑的端口或服务.

在三层加密中, 两层`tls`加密各有其作用, 而`vmess`的加密则有些多余: 多一层加密解密过程会增加耗时, 网速和响应速度都会受到影响(尽管这种影响通常可以忽略). 

值得一提的是, 在本项目的客户端推荐配置中, **并未**取消`vmess`层的加密(这层加密的开启与关闭仅取决于客户端).

---
