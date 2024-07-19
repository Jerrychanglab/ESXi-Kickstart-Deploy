#!/bin/bash

function login () {
    read -p "Password:" -s pw
    echo ""
}

login

# 需要更新的固件ID列表
firmware_list=(
    "lnvgy_fw_xcc_cdi3b2z-9.95_anyos_noarch"
    "lnvgy_fw_lxpm_pdl148a-2.11_anyos_noarch"
    "lnvgy_fw_drvln_pdl248f-2.11_anyos_noarch"
    "lnvgy_fw_drvwn_pdl348e-2.11_anyos_noarch"
    "lnvgy_fw_bootstor_sata-2.3.10.1103-0_anyos_noarch"
    "mlnx-lnvgy_fw_nic_cx-5.7-1.0.2.0-8_linux_x86-64"
)

# UEFI固件的更新順序
uefi_firmware_list=(
    "lnvgy_fw_uefi_ive172f-3.00_anyos_32-64"
    "lnvgy_fw_uefi_ive178i-3.31_anyos_32-64"
    "lnvgy_fw_uefi_ive184e-4.12_anyos_32-64"
)

# 檢查是否需要更新
check_update_needed() {
    local firmware_id=$1
    local x=$2
    result=$(onecli update flash --noreboot -b USERID:${pw}@${x} --dir $firmware_dir --includeid $firmware_id 2>&1)
    echo "$result"
    if echo "$result" | grep -q "No package needs update."; then
        return 1
    elif echo "$result" | grep -q "Reboot Required to take effect"; then
        return 2
    else
        return 0
    fi
}

# 執行更新
update_firmware() {
    local firmware_id=$1
    local x=$2
    echo "Starting firmware update for $firmware_id on $x..."
    onecli update flash --noreboot -b USERID:${pw}@${x} --dir $firmware_dir --includeid $firmware_id
}

# 更新並重試的函數
update_firmware_with_retry() {
    local firmware_id=$1
    local x=$2
    max_attempts=3
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        check_update_needed $firmware_id $x
        result=$?
        if [ $result -eq 1 ]; then
            echo "No update needed for $firmware_id on $x, exiting."
            return 1
        elif [ $result -eq 2 ]; then
            echo "Update completed for $firmware_id on $x with reboot required."
            return 2
        fi
        update_firmware $firmware_id $x
        if [ $? -eq 0 ]; then
            echo "Firmware update for $firmware_id on $x succeeded."
            return 0
        fi
        attempt=$((attempt+1))
        echo "Retry attempt $attempt of $max_attempts for $firmware_id on $x..."
        sleep 10
    done

    if [ $attempt -gt $max_attempts ]; then
        echo "Failed to update firmware $firmware_id on $x after $max_attempts attempts."
        return 3
    fi
}

# 固件目錄
firmware_dir="/var/www/html/firmware/lenovo/"

# 循環處理每個服務器
for x in `cat /home/sys-admin/hcl/lenovo_list`
do
    # 還原UEFI
    onecli config loaddefault UEFI -b USERID:${pw}@${x}
    onecli misc ospower reboot -b USERID:${pw}@${x}
    sleep 600

    # 先更新其他固件
    for firmware_id in "${firmware_list[@]}"; do
        update_firmware_with_retry $firmware_id $x
        if [ "$firmware_id" == "lnvgy_fw_xcc_cdi3b2z-9.95_anyos_noarch" ]; then
            # XCC固件更新後重啟BMC
            onecli misc rebootbmc -b USERID:${pw}@${x}
            # 等待BMC重啟完成
            sleep 120
        fi
    done

    # 更新UEFI固件，考慮升級順序
    for uefi_id in "${uefi_firmware_list[@]}"; do
        update_firmware_with_retry $uefi_id $x
        if [ $? -eq 2 ]; then
            # 更新後重啟機器
            onecli misc ospower reboot -b USERID:${pw}@${x}
            # 等待重啟完成
            sleep 1200
        fi
    done

    # 設定硬體參數
    onecli config set IMM.PowerRestorePolicy "Restore" -b USERID:${pw}@${x}
    onecli config set OperatingModes.ChooseOperatingMode "Custom Mode" -b USERID:${pw}@${x}
    onecli config set Processors.HyperThreading "Enable" -b USERID:${pw}@${x}
    onecli config set Processors.EnergyEfficientTurbo "Disable" -b USERID:${pw}@${x}
    onecli config set Memory.MemorySpeed "Max Performance" -b USERID:${pw}@${x}
    onecli config set Processors.TurboMode "Enable" -b USERID:${pw}@${x}
    onecli config set Processors.CStates "Disable" -b USERID:${pw}@${x}
    onecli config set Processors.C1EnhancedMode "Disable" -b USERID:${pw}@${x}
    onecli misc ospower reboot -b USERID:${pw}@${x}

done
