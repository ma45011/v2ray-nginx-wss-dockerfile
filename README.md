# v2ray-nginx-wss-dockfile
Surfing to the sky.


通过本项目的dockerfile, 你可以使用docker快速搭建`v2ray+nginx+websocket+tls`的远程代理服务器, 需要如下前置条件:

1. 一台VPS, 可以运行docker
2. 一个域名, 该域名必须解析到VPS的IP地址
3. 连接VPS命令行的权限

---

首先, 要安装`docker`, 对于`CentOS/RHEL`系统, 执行如下命令:

```bash
yum -y install docker wget && systemctl start docker && systemctl enable docker
```

对于`Debian/Ubuntu`系统, 只需要将`yum`替换为`apt`即可

```bash
apt -y install docker wget && systemctl start docker && systemctl enable docker
```

安装完docker之后, 以下的操作与系统无关:

```bash
# 下载本项目的dockerfile
wget https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/dockerfile -O dockerfile

# 构建镜像, 可能需要一段时间
docker build . -t v2ray-nginx-wss-nezumi 
```
---

最后一步, 运行你的容器, 你可以使用环境变量指定如下变量:

- `DOMAIN` 必选, 你拥有的解析到当前主机的域名, 唯一一个必须指定的变量
- `ACCESS` 可选, 用于穿透`Nginx`访问`v2ray`的路径, 默认值: `v2ray`
- `UID` 可选, 用于`vmess`加密和解密的密码, 必须符合`uuid`格式, 默认值: 随机生成
- `URL` 可选, 伪装页的下载地址, 默认值: https://github.com/trending, 如果设为特殊值`none`
- `EMAIL` 可选, 申请证书需要使用的邮箱, 不会被验证, 默认值: example@gmail.com


其中只有`DOMAIN`是必须被指定的, 因此最简的启动代码如下(使用`www.example.com`指代你的域名, 执行时需要替换):

```bash
docker run \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=www.example.com \
  --name v2ray-nginx-wss-nezumi-c \
  v2ray-nginx-wss-nezumi
```

在运行过程中, 会自动为你申请证书,  并为nginx服务器配置ssl, 并在最后给出你`v2ray`的各项密钥, 以及客户端推荐配置, 可以直接复制使用.

当打印出客户端推荐配置后, 尝试使用推荐设置访问`google`, 如果成功, 断开命令行即可(容器不会被中断)

----

如果你打算完全指定各项变量的值(有些用户可能有配置好的客户端), 例如将域名设置为`www.example.com`, 路径设置为`KanagawaNezumi`, 密码设置为`c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a`, 伪装页下载地址设置为`https://github.com/KanagawaNezumi`, 申请证书时使用的邮箱为`example@gmail.com`, 运行命令如下:

```bash
docker run \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=www.example.com \
  -e ACCESS=KanagawaNezumi \
  -e UID=c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a \
  -e URL=https://github.com/KanagawaNezumi \
  -e EMAIL=example@gamil.com \
  --name v2ray-nginx-wss-nezumi-c \
  v2ray-nginx-wss-nezumi
```

当然, 除了域名, 可选参数视情况而定, 并没必要全部指定, 另外, `UID`必须指定为一个`uuid`格式的值, 可以访问[在线uuid生成](https://www.uuidgenerator.net/)获得一个随机生成的`uuid`.

---

如果你已经有了从`Let's Encrypt`申请的证书, 可以将证书映射进容器, 并指定对应的域名, 容器在运行时不会重新申请证书.

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
  --name v2ray-nginx-wss-nezumi-c \
  v2ray-nginx-wss-nezumi
```
---

对于打算使用自己的伪装页的用户, 应当将文件映射至容器内的`/usr/share/nginx/html`文件夹内, 且在启动容器时环境变量`URL`设为`none`, 否则启动容器时会对首页文件进行覆盖.

---

如果在某些中间环节执行了误操作导致问题, 你都可以使用如下命令, 将一切推倒重来:

```bash
docker stop $(docker ps -a -q) # 终止所有容器
docker rm $(docker ps -a -q) # 移除所有容器
docker rmi $(docker images -q) # 移除所有镜像
```
---

一旦容器开始运行, 你可以随时中止, 启动, 重启该容器, 不会发生任何错误(任何在初次启动时生成的随机值均会被记录, 不会再次生成):

```bash
docker stop v2ray-nginx-wss-nezumi-c # 中止该容器, 服务会随之停止
docker start v2ray-nginx-wss-nezumi-c # 启动中止状态后的容器, 继续提供服务
docker restart v2ray-nginx-wss-nezumi-c # 中止, 然后启动该容器
```

如果需要该容器长时间运行, 可以在初次运行`docker run`指令时使用`--restart=always`选项, 确保该容器在意外中断时被docker守护进程重启, 如果该容器已运行, 执行如下命令为其更新状态:

```bash
docker container update --restart=always v2ray-nginx-wss-nezumi-c
```

在主机重启后, 由于`docker`守护进程会随系统启动, 该容器也会随后被`docker`守护进程重新启动, 因此可以无缝提供服务.

---

最后, 强烈推荐安装谷歌`BBR`加速

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```
`BBR`安装完毕后需要重启生效, 如果没有按照上一节的方法指定容器自动重启, 需要在主机重启后手动将容器启动, 具体命令请查看上一节. 

---

ps: 本镜像已发布为`docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi`, 如果不想执行本地build(耗时太久), 可以直接使用该镜像运行, 示例:

```bash
docker run \
  --restart=always \
  -p 80:80 \
  -p 443:443 \
  -e DOMAIN=www.example.com \
  -e ACCESS=KanagawaNezumi \
  -e UID=c93944d9-e2ac-4be8-8d2f-cf2fb5f4445a \
  -e EMAIL=example@gamil.com \
  --name v2ray-nginx-wss-nezumi-c \
  docker.io/kanagawanezumi/v2ray-nginx-wss-nezumi
  ```
`DockerHub`上可以查看镜像的`dockerfile`, 是与本项目完全保持一致的, 因此不必有安全上的疑虑.
