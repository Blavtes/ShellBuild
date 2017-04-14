#!/bin/bash
# author Blavtes

# 工程名
SCHEMENAME=GjFax 
BRANCHNAME=develop

# $1表示传入的第一个参数，启动脚本传入Debug或者Release就可以
# 如：sh build.sh Debug

MODE=$1
serverType=1

#svn 更新

svn update
if [ $? -ne 0 ]; then
	echo "svn up faild!!!"
	exit 1
fi

if [ $MODE = "Release" ]; then
	# 删除pod
	rm -rf Podfile.lock
	if [ $? -ne 0 ]; then
		echo "delete Podfile.lock faild!!!"
		exit 1
	fi
	rm  -rf Pods
	if [ $? -ne 0 ]; then
		echo "delete Pods faild!!!"
		exit 1
	fi
	rm -rf $SCHEMENAME.xcworkspace
	if [ $? -ne 0 ]; then
		echo "delete xcworkspace faild!!!"
		exit 1
	fi
	#pod update --verbose --no-repo-update
	pod install
	if [ $? -ne 0 ]; then
		echo "pod update faild!!!"
		exit 1
	fi
fi

echo "code update Successful"

echo "\n\n\nbegin build it.......\n\n"

# $serverType是启动脚本传入的参数值  TestDebug 为新增加的model
if [ $MODE = "TestDebug" ]; then    
	PREPROCESSOR_DEFINITIONS="COCOAPODS=1 TestDebug=$serverType DEBUG=1" 
	echo "config " + $PREPROCESSOR_DEFINITIONS
fi


DATE=`date +%Y%m%d_%H%M`
SOURCEPATH=$( cd "$( dirname $0 )" && pwd)
IPAPATH=/Users/`whoami`/Documents/AutoBuildIPA/$BRANCHNAME/$MODE/$DATE
IPANAME=$SCHEMENAME_$DATE.ipa

echo "cp hostSetting file...."

HostFile=/Users/`whoami`/Documents/AutoBuildIPA/HostSetting.h
echo "host " + $HostFile
if [ -f $HostFile ]; then 
	 
 	echo "have Host File to Build mk...."
else
	cp -r /$SOURCEPATH/HX_GJS/Classes/BaseFrame/Networking/HostSetting.txt $HostFile
	if [ $? -ne 0 ]; then
		echo "cp back-up  txt->HostSetting.h faild!!!"
		exit 1
	fi
	cp -r /$SOURCEPATH/HX_GJS/Classes/BaseFrame/Networking/HostSetting.h /Users/`whoami`/Documents/AutoBuildIPA/HostSetting.txt
	if [ $? -ne 0 ]; then
		echo "cp back-up  HostSetting.h->txt faild!!!"
		exit 1
	fi
	echo "copy Host File to Build mk...."
fi

cp -r $HostFile /$SOURCEPATH/HX_GJS/Classes/BaseFrame/Networking/HostSetting.h

if [ $? -ne 0 ]; then
		echo "cp  HostSetting.h faild!!!"
		exit 1
fi

echo "path : " + $IPAPATH

if [ $MODE = "Release" ]; then
	#statements
	xcodebuild \
	-workspace $SOURCEPATH/$SCHEMENAME.xcworkspace \
	-scheme $SCHEMENAME \
	-configuration $MODE \
	CODE_SIGN_IDENTITY="iPhone Developer: rui zhang (HK36TJZ8XU)" \
	PROVISIONING_PROFILE="cd4f0784-efcc-4a4e-b9f8-3400eef49b99" \
	clean \
	build \
	-derivedDataPath $IPAPATH

	if	[ -e $IPAPATH ]; then
		echo "xcodebuild Successful"
	else
		echo "error:Build faild!!"
		exit 1
	fi
elif [ $MODE = "Debug" ]; then
		xcodebuild \
	-workspace $SOURCEPATH/$SCHEMENAME.xcworkspace \
	-scheme $SCHEMENAME \
	-configuration $MODE \
	CODE_SIGN_IDENTITY="iPhone Developer: rui zhang (HK36TJZ8XU)" \
	PROVISIONING_PROFILE="cd4f0784-efcc-4a4e-b9f8-3400eef49b99" \
	clean \
	build \
	-derivedDataPath $IPAPATH

	if	[ -e $IPAPATH ]; then
		echo "xcodebuild Successful"
	else
		echo "error:Build faild!!"
		exit 1
	fi
else 
	xcodebuild \
	-workspace $SOURCEPATH/$SCHEMENAME.xcworkspace \
	-scheme $SCHEMENAME \
	-configuration $MODE \
	CODE_SIGN_IDENTITY="iPhone Developer: rui zhang (HK36TJZ8XU)" \
	PROVISIONING_PROFILE="cd4f0784-efcc-4a4e-b9f8-3400eef49b99" \
	clean \
	build \
	-derivedDataPath $IPAPATH

	if	[ -e $IPAPATH ]; then
		echo "xcodebuild Successful"
	else
		echo "error:Build faild!!"
		exit 1
	fi
fi

echo "\n\n\n====================================\n"
echo "===== xcrun begin ====="
echo "\n====================================\n\n\n"

xcrun -sdk iphoneos PackageApplication \
-v $IPAPATH/Build/Products/$MODE-iphoneos/$SCHEMENAME.app \
-o $IPAPATH/$IPANAME

if [ -e $IPAPATH/$IPANAME ]; then
#statements
	echo "\n\n\n====================================\n"
	echo "configuration! build Successful!"
	echo "\n====================================\n\n\n"
	open $IPAPATH
else
	echo "\n\n\n====================================\n"
	echo "error:create IPA faild!!"
	echo "\n====================================\n\n\n"
fi

cp -r /Users/`whoami`/Documents/AutoBuildIPA/HostSetting.txt /$SOURCEPATH/HX_GJS/Classes/BaseFrame/Networking/HostSetting.h 
if [ $? -ne 0 ]; then
	echo "cp recover  txt-> HostSetting.h faild!!!"
	exit 1
fi
# 启动模拟器
# xcrun instruments -w 'iPhone 6s'

# 卸载应用
# xcrun simctl uninstall booted com.gjfax.faxApp

# 安装应用
# xcrun simctl install booted $IPAPATH/Build/Products/$MODE-iphoneos/$SCHEMENAME.app

# 上传应用 应用管理API 查看uKey api_key

echo "upload path: " +$IPAPATH/$DATE.ipa

updateDescription=(集成)
if [ $MODE = "Debug" ]; then
	updateDescription=(用户)
fi

if [ $MODE = "Release" ]; then
	updateDescription=(生产)
fi
echo "updateDescription " +$updateDescription

curl -F "file=@$IPAPATH/$DATE.ipa" \
-F "uKey=d9572ef3a33118ee88eec9e8dc4e1c80" \
-F "_api_key=9c0328eb31c5b8597fe721e6d4e28a3a" \
-F "updateDescription=$updateDescription" \
https://qiniu-storage.pgyer.com/apiv1/app/upload

if [ $? -ne 0 ]; then
	echo "\n\n====================================\n"
	echo "upload ipa faild!!"
	echo "\n====================================\n\n\n"
else
	echo "\n\n====================================\n"
	echo "upload ipa Successful!!"
	echo "\n====================================\n\n\n"
fi

