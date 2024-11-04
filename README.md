# Verilog 2048game (FPGA VGA Basys3)

#### author: Zevick

## 基本描述

复旦2024春季，数字逻辑基础（H）课程作业，本项目代码成功通过了Basys3的上板验证。

利用Verilog设计硬件电路，实现了简易的2048小游戏，并利用VGA端口输出640x480@60的显示画面。

## 功能概览

- [ ] 使用usb接口接收来自键盘输入
- [x] 使用开发板上button与switch做输入与重置按键
- [x] 计时器与7段数码管显示
- [x] VGA画面棋盘与**ascii**字符显示

## 成果展示

#### 游戏画面

![](https://github.com/theElysia/Verilog-2048game/blob/main/pics/%E8%BF%87%E7%A8%8B.PNG?raw=true)

![](https://github.com/theElysia/Verilog-2048game/blob/main/pics/%E7%BB%93%E6%9D%9F.PNG?raw=true)

#### 资源使用

![](https://github.com/theElysia/Verilog-2048game/blob/main/pics/%E8%B5%84%E6%BA%90%E4%BD%BF%E7%94%A8.png?raw=true)

***

## 项目结构

game_top.v

> 1. game_kernel.v
>    1.  module: game_control（游戏控制内核及得分计算）
> 2. vga_modules.v
>    1. module: vga_control_sample（生成测试彩条）
>    2. module: vga_control（游戏画面显示控制模块）
>    3. module: ascii8x16（存储字符点阵）
> 3. segment_led_modules.v
>    1. module: display_7segment（七段数码管显示控制模块）
>    2. module: digit_to_7seg_patten（数字转七段显示）
>    3. module: led_timer（秒表及七段数码管显示）
> 4. Zevick_lib.v
>    1. module: simple_counter（无加载功能任意进制计数器）
>    2. module: frequency_divider（时钟偶数倍分频器）
>    3. module: async_to_sync（将异步多周期输入信号规整为给定时钟单周期信号）
>    4. module: binary_to_decimal（二进制数转十进制数，BCD编码）
>    5. module: random_8/32（LFSR型随机数生成器）

## 技术难点分享

#### 1.随机数生成

线性反馈移位寄存器（Linear Feedback Shift Register，LFSR），利用反馈函数以及线性位移生成伪随机序列。

多项式f(x)的阶定义为使式子
$$
f(x)|(x^n-1)
$$
成立的最小n，而n级的m序列特征多项式的阶为2^n-1，可以利用这个来构造相应电路。

有斐波那契LFSR与伽罗瓦LFSR两种类型，本项目采用伽罗瓦型（Galois）。且使用同或运算，故输出范围为
$$
[0 , 2^n-2]
$$

#### 2.二进制数转十进制数

使用名为**Double dabble**的技术，不断重复位移与加3操作。大致操作为从高位（有补0操作）开始扫描，每次4位，**若大于4，则加3**（详见代码）。

可以这样简单理解，每次移位相当于乘2，而+3在乘2后就变成+6，对于BCD编码相当于进位；大于4的数乘2后显然大于等于10，需要进位。通过每次判断位移与加3，用数学归纳法来理解，这样可以保证高位的BCD编码的正确性。

#### 3.VGA画面显示

为了减少保存画面的资源消耗，本部分在代码实现时仅存储了16\*4+32个ASCII字符点阵（16\*4为棋盘使用，32为右半画面显示使用）。为了进一步减轻时序压力（上述的存储模式相当于要实时计算并生成相当一部分画面内容），将640x480画布先按照64x64划分成基本块大小（选用2的幂次是避免取模运算），再对基本块填充色彩。

对于存储的字符点阵，我们也设置了事件驱动的更新策略。当其发生变化时，由game_kernel模块发出flush信号，接收到该信号时才会对画面进行更新。

本部分虽然看起来没什么含金量，但却是整个项目中耗费时间最大的部分QwQ。

以及友情提示，**VGA在行场信号无效时RGB一定要输出BLACK！！** 不然会有意外。
