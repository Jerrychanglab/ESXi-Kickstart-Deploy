# 描述:
![image](https://github.com/user-attachments/assets/eb563573-71c2-4915-8cbb-efa773996486)

## 備註: Kickstart建置在同一台虛擬機完成(DHCP+TFTP+HTTPD)
> 網段: 10.31.34.0/24

> IP: 10.31.34.9

> 網卡name: ifcfg-eth1
***
# 【 DHCP-建置 】
### SOP1 安裝套件
```yum install dhcp-server```
### SOP2 SELIUNX 關閉
``` 
sed -i s'/enforcing/disabled/'g /etc/selinux/config
setenforce 0
```
### SOP3 修改DHCP文件
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
### SOP4 指定DHCP配發網卡
vim /etc/sysconfig/dhcpd
```
DHCPDARGS=ifcfg-eth1 #新增，需看你要發放IP的網卡名稱
```
### SOP5 重啟服務
```systemctl restart dhcpd```
### SOP5.1 配發IP紀錄
```cat /var/lib/dhcpd/dhcpd.leases```
***
# 【 tftpboot-建置 】
### SOP1 安裝xinetd與tftp-server
```yum install xinetd tftp-server```
### SOP2 配置tftp (創建+貼上內容)
vim /etc/xinetd.d/tftp
```
service tftp
{
	socket_type		= dgram
	protocol		= udp
	wait			= yes
	user			= root
	server		        = /usr/sbin/in.tftpd
	server_args		= -s /var/lib/tftpboot
	disable		        = no
	per_source		= 11
	cps			= 100 2
	flags			= IPv4
}
```
> 安裝syslinux，是需要裡面的.c32
### 結構階層規劃配置
#### - /var/lib/tftpboot/ 放置.c32檔案
#### - /var/lib/tftpboot/images/ 放置ESXi ISO
#### - /var/lib/tftpboot/pxelinux.cfg/ 放置圖型化引導菜單
### SOP3 創建資料夾
```
mkdir -p /var/lib/tftpboot/bios
mkdir -p /var/lib/tftpboot/images
mkdir -p /var/lib/tftpboot/pxelinux.cfg
```
### SOP3 .C32檔案抓取與移動
#### 3.1 抓取syslinux-6.03.tar.gz
```
cd /tmp
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.05.tar.gz
tar zxvf syslinux-4.05.tar.gz
```
#### 3.2 複製必要的.C32到指定路徑
```
cp /tmp/syslinux-4.05/com32/samples/localboot.c32
cp /tmp/syslinux-4.05/com32/mboot/mboot.c32
cp /tmp/syslinux-4.05/com32/menu/menu.c32
cp /tmp/syslinux-4.05/core/pxelinux.0
cp /tmp/syslinux-4.05/com32/menu/vesamenu.c32
```
#### 3.3 元件功能說明
- localboot.c32: 用於本地磁盤引導。
- mboot.c32: 用於引導 VMware ESXi，必須有。
- menu.c32: 提供圖形化的引導菜單，非常有用。
- vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。
- pxelinux.0: PXE 引導程序，必須存在。
### SOP4 建置ESXi安裝檔
#### 4.1 官網下載ESXI ISO (VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso)
#### 4.2 將ISO檔案丟到虛擬機器內
```
scp VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso user@ip:/tmp
mkdir -p /mnt/iso
mount -o loop /tmp/VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso /mnt/iso
mkdir -p /var/lib/tftpboot/images/ESXi_8.0U2
cp -r /mnt/iso/* /var/lib/tftpboot/images/ESXi_8.0U2
```
#### 4.3 設定boot.cfg (移除特殊符號)
```
sed -i s'/\///'g /var/lib/tftpboot/images/ESXi_8.0U2/boot.cfg
```
#### 4.4 開啟boot.cfg (調整文件內容)
vim /var/lib/tftpboot/images/ESXi_8.0U2/boot.cfg
```
bootstate=0 
title=Loading ESXi installer
timeout=5
prefix=images/ESXi_8.0U2 # 指定放置ISO的位置
kernel=b.b00
kernelopt=ks=http://10.31.2.9/ks/ESXi_8.0U2.cfg # 指定http服務放置的文件設定檔
modules=jumpstrt.gz --- useropts.gz --- features.gz --- k.b00 --- uc_intel.b00 --- uc_amd.b00 --- uc_hygon.b00 --- procfs.b00 --- vmx.v00 --- vim.v00 --- tpm.v00 --- sb.v00 --- s.v00 --- atlantic.v00 --- bcm_mpi3.v00 --- bnxtnet.v00 --- bnxtroce.v00 --- brcmfcoe.v00 --- cndi_igc.v00 --- dwi2c.v00 --- elxiscsi.v00 --- elxnet.v00 --- i40en.v00 --- iavmd.v00 --- icen.v00 --- igbn.v00 --- intelgpi.v00 --- ionic_cl.v00 --- ionic_en.v00 --- irdman.v00 --- iser.v00 --- ixgben.v00 --- lpfc.v00 --- lpnic.v00 --- lsi_mr3.v00 --- lsi_msgp.v00 --- lsi_msgp.v01 --- lsi_msgp.v02 --- mtip32xx.v00 --- ne1000.v00 --- nenic.v00 --- nfnic.v00 --- nhpsa.v00 --- nipmi.v00 --- nmlx5_cc.v00 --- nmlx5_co.v00 --- nmlx5_rd.v00 --- ntg3.v00 --- nvme_pci.v00 --- nvmerdma.v00 --- nvmetcp.v00 --- nvmxnet3.v00 --- nvmxnet3.v01 --- pvscsi.v00 --- qcnic.v00 --- qedentv.v00 --- qedrntv.v00 --- qfle3.v00 --- qfle3f.v00 --- qfle3i.v00 --- qflge.v00 --- rdmahl.v00 --- rste.v00 --- sfvmk.v00 --- smartpqi.v00 --- vmkata.v00 --- vmksdhci.v00 --- vmkusb.v00 --- vmw_ahci.v00 --- bmcal.v00 --- clusters.v00 --- crx.v00 --- drivervm.v00 --- elx_esx_.v00 --- btldr.v00 --- esx_dvfi.v00 --- esx_ui.v00 --- esxupdt.v00 --- tpmesxup.v00 --- weaselin.v00 --- esxio_co.v00 --- infravis.v00 --- loadesx.v00 --- lsuv2_hp.v00 --- lsuv2_in.v00 --- lsuv2_ls.v00 --- lsuv2_nv.v00 --- lsuv2_oe.v00 --- lsuv2_oe.v01 --- lsuv2_sm.v00 --- native_m.v00 --- qlnative.v00 --- trx.v00 --- vdfs.v00 --- vds_vsip.v00 --- vmware_e.v00 --- hbrsrv.v00 --- vsan.v00 --- vsanheal.v00 --- vsanmgmt.v00 --- tools.t00 --- xorg.v00 --- gc.v00 --- imgdb.tgz --- basemisc.tgz --- resvibs.tgz --- esxiodpt.tgz --- imgpayld.tgz
build=8.0.2-0.0.22380479
updated=0
```
### SOP5 引導菜單-建置
#### 5.1 創建開機索引選單(創建+貼上內容)
vim /var/lib/tftpboot/pxelinux.cfg/default
```
# 載入選項畫面
default vesamenu.c32
# 確認
prompt 0
# 等待時間60s
timeout 600
# 選單開頭
menu title ESXI PXE Install
# Local硬碟開機
label local
      MENU LABEL ^Boot from local drive
      localboot 0xffff
# ESXi_8.0U2
label ESXi_8.0U2
      KERNEL images/ESXi_8.0U2/mboot.c32
      APPEND images/ESXi_8.0U2/boot.cfg
      MENU LABEL ^Install ESXi 8.0U2

menu end
```
### SOP6 tftp服務啟動
```systemctl restart xinetd```
***
# 【 建置HTTPD服務 】
### SOP1 安裝 httpd
```yum install httpd```
### SOP2 創建資料夾
```mkdir -p /var/www/html/ks```
### SOP3 建置.cfg文件 (創建+貼上)
vim ESXi_8.0U2.cfg
```
### == SOP 1 ==
## Accept the VMware End User License Agreement
accepteula

## The install Local disk
clearpart --alldrives --overwritevmfs
install --firstdisk=local --overwritevmfs --novmfsondisk

## Set the dhcp 
network --bootproto=dhcp --device=vmnic0

## Set root password
rootpw VMware1!

### == SOP 2 ==
##Enable shell command busybox
%firstboot --interpreter=busybox

## Enable SSH
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

## Enable ESXi Shell
vim-cmd hostsvc/enable_esx_shell
vim-cmd hostsvc/start_esx_shell

## License Key
vim-cmd vimsvc/license --set XXXXX-XXXXX-XXXXX-XXXXX-XXXXX

## IP Configure
CURRENT_IP=$(esxcli network ip interface ipv4 get | grep vmk0 | awk '{print $2}')
CURRENT_MASK=$(esxcli network ip interface ipv4 get | grep vmk0 | awk '{print $3}')
CURRENT_GATEWAY=$(esxcli network ip interface ipv4 get | grep vmk0 | awk '{print $6}')
esxcli network ip interface ipv4 set -i vmk0 -I $CURRENT_IP -N $CURRENT_MASK -t static
esxcli network ip route ipv4 add -n default -g $CURRENT_GATEWAY

## HostName
CURRENT_HOSTNAME=$(esxcli network ip interface ipv4 get | grep vmk0 | awk '{print $2}' | sed s'/\./-/'g)
esxcli system hostname set --host=ESXi-$CURRENT_HOSTNAME

#SNMP
esxcli system snmp set -c 'cyanyellowgreen168'
esxcli system snmp set -e true

#Coredump
#esxcli system coredump network set --interface-name 'vmk0' --server-ipv4 'IP' --server-port '6500'
#esxcli system coredump network set --enable true

#syslog
#esxcli system syslog config set --loghost='udp://IP:514'
#esxcli system syslog reload

## NTP two Server 
esxcli system ntp set --server=<IP> --server=<IP>
esxcli system ntp set --enabled=yes

## Power Type
esxcli system settings advanced set --option=/Power/CpuPolicy --string-value='High Performance'

# IPMITOOLS VIB 
esxcli software vib install -v http://10.31.2.9/vib/ipmitool.vib -f

# Mellanox VIB
esxcli software vib update -v http://10.31.2.9/vib/network/MEL_bootbank_nmlx5-core_4.21.71.101-1OEM.702.0.0.17630552.vib

# NetApp VAAI VIB
esxcli software vib install -v http://10.31.2.9/vib/netapp/NetApp_bootbank_NetAppNasPlugin_2.0.1-16.vib

## vSwitch0 配置
esxcli network vswitch standard uplink add -v 'vSwitch0' -u 'vmnic0'
esxcli network vswitch standard uplink add -v 'vSwitch0' -u 'vmnic1'
esxcli network vswitch standard portgroup policy failover set -a vmnic0,vmnic1 -p 'Management Network'
esxcli network vswitch standard portgroup policy failover set -p 'Management Network' -l 'iphash'
esxcli network vswitch standard policy failover set -v 'vSwitch0' -l 'iphash' -a 'vmnic0,vmnic1'
esxcli network vswitch standard portgroup add -v 'vSwitch0' -p 'vLan3102_10.31.2'
esxcli network vswitch standard portgroup set -p 'vLan3102_10.31.2' -v '3102'

## Reboot to complete host configuration
reboot

%end

```
### SOP4 httpd 服務啟動
```systemctl restart httpd```
***
# 【 Kickstart驗證 】

