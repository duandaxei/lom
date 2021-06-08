#!/bin/sh

rootDir=$(dirname $(readlink -f "$0"))
logsDir="${rootDir}/py_logs"
logFile="${logsDir}/phone.$(date -d today +'%Y-%m-%d').log"
htmlDir="${rootDir}/py_html"
#if [[ ! -d "${logsDir}" ]]; then
#    mkdir "${logsDir}"
#fi
#if [[ ! -d "${htmlDir}" ]]; then
#    mkdir "${htmlDir}"
#fi
[[ ! -d "${logsDir}" ]] && (mkdir "${logsDir}")
[[ ! -d "${htmlDir}" ]] && (mkdir "${htmlDir}")


gsd='-'
#phone=1540000
#phone=1560003
#phone=1311234
#phone=1455267

getGsd () {
    if [[ ! -f "${htmlDir}/${1}.html" ]]; then
        curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36" \
            -H "Referer: https://cn.m.chahaoba.com/%E9%A6%96%E9%A1%B5" \
            -s -o "${htmlDir}/${1}.html" -k \
            "https://cn.m.chahaoba.com/${1}"
        myEcho "CHB https://cn.m.chahaoba.com/${1} 等待 20 秒"
        sleep 20
    fi
    test_0=$(cat ${htmlDir}/${1}.html)
    if [[ "${test_0}" ]]; then
        strFound=$(echo ${test_0} | grep "本站中目前没有找到${1}页面。")
        if [[ "${strFound}" ]]; then
            myEcho "未获取到号码【${1}】归属地，可能号码格式错误"
        else
            test_1=$(echo ${test_0} | sed -r 's/.*归属省份地区：(.*)<\/li> <li> 电信运营商：.*/\1/g')
            if [[ "${test_1}" ]]; then
                strF2=$(echo ${test_1} | grep "、")
                if [[ "${strF2}" == "" ]]; then
                    test_2=$(echo ${test_1} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                    gsd="${test_2}-${test_2}"
                else
                    #arr=(`echo ${test_1} | tr ' ' '#' | tr '、' ' '`)
                    res=()
                    oldIFS=$IFS
                    IFS=、
                    arr=(${test_1})
                    for ((i=0; i<${#arr[@]}; i++)); do
                        res[i]=$(echo ${arr[$i]} | sed -r 's/<a href=".*" class="extiw" title="link:.*">(.*)<\/a>/\1/g')
                    done
                    IFS=$oldIFS
                    gsd="${res[0]}-${res[1]}"
                    if [[ "${res[1]}" != "重庆" ]]; then
                        if [[ "${gsd}" != "青海-海南" ]] && [[ "${gsd}" != "吉林-吉林" ]] && [[ $(provinceInBack "${res[1]}") == "1" ]]; then
                            gsd="${res[1]}-${res[0]}"
                        fi
                    else
                        gsd="${res[1]}-${res[0]}"
                    fi
                fi
            fi
        fi
    else
        myEcho "未获取到号码【${1}】源码"
    fi
    myEcho "获取到号码【${1}】的归属地为【${gsd}】"
    doGsd "${1}" "${gsd}"
}

provinceInBack () {
    province=(
        安徽
        河北
        山西
        辽宁
        吉林
        黑龙江
        江苏
        浙江
        福建
        江西
        山东
        河南
        湖北
        湖南
        广东
        海南
        四川
        贵州
        云南
        陕西
        甘肃
        青海
        台湾
        内蒙古
        广西
        西藏
        宁夏
        新疆
    )
    if [[ "${province[@]}" =~ "${1}" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

add0 () {
    num=${1}
    for ((i=0; i<(4-${#1}); i++)); do
        num="0${num}"
    done
    echo "${num}"
}

doGsd () {
    curl -s -o "${htmlDir}/${1}.do.html" -k -G -d "op=insert" -d "val=%7B%22tel%22:%22${1}%22,%22gsd%22:%22${2}%22%7D" "https://a.cdskdxyy.com/TM/API.PHP"
    myEcho "GSD do 等待 20 秒"
    sleep 20
    myEcho $(cat "${htmlDir}/${1}.do.html")
    #((numMin=15*60))
    #((numMax=20*60))
    #numRand=$[$RANDOM%$((numMax-numMin+1))+${numMin}]
    #myEcho "GSD done 等待 ${numRand} 秒"
    #timeNext=$(date --date="${numRand} second" '+%Y-%m-%d %H:%M:%S')
    #myEcho "下次操作: ${timeNext}"
    rm -f "${htmlDir}/${phone}.get.html"
    #sleep ${numRand}
}

myEcho () {
    echo ${1}
    echo $(date '+%Y-%m-%d %H:%M:%S') ${1} >>${logFile}
}

mob_file="./phone.txt"
[[ ! -f ${mob_file} ]] && (echo 0 >${mob_file})
mob_left=15
mob_center=9
mob_right=$(cat ${mob_file})
((mob_next=${mob_right}+1))
echo ${mob_next} >${mob_file}
phone=${mob_left}${mob_center}$(add0 "${mob_right}")
myEcho "开始操作号码 【${phone}】"
if [[ ! -f "${htmlDir}/${phone}.get.html" ]]; then
    curl -s -o "${htmlDir}/${phone}.get.html" -k -G -d "op=getOne" -d "tel=${phone}" "https://a.cdskdxyy.com/TM/API.PHP"
    myEcho "GSD 等待 20 秒"
    sleep 20
fi
if ! type jq &>/dev/null; then
    sudo apt-get install jq
    #yum install jq
    #apk --no-cache add -f jq
fi
json=$(cat "${htmlDir}/${phone}.get.html")
status=$(echo ${json} | jq ".status")
msg=$(echo ${json} | jq ".msg")
myEcho "查询号码 【${phone}】，返回信息 ${json}"
if [[ ${status} = '"bad"' ]]; then
    myEcho "bad"
    getGsd "${phone}"
elif [[ ${status} = '"ok"' ]] && [[ ${msg} = '"-"' ]]; then
    myEcho "ok && -"
    getGsd "${phone}"
fi
echo -e >>${logFile}

