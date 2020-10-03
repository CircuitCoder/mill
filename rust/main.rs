mod rtl;
mod mem;

use std::fs::File;
use std::num::ParseIntError;
use std::path::PathBuf;
use std::str::FromStr;

use anyhow::Error;
use mem::Mem;
use structopt::StructOpt;

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
    author,
    about = "Run CPU simulation",
    setting = structopt::clap::AppSettings::TrailingVarArg,
    setting = structopt::clap::AppSettings::AllowLeadingHyphen,
)]
struct Args {
    /// Maximum cycle count
    #[structopt(short, long, default_value = "100000")]
    cycles: usize,

    /// Reset cycle count
    #[structopt(long, default_value = "10")]
    reset_for: usize,

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

#[paw::main]
fn main(args: Args) -> Result<(), Error>{
    env_logger::init();

    log::debug!("With arguments: {:#?}", args);

    let mut mem = Mem::default();

    if let Some(mem_file) = args.mem {
        let f = File::open(mem_file)?;
        mem.init_with(f, args.mem_base.0)?;
    }

    log::debug!("Creating CPU...");
    let mut cpu = rtl::CPU::new(
        &args.extra,
        &args.trace,
    );
    cpu.set_rst(true);

    log::debug!("Creating MemInterface...");
    let mut mem_handler = cpu.mem();

    for cycle in 0..args.cycles {
        if cycle == args.reset_for {
            cpu.set_rst(false);
        }

        mem_handler.handle_single_tick(&mut mem);

        cpu.tick();
    }

    log::debug!("Simulation done");
    Ok(())
}
