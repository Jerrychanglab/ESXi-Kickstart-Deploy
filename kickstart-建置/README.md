安裝套件
1. httpd
2. xinetd
3. dhcpd
``` yum install httpd xinetd dhcpd```

## DHCP-建置
### 安裝套件
```yum install dhcpd```
### 修改DHCP文件
vim /etc/dhcp/dhcpd.conf
```
subnet 10.31.34.0 netmask 255.255.255.0 {       
range 10.31.34.11 10.31.34.250;   #配發網段範圍

# Gateway Allotment
option routers 10.31.34.254; 
option broadcast-address 10.31.34.255;  

# Lease Time
default-lease-time 31536000;  #DHCP租戶確認週期
max-lease-time 31536000;    #DHCP租戶保留週期

# Ping檢查
ping-check true;

# 轉導到Kickstart Server
filename "pxelinux.0";
next-server 10.31.34.9;     #指定轉跳到PXE Server
}
```
### 重啟服務
```systemctl restart dhcpd```
### 配發IP紀錄
```cat /var/lib/dhcpd/dhcpd.leases```

## tftpboot結構-建置
### 安裝套件
```yum install xinetd```
### 結構階層規劃配置
#### /var/lib/tftpboot/ 放置.c32檔案
#### /var/lib/tftpboot/images/ 放置ESXi ISO
#### /var/lib/tftpboot/pxelinux.cfg/ 放置圖型化引導菜單


建置結構   
chain.c32: 用於從其他引導裝載程序鏈接到 SYSLINUX，非常重要。
linux.c32: 用於引導 Linux kernel，在某些情況下可能需要。
localboot.c32: 用於本地磁盤引導。
mboot.c32: 用於引導 VMware ESXi，必須有。
menu.c32: 提供圖形化的引導菜單，非常有用。
vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。
