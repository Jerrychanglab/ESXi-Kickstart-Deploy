安裝套件
1. httpd
2. xinetd
3. dhcpd
``` yum install httpd xinetd dhcpd```

## DHCP-建置
### 安裝套件
```yum install dhcp-server```
### 修改DHCP文件
vim /etc/dhcp/dhcpd.conf
```
subnet 10.31.34.0 netmask 255.255.255.0 {      #你的機器必須要有此腳
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
### 安裝xinetd
```yum install xinetd```
### Wget抓取
```wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz```
> 安裝syslinux，是需要裡面的.c32
### 結構階層規劃配置
#### /var/lib/tftpboot/bios/ 放置.c32檔案
#### /var/lib/tftpboot/images/ 放置ESXi ISO
#### /var/lib/tftpboot/pxelinux.cfg/ 放置圖型化引導菜單
### SOP1 創建資料夾
```
mkdir /var/lib/tftpboot/bios
mkdir /var/lib/tftpboot/images
mkdir /var/lib/tftpboot/pxelinux.cfg
```
### SOP2 抓取syslinux-6.03.tar.gz
```
cd /tmp
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar zxvf syslinux-6.03.tar.gz
```
### SOP2 複製必要的.C32到指定路徑
```
cp /tmp/syslinux-6.03/bios/com32/chain/chain.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/modules/linux.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/samples/localboot.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/mboot/mboot.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/menu/menu.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/menu/vesamenu.c32 /var/lib/tftpboot/bios/
```
#### .c32功能說明
- chain.c32: 用於從其他引導裝載程序鏈接到 SYSLINUX，非常重要。
- linux.c32: 用於引導 Linux kernel，在某些情況下可能需要。
- localboot.c32: 用於本地磁盤引導。
- mboot.c32: 用於引導 VMware ESXi，必須有。
- menu.c32: 提供圖形化的引導菜單，非常有用。
- vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。

建置結構   
chain.c32: 用於從其他引導裝載程序鏈接到 SYSLINUX，非常重要。
linux.c32: 用於引導 Linux kernel，在某些情況下可能需要。
localboot.c32: 用於本地磁盤引導。
mboot.c32: 用於引導 VMware ESXi，必須有。
menu.c32: 提供圖形化的引導菜單，非常有用。
vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。
