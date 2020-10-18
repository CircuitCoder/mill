use std::fs::File;
use std::num::ParseIntError;
use std::path::PathBuf;
use std::str::FromStr;

use anyhow::Error;
use structopt::StructOpt;

use crate::mem::Mem;
use crate::rtl;

use super::SharedArgs;

#[derive(Debug)]
struct Addr(u64);
impl FromStr for Addr {
    type Err = ParseIntError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.starts_with("0x") {
            return Ok(Self(u64::from_str_radix(&s[2..], 16)?));
        } else {
            return Ok(Self(s.parse()?));
        }
    }
}

#[derive(StructOpt, Debug)]
#[structopt(
    setting = structopt::clap::AppSettings::TrailingVarArg,
    setting = structopt::clap::AppSettings::AllowLeadingHyphen,
)]
pub struct RunArgs {
    /// The memory file used to initialize the memory. If not provided, then the memory will be initialized to zero
    #[structopt(short, long)]
    mem: Option<PathBuf>,

    /// Base address of the provided memory file
    #[structopt(long, default_value = "0x80000000")]
    mem_base: Addr,

    /// Tracing waveform
    #[structopt(short, long)]
    trace: Option<PathBuf>,

    /// Extra argument passed directly to verilator
    extra: Vec<String>,
}

impl RunArgs {
    pub fn run(self, shared: SharedArgs) -> Result<(), Error> {
        let mut mem = Mem::default();

        if let Some(mem_file) = self.mem {
            let f = File::open(mem_file)?;
            mem.init_with(f, self.mem_base.0)?;
        }

        log::debug!("Creating CPU...");
        let mut cpu = rtl::CPU::new(&self.extra, &self.trace);
        cpu.set_rst(true);

        log::debug!("Creating MemInterface...");
        let mut mem_handler = cpu.mem();

        for cycle in 0..shared.cycles {
            if cycle == shared.reset_for {
                cpu.set_rst(false);
            }

            mem_handler.handle_single_tick(&mut mem);

            cpu.tick();
        }

        log::debug!("Simulation done");
        Ok(())
    }
}
