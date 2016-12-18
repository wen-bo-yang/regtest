# 回归测试


回归测试主要验证Paddle各个版本的变化，并不会对demo的行为造成影响。我们通过执行demo，并统计各demo的训练误差情况、测试误差情况、训练速度、内存使用情况、显存使用情况以及CPU使用情况等进行验证。


## 回归测试框架介绍

- **概述**

Paddle回归测试框架分为三部分：容器的构建、demo的自动化运行、数据统计。具体框架图如下图所示：
![image](https://github.com/beckett1124/regtest/blob/develop/img/regression.png)
    
其中，容器的构建：从github上拉取任意分支、任意版本，自动编译其paddle的docker容器环境。
demo的自动化运行：自我选择性的选取想要运行的demo，或者运行所的demo。
数据统计：收集各demo的训练误差情况、测试误差、内存、显存、CPU等各项指标情况，并进行对比分析。

- **模块组成** 

  - 容器构建

    Paddle的运行环境构建可以从 [Docker Hub paddledev/paddle](https://hub.docker.com/r/paddledev/paddle/builds/) 
    和 [Github PaddlePaddle/Paddle](https://github.com/PaddlePaddle/Paddle) 进行Paddle运行环境构建。
    
    使用不同的参数来区分构建来源`./run.sh --dockerhub=dockerhub`和`./run.sh --github=github`。
    参数中对应的值dockerhub和github是`run.sh`读取的配置文件,用以构建不同源的Paddle运行环境。

    在每次构建中，可以选择是否从新构建docker image、Paddle版本、运行demo名字、指定demo的模型以及指定apt-get更新源等等，
    具体详情可以查看配置文件中的注释。

    **如果不需要重新构建docker image时，请将配置文件中的rebuild置成OFF**`rebuild=OFF`

    环境构建成功后会启动一个docker container，程序会将所需要的资源和文件以挂载卷的方式挂到container中，
    同时会自动触发`auto_test/demo_run.sh`运行配置文件中指定的demo和对应的模型。
    如果构建iamge和启动container成功，则可以在屏幕中看到指定demo的运行详情。

    **如果没有成功运行demo，可以打开run.sh中的**`set -x`**查看详细信息。
    由于程序中每次会初始化docker container，如果开启重新构建参数，也会重新初始化docker image的运行环境。
    如果构建docker image失败，请在下次运行程序时请手动删除没有构建成功的image。**

    具体构建流程如下图所示：

    ![image](https://github.com/beckett1124/regtest/blob/develop/img/build_paddle_docker_image.png)
  
  - demo自动化运行
  
  - 数据统计

## 测试框架的使用

执行 `./run.sh --dockerhub=dockerhub` 或 `./run.sh --github=github`.
  
  ```bash
  ./run.sh -h
  Usage: ./run.sh [option] [arg]

  Options and arguments

    --dockerhub : specify the conf file and build from dockerhub
    --github    : specify the conf file and build from github
    -h --help   : print this help message

  e.g.:
    ./run.sh --dockerhub=dockerhub    : build images from paddle dockerhub

    ./run.sh --github=github          : build images from paddle github that branch is develop

  ```
