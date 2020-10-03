mod rtl;

use std::num::ParseIntError;
use std::path::PathBuf;
use std::str::FromStr;

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
fn main(args: Args) {
    env_logger::init();

    log::debug!("With arguments: {:#?}", args);

    let mut cpu = rtl::CPU::new(
        &args.extra,
        &args.trace,
    );
    cpu.set_rst(true);

    for cycle in 0..args.cycles {
        if cycle == args.reset_for {
            cpu.set_rst(false);
        }

        cpu.tick();
    }
}
