pub mod run;
pub mod test;

use anyhow::Error;
use structopt::StructOpt;

use self::run::RunArgs;
use self::test::TestArgs;

#[derive(StructOpt, Debug)]
#[structopt(author, about = "The mill driver")]
pub struct Args {
    #[structopt(flatten)]
    shared: SharedArgs,

    /// The command to run
    #[structopt(subcommand)]
    cmd: Command,
}

impl Args {
    pub fn run(self) -> Result<(), Error> {
        log::debug!("With arguments: {:#?}", self);
        self.cmd.run(self.shared)
    }
}

#[derive(StructOpt, Debug)]
pub struct SharedArgs {
    /// Maximum cycle count
    #[structopt(short, long, default_value = "100000")]
    cycles: usize,

    /// Reset cycle count
    #[structopt(long, default_value = "10")]
    reset_for: usize,
}

#[derive(StructOpt, Debug)]
enum Command {
    /// Run CPU Simulation
    Run(RunArgs),

    /// Run Test
    Test(TestArgs),
}

impl Command {
    pub fn run(self, shared: SharedArgs) -> Result<(), Error> {
        match self {
            Self::Run(a) => a.run(shared),
            Self::Test(a) => a.run(shared),
        }
    }
}
