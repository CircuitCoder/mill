## 约定

示例 CPU 的流水线有一个重要的约定：**除了 Ex 和 WB 以外，所有模块应该保证能够在当前周期被 Flush**。这是由于分支在 Ex 出口处生效，WB 永远不会被清空，而 Ex 只在自己不阻塞的时候输出有效。

这通常意味着两种实现：
- 纯组合逻辑，不带有状态。例如 ID
- 内部将 Flush 的内容单独处理。例如 IF，如果一个发出去的取指访问被 Flush 了，内部状态会进行标记。

这一约定使得分支的实现简单许多。

## Helpers

实现中包含数个辅助性的类型定义和模块：

### `decoupled`

抽象了 valid-ready 握手逻辑。当一个时钟上沿时，满足 ready && valid，意味着传输进行了一次。

这一类型主要用于 `queue` 的输入输出，以及流水级的输入输出。

### `counter`

自动溢出的计数器，区间为 `[0, BOUND)`，`tick == 1` 时自增。

### `queue`

队列。一个 `DEPTH` = D 的队列最多可以放 D-1 个元素。

参数意义为：

- `PIPE`: 即使队列已满，也允许在同一个周期内同时 `push + pop`。这会导致 `enq.ready` 形成包含 `deq.ready` 组合逻辑。
- `FALLTHROUGH`: 即使队列空，也允许同一个周期内同时 `push + pop`。这会导致 `deq.valid` 和 `deq.data` 形成包含 `enq` 对应信号的组合逻辑。

## 目录结构

在 `rtl/` 目录中：

- `components/`: 流水线以外的组件
  - `components/regfile.sv`: RegFile
  - `components/mem_arbiter.sv`: 访存仲裁器
- `exec/`: 执行单元实现，包括 ALU, Mem. PCRel 和 Misc，具体用途见 `stages/execute.sv`
- `stages/`: 流水级
- `types.sv`: 类型定义
- `types/`: 更多类型定义，包含于 `types.sv` 中
  - `types/decoupled.sv`: `decoupled` 类型
  - `types/insrt.sv`: 译码、指令相关的类型
  - `types/exec_result.sv`: 执行结果相关的类型
- `utils/`: 辅助模块
  - `utils/counter.sv`: 计数器
  - `utils/queue.sv`: 队列
- `cpu.sv`: SystemVerilog 类型的 CPU 顶级
- `top.sv`: 和仿真器约定的顶级接口，仿真时真正的顶级
