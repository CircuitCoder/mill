mod rtl;

fn main() {
    let cpu = rtl::init();
    std::mem::drop(cpu);
}
