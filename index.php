<?php

header('Content-Type:text/html;charset=utf-8');
ini_set('date.timezone', 'Asia/Shanghai');

define('WEBROOT', __DIR__);
require_once WEBROOT . '/vendor/autoload.php';

$right = add0(mt_rand(0, 9999), 4);

echo 'Line:11 ', getDT(1), '<br/>';
//echo Hello\SayHello::world();

/* 启用 爬虫文件缓存 */
$cfg_cache_enable = 1;
/* 爬虫文件缓存路径 */
$cfg_cache_path = WEBROOT . '/_temp/';
/* 爬虫目标网址 */
$cfg_target_domain1 = 'www.baidu.com';
$cfg_target_domain2 = 'cn.m.chahaoba.com';

use QL\QueryList;
use QL\Ext\DisguisePlugin;
use QL\Ext\AbsoluteUrl;
$_ql = QueryList::getInstance();
$_ql->use([
    DisguisePlugin::class,
    AbsoluteUrl::class
]);
$_ql_header1 = getHeader($cfg_target_domain1);
$_ql_header2 = getHeader($cfg_target_domain2);

$phone = '1311234';
echo "Line:34 {$phone}<br>";



/* 百度 */
//try{
    $data_list = $_ql->get("http://{$cfg_target_domain1}/s", ['ie' => 'utf-8', 'wd' => "{$phone}{$right}"], $_ql_header1);
    echo 'Line:41 ';print_r($_ql->disguise_headers);echo '<br>';
    if ($data_list->find('title')->text() == '百度安全验证') {
        exit('触发了百度安全验证');
    }
    $dataResult = $data_list->find('.c-span20.c-span-last>div:eq(0)')->text();
    echo 'Line:46 ';var_dump($dataResult);echo '<br>';
    if (!$dataResult) $dataResult = $data_list->find('.c-font-medium.c-color .c-line-clamp1 span')->text();
    echo 'Line:48 ';var_dump($dataResult);echo '<br>';
    //print_r($_ql->getHtml());
//} catch(Exception $e){
    //echo 'Line:51 ';print_r($e);
//}



/* 查号吧 */
//try{
    $data_list = $_ql->get("https://{$cfg_target_domain2}/{$phone}", [], $_ql_header2);
    echo 'Line:59 ';print_r($_ql->disguise_headers);echo '<br>';
    $dataResult = $data_list->find('#mw-content-text>.right:eq(0)>ul:eq(0)>li:eq(1)>a')->text();
    echo 'Line:61 ';var_dump($dataResult);echo '<br>';
//} catch(Exception $e){
    //echo 'Line:63 ';print_r($e);
//}




$_ql->destruct();


function getHeader($h){
    global $_ql, $cfg_cache_enable, $cfg_cache_path;
    /* 伪造浏览器请求头部信息 */
    $_ql->disguiseIp([
        'headers' => [
            //'Cookie' => 'abc=111;xxx=222',
            'Host' => $h,
            'Referer' => "http".($h=='cn.m.chahaoba.com'?'s':'')."://{$h}/",
            'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            'Accept-Encoding' => 'gzip, deflate, br',
            'Accept-Language' => 'en-US,en;q=0.9,zh-CN,zh;q=0.8;q=0.7',
            'Connection' => 'keep-alive'
        ]
    ]);
    $_ql->disguiseUa();
    $_tmp = $_ql->disguise_headers;
    /* 使用文件缓存驱动 */
    if($cfg_cache_enable){
        $_tmp['cache'] = $cfg_cache_path; /* 缓存文件夹路径 */
        $_tmp['cache_ttl'] = 3 * 24 * 60 * 60; /* 缓存有效时间，单位：秒。3天 */
    }
    return $_tmp;
}
function getDT($k = 0){
    $_d = new DateTime();
    $_v = $_d->format('U');
    if($k == 1) $_v = $_d->format('Y-m-d H:i:s');
    return $_v;
}
function add0($str, $len){
    $r = $str;
    for ($i = 0; $i < $len-strlen($str); $i++) {
        $r = "0{$r}";
    }
    return $r;
}
