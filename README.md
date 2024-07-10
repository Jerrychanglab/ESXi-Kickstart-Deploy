# ESXi-Kickstart-Deploy

![image](https://github.com/Jerrychanglab/ESXi-Kickstart-Deploy/assets/39659664/256500b8-ce67-45b8-a462-4f4f4d6ec860)
# Kickstart 概述
Kickstart 是一種用於自動化系統安裝和配置的工具，通常用於大規模部署環境中。它允許管理員通過預先定義的配置文件來自動化操作系統的安裝過程，減少了手動干預和配置錯誤，目的是自動化安裝和配置過程，包括操作系統的安裝、網絡配置、系統參數設置以及補丁安裝。這樣可以確保每次安裝都遵循相同的標準和配置，提升部署效率和一致性。

## ESXi 安裝流程

### PXE 引導
使用 PXE (Preboot Execution Environment) 進行網絡引導，啟動 Kickstart 安裝過程。

### ESXi 安裝
自動化安裝 VMware ESXi，使用預定義的 Kickstart 文件進行安裝過程。

### IP 配置
安裝過程中自動配置 ESXi 主機的 IP 地址，確保網絡連接的正常運行。

### 參數配置
配置 ESXi 的系統參數，包括管理網絡設置、安全設置等。

### 補丁安裝
在安裝完成後，自動應用最新的 ESXi 補丁，確保系統處於最新和最安全的狀態。

### IPMI 配置
自動化配置 IPMI (Intelligent Platform Management Interface) 設置，便於遠程管理和監控伺服器硬件狀態。

# HCL 概述
硬體兼容性列表 (Hardware Compatibility List, HCL) 是一個列出經過驗證的硬體和軟體組合的清單，確保這些組合能夠在特定的操作系統或應用環境中穩定運行。HCL 在部署企業級應用時尤為重要，因為它可以幫助避免硬體和軟體之間的兼容性問題。

## 硬體更新流程

### BMC 更新
自動化更新 BMC (Baseboard Management Controller) 固件，確保遠程管理和監控功能的穩定性和安全性。

### LXPM 更新
更新 Lenovo XClarity Provisioning Manager (LXPM) 相關固件，提升系統管理功能和性能。

### M.2 更新
更新 M.2 硬盤的固件，確保存儲性能和穩定性。

### 網卡更新
更新網絡接口卡的固件，提升網絡性能和穩定性。

## UEFI 參數設置

### 電力規則設置
配置電力管理規則，優化伺服器的電源使用效率。

### HT (超執行緒) 開啟
啟用或禁用超執行緒 (Hyper-Threading) 技術，根據工作負載需求調整處理器性能。

### C 狀態調整
調整處理器 C 狀態，優化功耗與性能的平衡。

### 性能最大化設置
配置系統參數以最大化伺服器性能，適應高性能計算需求。
