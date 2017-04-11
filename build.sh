#!/bin/bash
# author Blavtes

# 工程名
SCHEMENAME=GjFax 
BRANCHNAME=develop

# $1表示传入的第一个参数，启动脚本传入Debug或者Release就可以
# 如：sh build.sh Debug

MODE=$1
# echo "请输入传入Debug或者Release："
# read -p "请输入传入Debug或者Release：" input
# if [ $? -ne 0 ]; then
# 	MODE = $1
# 	echo $MODE + $input
# else 
# 	echo  $input
# 	MODE = $input
# 	echo  $input + $MODE
# fi
# echo $MODE
# exit

# svn 更新
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

DATE=`date +%Y%m%d_%H%M`
SOURCEPATH=$( cd "$( dirname $0 )" && pwd)
IPAPATH=/Users/`whoami`/Documents/AutoBuildIPA/$BRANCHNAME/$MODE/$DATE
IPANAME=$SCHEMENAME_$DATE.ipa

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
else 
	xcodebuild \
	-workspace $SOURCEPATH/$SCHEMENAME.xcworkspace \
	-scheme $SCHEMENAME \
	-configuration $MODE \
	CODE_SIGN_IDENTITY="iPhone Developer: rui zhang (HK36TJZ8XU)" \
	PROVISIONING_PROFILE="cd4f0784-efcc-4a4e-b9f8-3400eef49b99" \
	build \
	-derivedDataPath $IPAPATH

	if	[ -e $IPAPATH ]; then
		echo "xcodebuild Successful"
	else
		echo "error:Build faild!!"
		exit 1
	fi
fi



echo "\n\n\n====================================\n\n\n"
echo "===== xcrun begin ====="
echo "\n\n\n====================================\n\n\n"

xcrun -sdk iphoneos PackageApplication \
-v $IPAPATH/Build/Products/$MODE-iphoneos/$SCHEMENAME.app \
-o $IPAPATH/$IPANAME

if [ -e $IPAPATH/$IPANAME ]; then
#statements
	echo "\n\n\n====================================\n\n\n"
	echo "configuration! build Successful!"
	echo "\n\n\n====================================\n\n\n"
	open $IPAPATH
else
	echo "\n\n\n====================================\n\n\n"
	echo "error:create IPA faild!!"
	echo "\n\n\n====================================\n\n\n"
fi

xcrun instruments -w 'iPhone 6s'

xcrun simctl uninstall booted com.gjfax.faxApp

xcrun simctl install booted $IPAPATH/Build/Products/$MODE-iphoneos/$SCHEMENAME.app
