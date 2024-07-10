安裝套件
1. httpd
2. xinetd
3. dhcpd
``` yum install httpd xinetd dhcpd```

DHCP建置

建置結構
/var/lib/tftpboot/images/
                        - ESXi_8.0U2_SR630
/var/lib/tftpboot/pxelinux.cfg/
/var/lib/tftpboot/ #放置圖形化引導菜單


建置結構   
chain.c32: 用於從其他引導裝載程序鏈接到 SYSLINUX，非常重要。
linux.c32: 用於引導 Linux kernel，在某些情況下可能需要。
localboot.c32: 用於本地磁盤引導。
mboot.c32: 用於引導 VMware ESXi，必須有。
menu.c32: 提供圖形化的引導菜單，非常有用。
vesamenu.c32: 提供更好的圖形化引導菜單，非常有用。
