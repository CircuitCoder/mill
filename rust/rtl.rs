pub use ffi::*;

#[cxx::bridge(namespace = "mill::bridge")]
mod ffi {
    extern "C" {
        include!("bridge.h");

        type MemReq;
        type MemResp;
        type CPU;

        pub fn init(args: &Vec<String>, trace: &str) -> UniquePtr<CPU>;
        pub fn set_int(cpu: &mut UniquePtr<CPU>, n: usize);
        pub fn clear_int(cpu: &mut UniquePtr<CPU>, n: usize);
        pub fn set_rst(cpu: &mut UniquePtr<CPU>, rst: bool);
        pub fn tick(cpu: &mut UniquePtr<CPU>) -> bool;

        pub fn mem_req(cpu: &mut UniquePtr<CPU>) -> UniquePtr<MemReq>;
        pub fn mem_resp(cpu: &mut UniquePtr<CPU>) -> UniquePtr<MemResp>;

        pub fn read(req: &mut UniquePtr<MemReq>, addr: &mut u64) -> bool;
        pub fn no_read(req: &mut UniquePtr<MemReq>);

        pub fn write(resp: &mut UniquePtr<MemResp>, packed_data: &Vec<u64>) -> bool;
        pub fn no_write(resp: &mut UniquePtr<MemResp>);
    }
}
