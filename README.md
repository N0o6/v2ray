一个便于配置VLESS+xtls & SS环境的脚本

```
installed: /etc/systemd/system/xray@xtls.service
installed: /etc/systemd/system/xray@ss.service

installed: /usr/local/etc/xray/xtls.json
installed: /usr/local/etc/xray/ss.json
```

一键运行
```
wget https://github.com/N0o6/v2ray/blob/main/install.sh --no-check-certificate && chmod +x install.sh && ./install.sh
```
