FROM nginx
ENV DOMAIN=www.example.com EMAIL=example@gmail.com ACCESS=v2ray UID="" URL=""
RUN apt-get -y update && apt-get -y install certbot python-certbot-nginx wget uuid \
	&& mkdir /v2ray-nginx \
	&& wget -q https://install.direct/go.sh && bash go.sh \
	&& wget -q https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/nginx-with-server-block.conf -O /etc/nginx/nginx.conf \
	&& wget -q https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/nginx-v2ray.conf -O /etc/nginx/nginx_with_ssl.conf \
	&& wget -q https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/v2ray-server-config.json -O /etc/v2ray/config.json \
	&& wget -q https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/v2ray-cli-config.json -O /etc/v2ray/cli_config.json \
	&& wget -q https://raw.githubusercontent.com/KanagawaNezumi/v2ray-nginx-wss-dockerfile/master/v2ray-nginx-start.sh -O /v2ray-nginx/start.sh
ENTRYPOINT bash /v2ray-nginx/start.sh $DOMAIN $ACCESS $EMAIL $UID $URL
