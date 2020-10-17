GTKWave 是一个开源的波形浏览器，支持 VCD 和 FST 格式。

FST 是一种波形记录格式，为 Verilator 所支持。相比于 VCD，FST 文件的大小更小，且支持 Enum，Struct 等 SystemVerilog 专有的功能。

使用 Mill 运行 RTL 代码的仿真测试时，可以传递 `-i path/to/wave.fst` 参数，让测试框架输出波形文件。之后，可以直接使用 GTKWave 打开：

- On Linux: `gtkwave path/to/wave.fst path/to/config.wcfg`
- On Windows: 推荐安装 VcXSrv 之后在 WSL 中安装 gtkwave
- On macOS: 待测试，理论上和 Linux 相同

其中，wcfg 文件保存有 GTKWave 的配置，比如目前显示的信号、标记，等等，在保存以后可以在下次打开 GTKWave 的时候保留。

## GTKWave 的部份功能
GTKWave 有一些很方便的功能，可以对调试 CPU 很有帮助。具体的使用方法可以查看 GTKWave 的文档或者自行 Google。

- 标记: Markers，可以标记某个时间轴上的位置，并且用快捷键跳转。
- 搜索：Search
- 可以在显示区换信号的颜色，添加可折叠的分组，以及添加空信号（方便信号很多的时候的导航）
