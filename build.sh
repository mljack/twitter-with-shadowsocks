#!/bin/bash
FIR_APPID=54dad1f5f6c9fcb66100007d
SELECTED=1

# 选择证书
CERT_LIST=$(security find-identity -v -p codesigning)
echo "Choose a certificate to codesign: "
echo ""
echo "$CERT_LIST" | grep -v "found"
echo ""
read -p "> default(1): " SELECTED

[ -z $SELECTED ] && { SELECTED=1; }
SELECTED_CERT=$(echo "$CERT_LIST" | head -n $SELECTED | tail -n1)
SELECTED_IDENTITY=$(echo "$SELECTED_CERT" | awk '{ print $2; }')
SELECTED_PREFIX=$(echo "$SELECTED_CERT" | awk -F'[()]' '{print $3}')
echo "> codesign: $SELECTED_IDENTITY ($SELECTED_PREFIX)"

[ ! -d ./tmp ] && {
    mkdir tmp;
}

echo ""
echo "Check new version of Twitter.app with Shadowsocks..."
APP_VER=$(curl -s http://fir.im/api/v2/app/version/54dad1f5f6c9fcb66100007d | \
    cut -d, -f2 | sed "s/\"//g" | cut -d: -f2)
echo "> detect Twitter.app version: $APP_VER"
if [[ ! -f ./tmp/Twitter-$APP_VER.ipa ]]; then
    IPA_URL=http://wsvn.qiniudn.com/Twitter-$APP_VER.ipa
    echo "> downloading $IPA_URL.."
    rm -rf Payload __MACOSX
    curl -o ./tmp/Twitter-$APP_VER.ipa $IPA_URL
    unzip ./tmp/Twitter-$APP_VER.ipa
    mv Payload/Twitter.app ./
    rm Twitter.app/embedded.mobileprovision
    rm -rf Payload __MACOSX
    echo ""
fi

sed "s/__PREFIX__/$SELECTED_PREFIX/g" Tweetie2.app.xcent.tmpl > Tweetie2.app.xcent
[ -d Twitter.app/Shadowsocksable.framework ] && {
    /usr/bin/codesign --verify --force --sign $SELECTED_IDENTITY Twitter.app/Shadowsocksable.framework;
}
[ -d Twitter.app/TwitterShadowsocks.framework ] && {
    /usr/bin/codesign --verify --force --sign $SELECTED_IDENTITY Twitter.app/TwitterShadowsocks.framework;
}
/usr/bin/codesign --verify --force --sign $SELECTED_IDENTITY --entitlements ./Tweetie2.app.xcent Twitter.app

xcrun -sdk iphoneos PackageApplication -v Twitter.app -o $PWD/Twitter.ipa
