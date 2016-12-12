# 回归测试
     回归测试主要验证Paddle各个版本的变化，并不会对demo的行为造成影响。我们通过执行demo，并统计各demo的训练误差情况、测试误差情况、训练速度、内存使用情况、显存使用情况以及CPU使用情况等进行验证。
     
## 回归测试框架介绍

     Paddle回归测试框架分为三部分：容器的构建、demo的自动化运行、数据统计。具体框架
    图下图所示：
    ![image](https://github.com/dayhaha/regtest/raw/master/regression.png)
    
    其中，容器的构建：从github上拉取任意分支、任意版本，自动编译其paddle的docker容器环境；
    demo的自动化运行：自我选择性的选取想要运行的demo，或者运行所有的demo。
    数据统计：收集各demo的训练误差情况、测试误差、内存、显存、CPU等各项指标情况，并进行对比分析。
    
## 测试框架的使用
