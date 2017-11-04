# vagrant box 
vagrant php开发环境 box

## 方法1 从代码仓库直接下载使用
clone 过程比较久,因为库里面包括了一个大文件,github上超过100M大文件必须用[LFS](https://git-lfs.github.com) 来上传
```shell
git clone https://github.com/zhu2688/vagrant_box.git ##
cd vagrant_box/centos
vagrant box add dev1 ./centos-6.7-x64.box
vagrant up
```
## 方法2 下载box后本地安装
- 下载box [https://github.com/zhu2688/vagrant_box/raw/file/centos/centos-6.7-x64.box](https://github.com/zhu2688/vagrant_box/raw/file/centos/centos-6.7-x64.box) 
- 下载Vagrantfile [Vagrantfile](https://raw.githubusercontent.com/zhu2688/vagrant_box/master/centos/Vagrantfile)
- 下载centos67.sh [centos67.sh](https://raw.githubusercontent.com/zhu2688/vagrant_box/master/centos/centos67.sh)


```shell
## 把上面三个脚本放到当前目录
vagrant box add dev1 centos-6.7-x64.box
vagrant up
```

## 软件环境
-  vagrant 1.9.6
-  VirtualBox 5.0.40

## 简介
  vagrant 一个完整的box文件都特别大,所以使用base文件加上provision来初始化开发环境

```shell
  ├── centos
  │   ├── centos-6.7-x64.box  基本box
  │   ├── centos67.sh    初始化脚本
  │   ├── Vagrantfile    Vagrantfile 文件
```
  
## php环境

```shell
* Php5.6
* Mysql 5.6
* Redis 3.2
* Tengine 2.2.1
```