#!/usr/bin/env bash

set -e
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"
TMATE_SOCK="/tmp/tmate.sock"
TELEGRAM_LOG="/tmp/telegram.log"
CONTINUE_FILE="/tmp/continue"

# Install tmate on macOS or Ubuntu
echo -e "${INFO} Setting up tmate ..."
if [[ -n "$(uname | grep Linux)" ]]; then
    curl -fsSL git.io/tmate.sh | bash
elif [[ -x "$(command -v brew)" ]]; then
    brew install tmate
else
    echo -e "${ERROR} This system is not supported!"
    exit 1
fi

# Generate ssh key if needed
[[ -e ~/.ssh/id_rsa ]] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""

# Run deamonized tmate
echo -e "${INFO} Running tmate..."
tmate -S ${TMATE_SOCK} new-session -d
tmate -S ${TMATE_SOCK} wait tmate-ready

# Print connection info
TMATE_SSH=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_ssh}')
TMATE_WEB=$(tmate -S ${TMATE_SOCK} display -p '#{tmate_web}')
MSG="
*GitHub Actions - tmate session info:*

⚡ *CLI:*
\`${TMATE_SSH}\`

🔗 *URL:*
${TMATE_WEB}

🔔 *TIPS:*
Run '\`touch ${CONTINUE_FILE}\`' to continue to the next step.
"

if [[ -n "${TELEGRAM_BOT_TOKEN}" && -n "${TELEGRAM_CHAT_ID}" ]]; then
    echo -e "${INFO} Sending message to Telegram..."
    curl -sSX POST "${TELEGRAM_API_URL:-https://api.telegram.org}/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=Markdown" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${MSG}" >${TELEGRAM_LOG}
    TELEGRAM_STATUS=$(cat ${TELEGRAM_LOG} | jq -r .ok)
    if [[ ${TELEGRAM_STATUS} != true ]]; then
        echo -e "${ERROR} Telegram message sending failed: $(cat ${TELEGRAM_LOG})"
    else
        echo -e "${INFO} Telegram message sent successfully!"
    fi
fi

while ((${PRT_COUNT:=1} <= ${PRT_TOTAL:=10})); do
    SECONDS_LEFT=${PRT_INTERVAL_SEC:=10}
    while ((${PRT_COUNT} > 1)) && ((${SECONDS_LEFT} > 0)); do
        echo -e "${INFO} (${PRT_COUNT}/${PRT_TOTAL}) Please wait ${SECONDS_LEFT}s ..."
        sleep 1
        SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
    done
    echo "-----------------------------------------------------------------------------------"
    echo "To connect to this session copy and paste the following into a terminal or browser:"
    echo -e "CLI: ${Green_font_prefix}${TMATE_SSH}${Font_color_suffix}"
    echo -e "URL: ${Green_font_prefix}${TMATE_WEB}${Font_color_suffix}"
    echo -e "TIPS: Run 'touch ${CONTINUE_FILE}' to continue to the next step."
    echo "-----------------------------------------------------------------------------------"
    PRT_COUNT=$((${PRT_COUNT} + 1))
done

while [[ -S ${TMATE_SOCK} ]]; do
    sleep 1
    if [[ -e ${CONTINUE_FILE} ]]; then
        echo -e "${INFO} Continue to the next step."
        exit 0
    fi
done



2、tmate-ubuntu.yml文件

shell 代码解读复制代码name: 'tmate-ubuntu'

on:
  workflow_dispatch:
    inputs:
      mode:
        description: 'Choose tmate or ngrok mode'
        required: false
        default: 'tmate'

jobs:
  ssh-debug:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2  # 检出你的代码仓库

      - name: Choose mode tmate (ubuntu)
        run: |
          MODE=${{ github.event.inputs.mode }}
          bash ./${MODE}2actions.sh  # 使用相对路径执行脚本
        shell: bash
        
      - name: Sleep
        run: sleep 6h


3、tmate-macos.yml文件

shell 代码解读复制代码name: 'tmate-macos'

on:
  workflow_dispatch:
    inputs:
      mode:
        description: 'Choose tmate or ngrok mode'
        required: false
        default: 'tmate'

jobs:
  ssh-debug:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2  # 检出你的代码仓库

      - name: Choose mode tmate (macos)
        run: |
          MODE=${{ github.event.inputs.mode }}
          bash ./${MODE}2actions.sh  # 使用相对路径执行脚本
        shell: bash
        
      - name: Sleep
        run: sleep 6h

三、通过ngrok安装GitHub Actions VM (SSH免费连接VM服务器Ubuntu、macOS)
前提配置github变量 NGROK_TOKEN
在当前项目找到 Settings -> Secrets and variables -> Actions -> Repository secrets -> 然后点New repository secret创建变量 填下ngrok的Authtoken值
上面ngrok注册成功后看到的信息 代码解读复制代码- 注册成功后查看Authtoken地址，复制token下来就可以
https://dashboard.ngrok.com/get-started/your-authtoken

前提配置github变量 SSH_PASSWORD
在当前项目找到 Settings -> Secrets and variables -> Actions -> Repository secrets -> 然后点New repository secret创建变量 填到时要登录服务器的密码

1、ngrok2actions.sh

shell 代码解读复制代码#!/usr/bin/env bash

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"
LOG_FILE='/tmp/ngrok.log'
TELEGRAM_LOG="/tmp/telegram.log"
CONTINUE_FILE="/tmp/continue"

if [[ -z "${NGROK_TOKEN}" ]]; then
    echo -e "${ERROR} Please set 'NGROK_TOKEN' environment variable."
    exit 2
fi

if [[ -z "${SSH_PASSWORD}" && -z "${SSH_PUBKEY}" && -z "${GH_SSH_PUBKEY}" ]]; then
    echo -e "${ERROR} Please set 'SSH_PASSWORD' environment variable."
    exit 3
fi

if [[ -n "$(uname | grep -i Linux)" ]]; then
    echo -e "${INFO} Install ngrok ..."
    curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -o ngrok.zip
    unzip ngrok.zip ngrok
    rm ngrok.zip
    chmod +x ngrok
    sudo mv ngrok /usr/local/bin
    ngrok -v
elif [[ -n "$(uname | grep -i Darwin)" ]]; then
    echo -e "${INFO} Install ngrok ..."
    curl -fsSL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip -o ngrok.zip
    unzip ngrok.zip ngrok
    rm ngrok.zip
    chmod +x ngrok
    sudo mv ngrok /usr/local/bin
    ngrok -v
    USER=root
    echo -e "${INFO} Set SSH service ..."
    echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
else
    echo -e "${ERROR} This system is not supported!"
    exit 1
fi

if [[ -n "${SSH_PASSWORD}" ]]; then
    echo -e "${INFO} Set user(${USER}) password ..."
    echo -e "${SSH_PASSWORD}\n${SSH_PASSWORD}" | sudo passwd "${USER}"
fi

echo -e "${INFO} Start ngrok proxy for SSH port..."
screen -dmS ngrok \
    ngrok tcp 22 \
    --log "${LOG_FILE}" \
    --authtoken "${NGROK_TOKEN}" \
    --region "${NGROK_REGION:-us}"

while ((${SECONDS_LEFT:=10} > 0)); do
    echo -e "${INFO} Please wait ${SECONDS_LEFT}s ..."
    sleep 1
    SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
done

ERRORS_LOG=$(grep "command failed" ${LOG_FILE})

if [[ -e "${LOG_FILE}" && -z "${ERRORS_LOG}" ]]; then
    SSH_CMD="$(grep -oE "tcp://(.+)" ${LOG_FILE} | sed "s/tcp:\/\//ssh ${USER}@/" | sed "s/:/ -p /")"
    MSG="
*GitHub Actions - ngrok session info:*

⚡ *CLI:*
\`${SSH_CMD}\`

🔔 *TIPS:*
Run '\`touch ${CONTINUE_FILE}\`' to continue to the next step.
"
    if [[ -n "${TELEGRAM_BOT_TOKEN}" && -n "${TELEGRAM_CHAT_ID}" ]]; then
        echo -e "${INFO} Sending message to Telegram..."
        curl -sSX POST "${TELEGRAM_API_URL:-https://api.telegram.org}/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "disable_web_page_preview=true" \
            -d "parse_mode=Markdown" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=${MSG}" >${TELEGRAM_LOG}
        TELEGRAM_STATUS=$(cat ${TELEGRAM_LOG} | jq -r .ok)
        if [[ ${TELEGRAM_STATUS} != true ]]; then
            echo -e "${ERROR} Telegram message sending failed: $(cat ${TELEGRAM_LOG})"
        else
            echo -e "${INFO} Telegram message sent successfully!"
        fi
    fi
    while ((${PRT_COUNT:=1} <= ${PRT_TOTAL:=10})); do
        SECONDS_LEFT=${PRT_INTERVAL_SEC:=10}
        while ((${PRT_COUNT} > 1)) && ((${SECONDS_LEFT} > 0)); do
            echo -e "${INFO} (${PRT_COUNT}/${PRT_TOTAL}) Please wait ${SECONDS_LEFT}s ..."
            sleep 1
            SECONDS_LEFT=$((${SECONDS_LEFT} - 1))
        done
        echo "------------------------------------------------------------------------"
        echo "To connect to this session copy and paste the following into a terminal:"
        echo -e "${Green_font_prefix}$SSH_CMD${Font_color_suffix}"
        echo -e "TIPS: Run 'touch ${CONTINUE_FILE}' to continue to the next step."
        echo "------------------------------------------------------------------------"
        PRT_COUNT=$((${PRT_COUNT} + 1))
    done
else
    echo "${ERRORS_LOG}"
    exit 4
fi

while [[ -n $(ps aux | grep ngrok) ]]; do
    sleep 1
    if [[ -e ${CONTINUE_FILE} ]]; then
        echo -e "${INFO} Continue to the next step."
        exit 0
    fi
done




2、ngrok-ubuntu.yml文件

shell 代码解读复制代码name: 'ngrok-ubuntu'

on:
  workflow_dispatch:
    inputs:
      mode:
        description: 'Choose tmate or ngrok mode'
        required: false
        default: 'ngrok'

jobs:
  ssh-debug:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2  # 检出你的代码仓库

      - name: Choose mode ngrok (ubuntu)
        env:
          NGROK_TOKEN: ${{ secrets.NGROK_TOKEN }} 
          SSH_PASSWORD: ${{ secrets.SSH_PASSWORD }}
        run: |
          MODE=${{ github.event.inputs.mode }}
          bash ./${MODE}2actions.sh  # 使用相对路径执行脚本
        shell: bash
        
      - name: Sleep
        run: sleep 6h


3、ngrok-macos.yml文件

shell 代码解读复制代码name: 'ngrok-macos'

on:
  workflow_dispatch:
    inputs:
      mode:
        description: 'Choose tmate or ngrok mode'
        required: false
        default: 'ngrok'

jobs:
  ssh-debug:
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2  # 检出你的代码仓库

      - name: Choose mode ngrok (macos)
        env:
          NGROK_TOKEN: ${{ secrets.NGROK_TOKEN }} 
          SSH_PASSWORD: ${{ secrets.SSH_PASSWORD }}
        run: |
          MODE=${{ github.event.inputs.mode }}
          bash ./${MODE}2actions.sh  # 使用相对路径执行脚本
        shell: bash
        
      - name: Sleep
        run: sleep 6h



相同系统的两个yml文件可以部署一个就可以,因为运行时可以输入参数选择tmate还是ngrok运行的

四、通过ngrok安装GitHub Actions VM (RDP免费连接VM服务器windows)
前提配置github变量 NGROK_TOKEN
在当前项目找到 Settings -> Secrets and variables -> Actions -> Repository secrets -> 然后点New repository secret创建变量 填下ngrok的Authtoken值
上面ngrok注册成功后看到的信息 代码解读复制代码- 注册成功后查看Authtoken地址，复制token下来就可以
https://dashboard.ngrok.com/get-started/your-authtoken

前提配置github变量 SSH_PASSWORD
在当前项目找到 Settings -> Secrets and variables -> Actions -> Repository secrets -> 然后点New repository secret创建变量 填到时要登录服务器的密码

1、ngrok-windows.yml文件

shell 代码解读复制代码name: ngrok-windows

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: windows-latest
    steps:
    - name: Download ngrok
      run: Invoke-WebRequest https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -OutFile ngrok.zip
    - name: Extract ngrok
      run: Expand-Archive ngrok.zip
    - name: Authenticate with ngrok
      run: .\ngrok\ngrok.exe authtoken $Env:NGROK_TOKEN
      env:
        NGROK_TOKEN: ${{ secrets.NGROK_TOKEN }} 
    - name: Enable Remote Desktop
      run: |
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
        Set-LocalUser -Name "runneradmin" -Password (ConvertTo-SecureString -AsPlainText $Env:SSH_PASSWORD -Force)
      env:
        SSH_PASSWORD: ${{ secrets.SSH_PASSWORD }}
    - name: Create ngrok tunnel to remote desktop
      run: .\ngrok\ngrok.exe tcp 3389


[点击观看视频教程]
   标签： GitHub运维云计算   评论 0           0 / 1000 
        标点符号、链接等不计算在有效字数内
       
        Ctrl + Enter
      
              发送
             登录 / 注册 即可发布评论！      暂无评论数据      点赞  评论  
            收藏
           

作者：AM科技
链接：https://juejin.cn/post/7462571241742024730
来源：稀土掘金
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。
