#[cxx::bridge(namespace = "mill::bridge")]
mod ffi {
    // TODO: handle memory write
    struct MemReqPacket {
        addr: u64,
        we: bool,
        be: u8,
        data: u32, // TODO: return as CxxVec or CxxString
    }

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

        pub fn read(req: &mut UniquePtr<MemReq>, addr: &mut MemReqPacket) -> bool;
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
    pending: Option<Vec<u64>>,
}

impl MemInterface {
    pub fn handle_single_tick(&mut self, mem: &mut Mem) {
        if let Some(ref pending) = self.pending {
            // Process pending request from the previous cycle
            ffi::no_read(&mut self.req);
            let resp = ffi::write(&mut self.resp, pending);
            if resp {
                self.pending = None;
            }
        } else {
            let mut pack = ffi::MemReqPacket {
                addr: 0,
                be: 0,
                we: false,
                data: 0,
            };

            let has_req = ffi::read(&mut self.req, &mut pack);

            if !has_req {
                ffi::no_write(&mut self.resp);
                return;
            }

            let data = mem.mem.get(&pack.addr).cloned().unwrap_or(0);

            // Write
            if pack.we {
                if pack.addr == 0x20000000u64 {
                    // tohost
                    log::info!("tohost: {}", pack.data);
                } else {
                    log::debug!("writing: 0x{:x} <- 0x{:x} / 0b{:b}", pack.addr, pack.data, pack.be);
                    let mut buffer = data.to_le_bytes();
                    let writing = pack.data.to_le_bytes();
                    for i in 0..4 {
                        if (pack.be & (1 << i)) != 0 {
                            buffer[i] = writing[i];
                        }
                    }

                    let flatten = u32::from_le_bytes(buffer);
                    if flatten != data {
                        mem.mem.insert(pack.addr, flatten);
                    }
                }
            }

            let data_pack = vec![data as u64];
            let resp = ffi::write(&mut self.resp, &data_pack);

            if !resp {
                self.pending = Some(data_pack);
            }
        }
    }
}
