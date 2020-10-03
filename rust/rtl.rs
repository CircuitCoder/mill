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

use std::path::PathBuf;

use cxx::UniquePtr;

use crate::mem::Mem;
pub struct CPU(UniquePtr<ffi::CPU>);
impl CPU {
    pub fn new(extra: &Vec<String>, trace: &Option<PathBuf>) -> Self {
        let inner = ffi::init(
            &extra,
            trace
                .as_ref()
                .and_then(|p| p.as_os_str().to_str())
                .unwrap_or(""),
        );

        Self(inner)
    }

    pub fn tick(&mut self) {
        ffi::tick(&mut self.0);
    }

    pub fn set_rst(&mut self, rst: bool) {
        ffi::set_rst(&mut self.0, rst);
    }
    
    pub fn mem(&mut self) -> MemInterface {
        MemInterface {
            req: ffi::mem_req(&mut self.0),
            resp: ffi::mem_resp(&mut self.0),
            pending: None,
        }
    }
}

pub struct MemInterface {
    req: UniquePtr<ffi::MemReq>,
    resp: UniquePtr<ffi::MemResp>,
    pending: Option<u64>,
}

impl MemInterface {
    pub fn handle_single_tick(&mut self, mem: &mut Mem) {
        if let Some(pending) = self.pending {
            // Process pending request from the previous cycle
            ffi::no_read(&mut self.req);
        } else {
            let mut addr: u64 = 0;
            let has_req = ffi::read(&mut self.req, &mut addr);

            if !has_req {
                return;
            }
        }
    }
}
