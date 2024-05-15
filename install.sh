#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

# 检测系统是否为64位
cmd="apt"

sys_bit=$(uname -m)

if [[ $sys_bit == "i386" || $sys_bit == "i686" || $sys_bit == "x86_64" ]]; then
	echo
	echo -e "$green支持的 x86/x86_64 位系统$none"
else
	echo -e " 
	哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1
fi

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get || -f /usr/bin/yum ]] && [[ -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi

else

	echo -e " 
	哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}

	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1

fi

# 检测是否安装Xray-core
if [[ -f '/usr/local/bin/xray' ]]; then
	xray_version="$(/usr/local/bin/xray -version | awk 'NR==1 {print $2}')"
	xray_version="v${xray_version#v}"
	echo -e "已安装xray-core $cyan$xray_version${none}，开始执行xtls配置文件安装$none"
	echo -e ">>$yellow开始为XTLS配置做准备$none<<"
	sleep 1
else
	echo -e "$red未检测到安装xray-core，请先执行xray-install并完成安装$none"
	exit 1
fi

# 输入域名
domain_input() {

	while :; do
		echo
		echo -e "请输入$magenta本机所绑定的域名$none"
		read -p "(例如：baidu.com): " domain
		[ -z "$domain" ] && error && continue
		echo
		echo
		# 获取IP
		ip=$(curl -s https://ipinfo.io/ip)
		[[ -z $ip ]] && ip=$(curl -s https://api.ip.sb/ip)
		[[ -z $ip ]] && ip=$(curl -s https://api.ipify.org)
		[[ -z $ip ]] && ip=$(curl -s https://ip.seeip.org)
		[[ -z $ip ]] && ip=$(curl -s https://ifconfig.co/ip)
		[[ -z $ip ]] && ip=$(curl -s https://api.myip.com | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
		[[ -z $ip ]] && ip=$(curl -s icanhazip.com)
		[[ -z $ip ]] && ip=$(curl -s myip.ipip.net | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
		[[ -z $ip ]] && echo -e "\n$red 这垃圾小鸡扔了吧！$none\n" && exit
		echo "----------------------------------------------------------------"
		break
		done
		echo -e "$yellow 你输入的域名 = $cyan$domain$none"
		echo
		echo -e "$yellow 请将 $magenta$domain$none $yellow解析到: $cyan$ip$none"
		echo "----------------------------------------------------------------"
		echo
		domain_confirm
}

domain_confirm() {
	while :; do

		read -p "$(echo -e "(你确定已将本机iP解析到该域名了吗: [${magenta}Y/N$none]):") " record
		if [[ -z "$record" ]]; then
			domain_confirm
		elif [[ "$record" == [Yy] ]]; then
			domain_check
		elif [[ "$record" == [Nn] ]]; then
			clear
			domain_input
		fi
		
	done
}

domain_check() {
	test_domain=$(ping $domain -c 1 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
	if [[ $test_domain != $ip ]]; then
		echo "----------------------------------------------------------------"
		echo -e "$red 检测域名解析错误....$none"
		echo
		echo -e " 输入的域名: $yellow$domain$none 未解析到本机IP: $cyan$ip$none"
		echo
		echo -e " 你的域名当前解析到: $cyan$test_domain$none"
		echo "----------------------------------------------------------------"
		echo
		echo "如果你的域名是使用 Cloudflare 解析的话，请确认使用。" 
		read -p "$(echo -e "(你确定要使用这个域名吗: [${magenta}Y/N$none]):") " record
	else 
		if [[ -z "$record" ]]; then
			clear
			domain_check
		else
			if [[ "$record" == [Yy] ]]; then
				certbot_configration
			elif [[ "$record" == [Nn] ]]; then
				clear
				domain_input
			fi
		fi
	fi
}

certbot_configration() {
	echo
	echo -e ">>$yellow开始安装certbot并签名$none<<"
	sleep 1
	$cmd install certbot -y
	echo
	echo -e ">>$yellow开始签名$none<<"
	sleep 1
	certbot certonly -d $domain --register-unsafely-without-email --standalone --agree-tos
	echo -e ">>$green完成签名$none<<"
	echo 
	echo -e ">>$yellow写入配置$none<<"
	xray_configration
}

ss_comfirm() {
	read -p "$(echo -e "(是否安装SS协议: [${magenta}Y/N$none]):") " record
		if [[ -z "$record" ]]; then
			ss_comfirm
		else
			if [[ "$record" == [Yy] ]]; then
				ss_install
			else
				if [[ "$record" == [Nn] ]]; then
					echo
					echo "See you soon!~"
					exit
				fi
			fi
		fi
	exit
}

ss_install() {
# Config导入
cat > /usr/local/etc/xray/ss.json << EOF
{
    "inbounds": [
        {
            "port": 10248,
            "protocol": "shadowsocks",
            "settings": {
                "clients": [
                    {
                        "password": "noobnetwork",
                        "method": "aes-256-gcm"
                    }
                ],
                "network": "tcp,udp"
            }
        }
    ],
    "outbounds": [
		{
			"protocol": "freedom"
		}
    ]
}
EOF
	echo -e ">>$green开启xray@ss自启$none<<"
	systemctl enable xray@ss.service
	echo -e ">>$green开启xray@ss服务$none<<"
	systemctl start xray@ss.service
	echo
	echo -e ">>$green安装完毕√$none<<"
	exit
}

xray_configration() {
# Config导入
cat > /usr/local/etc/xray/xtls.json << EOF
{
	"log": {
		"loglevel": "warning"
	},
	"inbounds": [
		{
			"address": "127.0.0.1",
			"port": 10000,
			"protocol": "vless",
			"settings": {
				"clients": [
					{
						"id": "noobnetwork", // 填写你的 UUID
						"flow": "xtls-rprx-direct"
					}
				],
				"decryption": "none",
				"fallbacks": [
					{
						"dest": 443
					}
				]
			},
			"streamSettings": {
				"network": "tcp",
				"security": "xtls",
				"xtlsSettings": {
					"serverName": "$domain", // 填写服务器域名
					"alpn": [
						"h2",
						"http/1.1"
					],
					"certificates": [
						{
							"certificateFile": "/etc/letsencrypt/live/$domain/fullchain.pem",
							"keyFile": "/etc/letsencrypt/live/$domain/privkey.pem"
						}
					]
				}
			}
		}
	],
	"outbounds": [
		{
			"protocol": "freedom"
		}
	]
}
EOF

	sed -i 's/nobody/root/g' /etc/systemd/system/xray@.service
	echo -e ">>$green开启xray@xtls自启$none<<"
	systemctl enable xray@xtls.service
	echo -e ">>$green开启xray@xtls服务$none<<"
	systemctl start xray@xtls.service
	echo
	echo -e ">>$green安装完毕√$none<<"
	echo
	echo -e ">>$yellow是否需要SS协议$none<<"
	ss_comfirm
}

error() {

	echo -e "\n$red 已取消！$none\n"

}


####################
domain_input
