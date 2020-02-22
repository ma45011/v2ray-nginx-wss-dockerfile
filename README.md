# v2ray-nginx-wss-dockfile
Surfing to the sky.


通过本项目的dockerfile, 你可以使用docker快速搭建`v2ray+nginx+websocket+tls`的远程代理服务器, 需要如下前置条件:

1. 一台VPS, 可以运行docker
2. 一个域名, 该域名必须解析到VPS的IP地址
3. 连接VPS命令行的权限

---

### 总览

构建一个`v2ray+nginx+wss`服务分为三步:

1. 安装docker
2. 构建镜像
3. 运行容器

---

### 安装docker

对于`CentOS/RHEL`系统, 执行如下命令:

```bash
yum -y install docker wget && systemctl start docker && systemctl enable docker
```

对于`Debian/Ubuntu`系统, 只需要将`yum`替换为`apt`即可

```bash
apt -y install docker wget && systemctl start docker && systemctl enable docker
```

---

### 构建镜像

构建镜像有两种方式:

1. 使用本项目的`dockerfile`自行构建镜像
2. 使用已上传至`DockerHub`的本项目镜像

#### 自行构建镜像

```bash
# 下载本项目的dockerfile
wget https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/dockerfile -O dockerfile

# 构建镜像, 可能需要一段时间
docker build . -t v2ray-nginx-wss-nezumi 
```

#### 直接使用已发布的镜像

```bash
# 拉取镜像
docker pull docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi 

# 重命名本地镜像, 以符合之后章节的命令
docker tag docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi v2ray-nginx-wss-nezumi
```

在`Dockerhub`上可以查看`dockerfile`与本项目是保持一致的, 因此无需有安全上的疑虑

---

### 运行容器

因此, 在构建`nginx+v2ray+wss`服务之前, 你最好先确定三个元素:

1. 域名, 用来申请证书和伪装的域名
2. 路径, 用来穿透`Nginx`到达`v2ray`服务的路径
3. 密码, `v2ray`用来加密和解密的密码, 必须为`uuid`格式.

如果你对`uuid`的格式并不熟悉, 可以访问[此处](https://www.uuidgenerator.net/)可以获得一个随机生成的`uuid`格式的字符串.

---

本镜像所提供的环境变量如下:

- `DOMAIN` 必选, 你拥有的解析到当前主机的域名, 唯一一个必须指定的变量
- `ACCESS` 可选, 用于穿透`Nginx`访问`v2ray`的路径, 默认值: `v2ray`
- `UID` 可选, 用于`vmess`加密和解密的密码, 必须符合`uuid`格式, 默认值: 随机生成
- `URL` 可选, 伪装页的下载地址, 默认值: https://github.com/trending, 如果不需要, 请设置为`none`
- `EMAIL` 可选, 申请证书需要使用的邮箱, 不会被验证, 默认值: example@gmail.com

其中只有`DOMAIN`是必须被指定的, 但还是建议你至少指定`DOMAIN`, `ACCESS`, `UID`, 分别对应以上所解释的域名, 路径, 密码三者.

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

在运行容器的初始化阶段, 会自动申请证书, 并为`nginx`服务器开启强制`ssl`, 设置反向代理, 并在容器内启动`v2ray`服务, 打印相关信息, 并在最后给出**客户端推荐配置**, 可以**直接复制使用**.

当打印出客户端推荐配置后, 尝试使用推荐设置访问`google`, 如果成功, 断开命令行即可(容器不会被中断).

---

### 出现错误

如果在某些中间环节执行了误操作导致问题, 你都可以使用如下命令将所有容器和镜像清除:

```bash
docker stop $(docker ps -a -q) # 终止所有容器
docker rm $(docker ps -a -q) # 移除所有容器
docker rmi $(docker images -q) # 移除所有镜像
```

然后从 *第2步:构建镜像* 处重新进行. 如果出现了其他错误, 也应当执行以上命令, 并尝试重新进行, 如果仍然不能解决, 请提交issue.

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

### 自定义伪装页

伪装页在直接访问域名时作为首页展示, 通常会设置为某个外文界面, 一个独特的外文伪装页理论上可以让你的网站看起来更像是一个正常的小型网站.

在运行容器时, 可以使用环境变量`URL`指定一个网址, 对应网页随即被下载并作为`nginx`的默认首页文件, 如果无需这种行为, `URL`必须被设置为`none`

```bash
-e URL=none \
```

如果打算使用自定义伪装页, 应当将文件映射至容器内的`/usr/share/nginx/html`目录内, 且务必在启动容器时将环境变量`URL`设为`none`, 否则启动容器时会对首页文件进行覆盖.

---

### 稳定的服务

一旦容器开始运行, 你可以随时中止, 启动, 重启该容器, 不会发生任何错误(任何在初次启动时生成的随机值均会被记录, 不会再次生成):

```bash
docker stop v2ray-nginx-wss-nezumi-c # 中止该容器, 服务会随之停止
docker start v2ray-nginx-wss-nezumi-c # 启动中止状态后的容器, 继续提供服务
docker restart v2ray-nginx-wss-nezumi-c # 中止, 然后启动该容器
```

在以上示例的命令中, 容器在意外中止时会被`docker守护进程`自动重启, 而`docker守护进程`会随系统启动, 因此理论上只要容器开始正常工作, 就可以在一直提供服务.

---

### 提高用户体验

为了降低延迟和增加网速, 强烈推荐安装谷歌`BBR`加速:

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

`BBR`安装完毕后需要重启服务器生效, 示例的命令已指定容器自动重启, 因此在服务器重启后, 容器会迅速恢复执行, 如果容器未能自行启动, 请使用上一节的启动/重启容器的命令进行手动启动.

---

### 安全与效率

在使用`nginx+v2ray+wss`时, 你所发送的信息共有三层加密, 包括两层`tls`加密和一层`vmess`协议的加密. 理论上来说, `tls`加密是不可破解的, 而只要`v2ray`的密码不暴露, `vmess`协议的加密也是极难破解的, 因此安全性完全可以保证.

网络中的监听者只能观察到你在正常访问自己的域名, 但除此之外的任何信息不会被暴露, 包括你正在访问的路径. 而且由于`nginx`顶在前面, `v2ray`仅对容器内的进程提供服务, 在容器外部完全无法察觉, 因此即使观察者主动探测也无法获得任何可疑的端口或服务.

在三层加密中, 两层`tls`加密各有作用, 且几乎是完全不可破解的, 而`vmess`的加密则有些多余, 多一层加密解密过程会增加耗时, 网速和响应速度都会受到影响(尽管这种影响几近于无). 

值得一提的是, 在本项目的推荐配置中, **并未**取消`vmess`层的加密.
