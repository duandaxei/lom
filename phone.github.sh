#!/bin/bash

rootDir=$(dirname $(readlink -f "$0"))
logsDir="${rootDir}/py_logs"
htmlDir="${rootDir}/py_html"
logFile="${logsDir}/phone.$(date -d today +'%Y-%m-%d').log"
[[ ! -d "${logsDir}" ]] && (mkdir "${logsDir}")
[[ ! -d "${htmlDir}" ]] && (mkdir "${htmlDir}")
if ! type jq &>/dev/null; then
    sudo apt-get install jq
    sudo snap install jq
    #yum install jq
fi

gsd="-"
#phone=1540000
#phone=1560003
#phone=1311234
#phone=1455267

curlPhone () {
    curl -s -o "${htmlDir}/${phone}.get.html" -k -G -d "op=getOne" -d "tel=${phone}" "https://a.cdskdxyy.com/TM/API.PHP"
    myEcho "GSD 等待 20 秒"
    sleep 20
}

curlCHB () {
    if [[ ! -f "${htmlDir}/${phone}.html" ]]; then
        curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.100 Safari/537.36" \
            -H "Referer: https://cn.m.chahaoba.com/%E9%A6%96%E9%A1%B5" \
            -s -o "${htmlDir}/${phone}.html" -k \
            "https://cn.m.chahaoba.com/${phone}"
        myEcho "CHB https://cn.m.chahaoba.com/${phone} 等待 20 秒"
        sleep 20
    fi
}

getGsd () {
    curlCHB
    test_0=$(cat "${htmlDir}/${phone}.html")
    if [[ "${test_0}" ]]; then
        strFound=$(echo ${test_0} | grep "本站中目前没有找到${phone}页面。")
        str400=$(echo ${test_0} | grep "400 Bad Request")
        str502=$(echo ${test_0} | grep "502 Bad Gateway")
        str522=$(echo ${test_0} | grep "522 Origin Connection Time-out")
        str524=$(echo ${test_0} | grep "524 Origin Time-out")
        str525=$(echo ${test_0} | grep "525 Origin SSL Handshake Error")
        if [[ "${strFound}" ]]; then
            myEcho "未获取到号码【${phone}】归属地，可能号码格式错误"
        else
            if [[ "${str400}" ]]; then
                myEcho "未获取到号码【${phone}】归属地，查号吧 400 错误"
            else
                if [[ "${str502}" ]]; then
                    myEcho "未获取到号码【${phone}】归属地，查号吧 502 错误"
                else
                    if [[ "${str522}" ]]; then
                        myEcho "未获取到号码【${phone}】归属地，查号吧 522 错误"
                    else
                        if [[ "${str524}" ]]; then
                            myEcho "未获取到号码【${phone}】归属地，查号吧 524 错误"
                        else
                            if [[ "${str525}" ]]; then
                                myEcho "未获取到号码【${phone}】归属地，查号吧 525 错误"
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
                        fi
                    fi
                fi
            fi
        fi
    else
        myEcho "未获取到号码【${phone}】源码"
    fi
    myEcho "CHB https://cn.m.chahaoba.com/${phone} 等待 10 秒"
    sleep 10
    myEcho "获取到号码【${phone}】的归属地为【${gsd}】"
    if [[ "${gsd}" != "-" ]]; then
        doGsd "${gsd}"
    fi
}

provinceInBack () {
    province=(安徽 河北 山西 辽宁 吉林 黑龙江 江苏 浙江 福建 江西 山东 河南 湖北 湖南 广东 海南 四川 贵州 云南 陕西 甘肃 青海 台湾 内蒙古 广西 西藏 宁夏 新疆)
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
    curl -s -o "${htmlDir}/${phone}.do.html" -k -G -d "op=insert" -d "val=%7B%22tel%22:%22${phone}%22,%22gsd%22:%22${1}%22%7D" "https://a.cdskdxyy.com/TM/API.PHP"
    myEcho "GSD do 等待 20 秒"
    sleep 20
    strDone=$(cat "${htmlDir}/${phone}.do.html")
    myEcho "${strDone}"
    if [[ -n "${strDone}" ]]; then
        setNext "${phone}"
    fi
}

setNext () {
    rm -f "${htmlDir}/${1}.get.html"
    echo ${mob_next} >${mob_file}
}

myEcho () {
    st="$(date '+%Y-%m-%d %H:%M:%S') ${1}"
    echo "${st}"
    echo "${st}" >>${logFile}
}

goonGsd () {
    status=$(echo ${json} | jq ".status")
    msg=$(echo ${json} | jq ".msg")
    if [[ ${status} = '"bad"' ]]; then
        myEcho "bad"
        getGsd
    elif [[ ${status} = '"ok"' ]] && [[ ${msg} = '"-"' ]]; then
        myEcho "ok && -"
        getGsd
    else
        setNext "${1}"
    fi
}

mob_file="./phone.txt"
[[ ! -f ${mob_file} ]] && (echo 0 >${mob_file})
mob_left=15
mob_center=9
mob_right=$(cat "${mob_file}")
((mob_next=${mob_right}+1))
echo -e >>${logFile}
echo
phone=${mob_left}${mob_center}$(add0 "${mob_right}")
myEcho "开始操作号码 【${phone}】"
curlPhone
json=$(cat "${htmlDir}/${phone}.get.html")
myEcho "查询号码 【${phone}】，返回信息 ${json}"
if [[ -z "${json}" ]]; then
    myEcho "查询失败，10 秒后重新查询"
    sleep 10
    curlPhone
    json=$(cat "${htmlDir}/${phone}.get.html")
    myEcho "查询号码 【${phone}】，返回信息 ${json}"
    if [[ -z "${json}" ]]; then
        myEcho "查询失败，结束本次操作，期待下次成功~"
    else
        goonGsd "${phone}"
    fi
else
    goonGsd "${phone}"
fi
echo -e >>${logFile}
echo 
