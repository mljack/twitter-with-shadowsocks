# Twitter with Shadowsocks

> 这是将 Twitter iOS 官方客户端集成 Shadowsocks 之后的版本，这个仓库提供的是自签名打包脚本，便于开发者使用自有证书签名后安装到未越狱 iOS 设备上；  
> 未越狱设备可以直接安装 http://fir.im/w3dk

## 使用前请注意

1. 重签名后导致部分 keychain 无法正常读写，目前简单的解决方案是在输入密码时在新的 keychain item 中记录您的密码，这样可以便于在进程杀死后不用再次输入密码验证，如对此有顾虑请慎用；  
* 这不是官方授权版本，仅供大家学习研究使用，请勿用于其他破坏性目的；

## 使用方法

下载仓库
````bash
git clone https://github.com/wsvn53/twitter-with-shadowsocks.git
````

执行 build.sh 脚本，并选择签名证书
````bash
  > ./build.sh
  
  Choose a certificate to codesign: 
  
  1) 6365A9A3C78******AEEF690B030F "iPhone Developer: SEN **** (732DWZ****)"
  2) 3B8469965C8******31EE1D7B13E8 "iPhone Developer: SEN **** (732DWZ****)"
  3) 1A479D9F8F6******E6E9288F244A "iPhone Distribution: SEN **** (4EJ7GY****)"
  
  > default(1): 3
  > codesign: 1A479D9F8F6******E6E9288F244A (4EJ7GY****)
  
  Check new version of Twitter.app with Shadowsocks...
  > detect Twitter.app version: 6.21
  > downloading http://wsvn.qiniudn.com/Twitter-6.21.ipa..
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spe Lef tSpeed
  100 32.1M  100 32.1M    0     0   204k      0  0:02:40  0:02:40   --:--:--  165k
  Archive:  ./tmp/Twitter-6.21.ipa
  
  Twitter.app/Shadowsocksable.framework: replacing existing signature
  Twitter.app/TwitterShadowsocks.framework: replacing existing signature
  Twitter.app: replacing existing signature
  Packaging application: 'Twitter.app'
  
  Done checking the original app
  + /usr/bin/zip --symlinks --verbose --recurse-paths ../twiter-with-shadowsocks/Twitter.ipa .
````

Ok，打包完成后，在本目录下 Twitter.ipa 就是使用自有证书签名的版本；

如果需要集成自己的 `embedded.mobileprovision`，请将你的 `embedded.mobileprovision` 复制到 Twitter.app/ 目录下并再次执行 `build.sh` 即可。