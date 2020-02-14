#!/bin/bash
domain=$1 ; access=$2 ; email=$3 ; uid=$4; url=$5

[[ ! $domain ]] && echo "你必须拥有一个解析至当前主机的域名" && exit 1
[[ ! $access ]] && access=v2ray
[[ ! $url ]] && url=https://github.com/trending
[[ ! $email ]] && email=example@gmail.com

if [[ ! $uid ]]; then
    # 当用户未传入UID变量时, 为了防止重启容器时重新生成随机ID, 应当在初次生成时保存该uuid
    if [[ ! -e /v2ray-uid ]]; then
        uid=`uuid`
        echo $uid > /v2ray-uid
    else
        uid=`cat /v2ray-uid`
    fi
fi

echo "domain: $domain\n path: $access\n email: $email\n id: $uid"

# 设置公钥私钥路径
publickey="/etc/letsencrypt/live/$domain/fullchain.pem"
priviatekey="/etc/letsencrypt/live/$domain/privkey.pem"

is_certed(){
    if [[ -e $publickey && -e $priviatekey ]]; then 
        certed="true"
    else
        certed=""
    fi
}


# 检测证书文件是否存在
is_certed

if [[ $certed ]]; then

    # 如果公钥私钥均存在, 打印文件信息
    echo 公钥文件: $publickey && echo 私钥文件: $priviatekey
else 
    # 如果没有证书, 开始申请, 首先启动nginx
    nginx && echo "nginx启动成功"

    # 使用cetbot申请证书
    certbot --nginx --domain $domain --agree-tos -n --email $email

    # 中止nginx的运行
    nginx -s stop
fi

# 再次检测证书文件是否存在

is_certed

if [[ $certed ]]; then

    # 此时无论是通过映射获得证书, 抑或是重启容器操作, 使用之前的证书, 还是新申请证书, 应当已持有证书
    # 以下操作均以持有为前提, 如果还未持有证书, 打印错误信息并退出脚本
    # 首先检查是重启容器还是映射的证书

    if [[ ! -e /KanagawaNezumi.flag ]]; then
        
        # 如果是映射的证书, 所有的设置需要更新, 首先将nginx默认配置文件替换为一份带有ssl设置的配置文件
        /bin/cp /etc/nginx/nginx_with_ssl.conf /etc/nginx/nginx.conf

        # 使用sed命令将其中的变量替换真正的域名和路径
        sed -i -e "s/\$access/$access/g" -e "s/\$domain/$domain/g" /etc/nginx/nginx.conf

        # 获得伪装页, 并替换为默认首页index.html
        [[ $url!="none" ]] && wget -q $url -O /usr/share/nginx/html/index.html 

        # 修改v2ray配置, 包括替换服务端配置, 并替换生成客户端推荐配置
        sed -i -e "s/\$uid/$uid/g" -e "s/\$access/$access/g" /etc/v2ray/config.json # 重写 id和path
        sed -i -e "s/\$uid/$uid/g" -e "s/\$access/$access/g" -e "s/\$domain/$domain/g" /etc/v2ray/cli_config.json

        # 打印信息和推荐配置
        echo -e "你的域名: $domain\n你的路径: $access\n你的id: $uid\n推荐安卓客户端: Kitsunebi\n推荐的客户端配置(通用):"
        cat /etc/v2ray/cli_config.json

        # 设置一个标志, 代表配置已重写, 下次重启容器可以直接运行v2ray和nginx
        echo "surfing" > /KanagawaNezumi.flag
    fi

else
    echo " 当前域名$domain 无本地证书, 且证书申请失败" && exit 1
fi

echo "启动v2ray主程序和nginx进程"
nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json &
nginx -g "daemon off;"
