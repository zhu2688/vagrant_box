# vagrant box 
vagrant box php7开发环境 php5的详见 [php5分支](https://github.com/zhu2688/vagrant_box/tree/master)

## box 文件保存在file分支
github上超过100M大文件必须用[LFS](https://git-lfs.github.com) 来上传

## 下载box后本地安装
- 下载box [https://github.com/zhu2688/vagrant_box/releases/download/0.0.2/centos-6.9-x64.box](https://github.com/zhu2688/vagrant_box/releases/download/0.0.2/centos-6.9-x64.box) 
- 下载Vagrantfile [https://raw.githubusercontent.com/zhu2688/vagrant_box/php7/centos/Vagrantfile](https://raw.githubusercontent.com/zhu2688/vagrant_box/php7/centos/Vagrantfile)
- 下载centos69.sh [https://raw.githubusercontent.com/zhu2688/vagrant_box/php7/centos/centos69.sh](https://raw.githubusercontent.com/zhu2688/vagrant_box/php7/centos/centos69.sh)


```shell
## 把上面三个脚本放到当前目录
vagrant box add php7 centos-6.9-x64.box
vagrant up

```

## 软件环境
-  vagrant 2.2.4
-  VirtualBox 5.2.18
-  GuestAdditions 5.2.18

## 简介
  vagrant 一个完整的box文件都特别大,所以使用base文件加上provision来初始化开发环境

```shell
  ├── centos
  │   ├── centos-6.9-x64.box  基本box
  │   ├── centos69.sh    初始化脚本
  │   ├── Vagrantfile    Vagrantfile 文件
```
## Provision
  Provision工作方式和详解 [https://www.vagrantup.com/docs/provisioning/](https://www.vagrantup.com/docs/provisioning/)
```shell
## 只会在第一次启动的时候会自动执行 provision 的shell脚本 centos69.sh 
## 如果需要再次执行centos69.sh 
## 需要用以下方式启动
vagrant reload --provision
```

## php环境

```shell
## centos69.sh脚本中可以修改各个软件和扩展的版本号
* Php7.2
* Mysql 5.6
* Redis 4.0
* Tengine 2.3.0
```