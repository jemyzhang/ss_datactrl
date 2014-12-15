Data control for ss
====

适用于supervisor控制的python shadowsocks

1. 配置

- 使用config.sh作为配置文件,具体内容如下:

```
CONFIG_FILE=/etc/shadowsocks.json  # shadowsocks的配置文件

DATA_CONFIG_DIR=/root/datactrl      # 端口/数据文件所在文件夹
PORTS_DIR=${DATA_CONFIG_DIR}/ports/ # 端口所在文件夹,文件中文件名以端口名称命名,具体配置内容参见ports/文件夹
DATA_DIR=${DATA_CONFIG_DIR}/data/
```

- 端口配置
```
enabled=1                   #是否启用该端口
limit_ctrl=1                #是否进行流量控制
data_limit=2000             #日流量大小控制,单位MB
valid_days=365              #有效期限
user_info=public            #用户信息,本打算实现email自动发送,暂未实现
send_report=0
```

2. 使用

- 开机自启动

使用`/root/reset_daily.sh 1`启动

- 监控

在crontab中,每隔较短时间执行一次check_daily.sh; 每日执行一次reset_daily.sh来实现流量检测和控制.

