![image](https://github.com/Jerrychanglab/ESXi-Kickstart-Deploy/assets/39659664/d31f729f-9ec0-4106-abc8-2cd30c62118d)安裝套件
1. httpd
2. xinetd
3. dhcpd
``` yum install httpd xinetd dhcpd```

## DHCP-建置
### 安裝套件
```yum install dhcp-server```
### SELIUNX 關閉
``` 
sed -i s'/enforcing/disabled/'g /etc/selinux/config
setenforce 0
```
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
### 安裝xinetd與tftp-server
```yum install xinetd tftp-server```
### 配置tftp
```
# 開啟創建文件
vim /etc/xinetd.d/tftp

# 內容貼上
service tftp
{
	socket_type		= dgram
	protocol		= udp
	wait			= yes
	user			= root
	server		= /usr/sbin/in.tftpd
	server_args		= -s /var/lib/tftpboot
	disable		= no
	per_source		= 11
	cps			= 100 2
	flags			= IPv4
}
```
### Wget抓取.c32
```wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz```
> 安裝syslinux，是需要裡面的.c32
### 結構階層規劃配置
#### /var/lib/tftpboot/bios/ 放置.c32檔案
#### /var/lib/tftpboot/images/ 放置ESXi ISO
#### /var/lib/tftpboot/pxelinux.cfg/ 放置圖型化引導菜單
### SOP1 創建資料夾
```
mkdir -p /var/lib/tftpboot/bios
mkdir -p /var/lib/tftpboot/images
mkdir -p /var/lib/tftpboot/pxelinux.cfg
```
### SOP2 .C32檔案抓取與移動
#### 2.1 抓取syslinux-6.03.tar.gz
```
cd /tmp
wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz
tar zxvf syslinux-6.03.tar.gz
```
#### 2.2 複製必要的.C32到指定路徑
```
cp /tmp/syslinux-6.03/bios/com32/chain/chain.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/modules/linux.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/samples/localboot.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/mboot/mboot.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/menu/menu.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/menu/vesamenu.c32 /var/lib/tftpboot/bios/
cp /tmp/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/
cp /tmp/syslinux-6.03/bios/core/pxelinux.0 /var/lib/tftpboot/
```
#### 2.3 .c32功能說明
- chain.c32: 用於從其他引導裝載程序鏈接到 SYSLINUX，非常重要。
- linux.c32: 用於引導 Linux kernel，在某些情況下可能需要。
- localboot.c32: 用於本地磁盤引導。
- mboot.c32: 用於引導 VMware ESXi，必須有。
- menu.c32: 提供圖形化的引導菜單，非常有用。
- vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。
### SOP3 建置ESXi安裝檔
#### 3.1 官網下載ESXI ISO (VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso)
#### 3.2 將ISO檔案丟到虛擬機器內
```
scp VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso user@ip:/tmp
mkdir -p /mnt/iso
mount -o loop /tmp/VMware-VMvisor-Installer-8.0U2-22380479.x86_64.iso /mnt/iso
mkdir -p /var/lib/tftpboot/images/ESXi_8.0U2
cp -r /mnt/iso/* /var/lib/tftpboot/images/ESXi_8.0U2
```
#### 3.3 設定boot.cfg (移除特殊符號)
```
sed -i s'/\///'g /var/lib/tftpboot/images/ESXi_8.0U2/boot.cfg
```
#### 3.4 開啟boot.cfg (文件修改內容)
```
# 開啟文件
vim /var/lib/tftpboot/images/ESXi_8.0U2/boot.cfg

# 調整內容
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
### SOP4 引導菜單-建置
#### 4.1 創建開機索引選單
```
# 創建與開啟文件
vim /var/lib/tftpboot/pxelinux.cfg/default

# 內容貼上
default vesamenu.c32 # 載入選項畫面
prompt 0 # 確認
timeout 600 # 等待時間60s
menu title ESXI PXE Install # 選單開頭

label local # Local硬碟開機
      MENU LABEL ^Boot from local drive
      localboot 0xffff

label ESXi_8.0U2 # 安裝選項
      KERNEL images/ESXi_8.0U2/mboot.c32
      APPEND images/ESXi_8.0U2/boot.cfg
      MENU LABEL ^Install ESXi 8.0U2

menu end

```
### SOP5 tftp服務啟動
```systemctl restart xinetd```
