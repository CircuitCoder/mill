> 首先，为了运行最基本的 `rv32ui-p` 测试，除了所有非特权 `RV32I` 指令外，你必须实现 `ecall`。
>
> 因此，需要实现 CSR 读写，以及至少实现 `mhartid`，`misa`，`mtvec`，`mcause` CSR，至少实现 Illegal Instruction 和 Environmental Call 两个异常，其中前者用来处理不存在的 CSR。

[riscv-tests](https://github.com/riscv/riscv-tests) 是 RISC-V Foundation 提供的 RISC-V 核单元测试，包含对于基础指令集、扩展以及特权态的测试，可以根据目标实现的指令集，调整测例的范围。

接下来将介绍如何使用 Mill 框架运行 `rv32ui-p` 测试，也就是 `RV32I` 非特权指令，在单核 M 态上执行。

## 约定

`p` 环境下的 `riscv-tests` 测例是 PIE，也就是处理器的 boot vector 不会影响测例的正常执行。这意味着我们不需要修改 Linker Script 来适配不同的处理器。

`riscv-tests` 和测试环境的通讯方式和 Spike 模拟器的实现一致： Spike 模拟器在加载 elf 的时候会将 `tohost` 和 `fromhost` 符号作为宿主机和模拟器内软件的通讯接口，以此实现 Syscall 的代理。应用这一协议，测例可以通知测试环境测试通过或者某个子测例失败。具体的协议可以参考 `rust/rtl.rs` 实现。Mill 框架也同样实现了这一协议，在 `run` 命令中可以通过 `-s` 打开。

在 `p` 环境下，`tohost` 符号永远位于 `BASE+0x1000` 位置。根据 RISC-V 社区的一般约定， boot vector 位于 `0x80000000`，因此 Mill 框架默认会监听 `0x80001000`。可以通过 `--spike-base <ADDR>` 选项修改这一地址。

## 使用 Mill 运行 `riscv-tests`

### 编译

首先，在任意位置 clone 仓库:

```bash
> git clone https://github.com/riscv/riscv-tests.git
> cd riscv-tests
```

---

随后，你需要安装编译器。如果你使用 ArchLinux，可以安装 `riscv64-linux-gnu-binutils` 和 `riscv64-linux-gnu-gcc` 两个包。如果你使用其他 Linux，可以在 [此页面](https://www.sifive.com/software) 中下载 SiFive 提供的预编译工具链，或者 [下载源码](https://github.com/riscv/riscv-gnu-toolchain) 手动编译。

请确保将工具链二进制所在目录添加至 PATH 中。

---

接下来，修改 `riscv-tests/isa/Makefile`，选择需要的测例，并且生成裸二进制文件。

你需要根据你安装的编译器来修改对应的 `RISCV_PREFIX`。下面的例子中假设你使用 ArchLinux repo 中的 `riscv64-gnu-linux-*`

```diff
diff --git a/isa/Makefile b/isa/Makefile
index 4e1ba20..2e96d16 100644
--- a/isa/Makefile
+++ b/isa/Makefile
@@ -2,7 +2,7 @@
 # Makefile for riscv-tests/isa
 #-----------------------------------------------------------------------
 
-XLEN ?= 64
+XLEN ?= 32
 
 src_dir := .
 
@@ -17,12 +17,12 @@ include $(src_dir)/rv64si/Makefrag
 include $(src_dir)/rv64mi/Makefrag
 endif
 include $(src_dir)/rv32ui/Makefrag
-include $(src_dir)/rv32uc/Makefrag
-include $(src_dir)/rv32um/Makefrag
-include $(src_dir)/rv32ua/Makefrag
-include $(src_dir)/rv32uf/Makefrag
-include $(src_dir)/rv32ud/Makefrag
-include $(src_dir)/rv32si/Makefrag
-include $(src_dir)/rv32mi/Makefrag
+#include $(src_dir)/rv32uc/Makefrag
+#include $(src_dir)/rv32um/Makefrag
+#include $(src_dir)/rv32ua/Makefrag
+#include $(src_dir)/rv32uf/Makefrag
+#include $(src_dir)/rv32ud/Makefrag
+#include $(src_dir)/rv32si/Makefrag
+#include $(src_dir)/rv32mi/Makefrag
 
 default: all
@@ -31,10 +31,11 @@ default: all
 # Build rules
 #--------------------------------------------------------------------
 
-RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
+RISCV_PREFIX ?= riscv64-linux-gnu-
 RISCV_GCC ?= $(RISCV_PREFIX)gcc
-RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
+RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none
 RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
+RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy -O binary
 RISCV_SIM ?= spike
 
 vpath %.S $(src_dir)
@@ -45,11 +46,14 @@ vpath %.S $(src_dir)
 %.dump: %
 	$(RISCV_OBJDUMP) $< > $@
 
+%.bin : %
+	$(RISCV_OBJCOPY) $< $@
+
 %.out: %
-	$(RISCV_SIM) --isa=rv64gc $< 2> $@
+	$(RISCV_SIM) --isa=rv64g $< 2> $@
 
 %.out32: %
-	$(RISCV_SIM) --isa=rv32gc $< 2> $@
+	$(RISCV_SIM) --isa=rv32g $< 2> $@
 
 define compile_template
 
@@ -57,9 +61,9 @@ $$($(1)_p_tests): $(1)-p-%: $(1)/%.S
 	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -I$(src_dir)/../env/p -I$(src_dir)/macros/scalar -T$(src_dir)/../env/p/link.ld $$< -o $$@
 $(1)_tests += $$($(1)_p_tests)
 
-$$($(1)_v_tests): $(1)-v-%: $(1)/%.S
-	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -I$(src_dir)/../env/v -I$(src_dir)/macros/scalar -T$(src_dir)/../env/v/link.ld $(src_dir)/../env/v/entry.S $(src_dir)/../env/v/*.c $$< -o $$@
-$(1)_tests += $$($(1)_v_tests)
+# $$($(1)_v_elftests): $(1)-v-%: $(1)/%.S
+# 	$$(RISCV_GCC) $(2) $$(RISCV_GCC_OPTS) -DENTROPY=0x$$(shell echo \$$@ | md5sum | cut -c 1-7) -std=gnu99 -O2 -I$(src_dir)/../env/v -I$(src_dir)/macros/scalar -T$(src_dir)/../env/v/link.ld $(src_dir)/../env/v/entry.S $(src_dir)/../env/v/*.c $$< -o $$@
+# $(1)_tests += $$($(1)_v_tests)
 
 $(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))
 
@@ -91,18 +95,19 @@ $(eval $(call compile_template,rv64mi,-march=rv64g -mabi=lp64))
 endif
 
 tests_dump = $(addsuffix .dump, $(tests))
+tests_bins = $(addsuffix .bin, $(tests))
 tests_hex = $(addsuffix .hex, $(tests))
 tests_out = $(addsuffix .out, $(spike_tests))
 tests32_out = $(addsuffix .out32, $(spike32_tests))
 
 run: $(tests_out) $(tests32_out)
 
-junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)
+junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out) $(tests_bins)
 
 #------------------------------------------------------------
 # Default
 
-all: $(tests_dump)
+all: $(tests_dump) $(tests_bins)
 
 #------------------------------------------------------------
 # Clean up
```

---

在 `riscv-tests/isa` 目录中运行 `make -j`，会生成一系列 ELF，对应的二进制文件 `*.bin` 以及对应的反编译 `*.dump`。

### 仿真

之后可以使用 Mill 进行测试：

```bash
> cd path/to/mill
> find path/to/riscv-tests/isa -type f | grep "\.bin$" | RUST_LOG=info cargo run --release -- test
    Finished release [optimized] target(s) in 0.02s
     Running `target/release/mill-run test`
[2020-10-26T18:25:05Z INFO  mill_run::cmd::test] All 39 tests passed!
```

如果你的 CPU 核心是 N，这将会启动 N 个线程进行并发测试。
