#!bin/bash 

ORGANIZATION=DecodeDevOps
COMPONENT=shipping
USERNAME=roboshop
DIRECTORY=/tmp/$COMPONENT
APPDIRECTORY=/home/$USERNAME/$COMPONENT
ARTIFACTS=https://github.com/$ORGANIZATION/$COMPONENT/archive/refs/heads/main.zip

OS=$(hostnamectl | grep 'Operating System' | tr ':', ' ' | awk '{print $3$NF}')
selinux=$(sestatus | awk '{print $NF}')

if [ $OS == "CentOS8" ]; then
    echo -e "\e[1;33mRunning on CentOS 8\e[0m"
    else
        echo -e "\e[1;33mOS Check not satisfied, Please user CentOS 8\e[0m"
        exit 1
fi

if [ $selinux == "disabled" ]; then
    echo -e "\e[1;33mSE Linux Disabled\e[0m"
    else
        echo -e "\e[1;33mOS Check not satisfied, Please disable SE linux\e[0m"
        exit 1
fi

if [ $(id -u) -ne 0 ]; then
  echo -e "\e[1;33mYou need to run this as root user\e[0m"
  exit 1
fi

hostname $COMPONENT

cat /etc/passwd | grep $USERNAME
if [ $? -ne 0 ]; then
    useradd $USERNAME
    echo -e "\e[1;33m$USERNAME user added\e[0m"
    else
    echo -e "\e[1;32m$USERNAME user exists\e[0m"
fi 

if [ -d $DIRECTORY ]; then
    rm -rf $DIRECTORY
    mkdir -p $DIRECTORY
    else
        mkdir -p $DIRECTORY
fi

echo -e "\e[1;33m$DIRECTORY Created, Downloading and Extracting the Artifacts"
if [ -d $APPDIRECTORY ]; then
    rm -rf $APPDIRECTORY
    mkdir -p $APPDIRECTORY
    else
        mkdir -p $APPDIRECTORY
fi

echo -e "\e[1;33mDownload and Extract $COMPONENT Artifacts\e[0m"
curl -L $ARTIFACTS -o $DIRECTORY/$COMPONENT.zip
unzip $DIRECTORY/$COMPONENT.zip -d $DIRECTORY

echo -e "\e[1;33mInstalling Build tools\e[0m"
rpm -qa maven | grep maven 
if [ $? -ne 0 ]; then
    yum install -y maven
    echo -e "\e[1;33mBuild tools installed\e[0m"
    else
        echo -e "\e[1;33mExisting installations found\e[0m"
fi

echo -e "\e[1;33mInstalling $COMPONENT dependencis with maven\e[0m"
cp -rvf $DIRECTORY/$COMPONENT-main/* $APPDIRECTORY
cd $APPDIRECTORY
mvn clean package

if [ $? -eq 0 ]; then
    echo -e "\e[1;33mApp dependencies installed successfully\e[0m"
    else
        echo -e "\e[1;33mFailed to install app dependences with maven\e[0m"
        exit 0
fi

echo -e "\e[1;33mConfiguring and starting $COMPONENT\e[0m"
mv -fv $APPDIRECTORY/target/shipping-1.0.jar $APPDIRECTORY/shipping.jar 
sed -i -e 's/{{DOMAIN}}/'$USERNAME'.com/g' $APPDIRECTORY/$COMPONENT.service
mv $APPDIRECTORY/$COMPONENT.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable $COMPONENT && systemctl restart $COMPONENT
if [ $? -eq 0 ]; then
    echo -e "\e[1;33m$COMPONENT configured successfully\e[0m"
    else
        echo -e "\e[1;33mfailed to configure $COMPONENT\e[0m"
        exit 0
fi