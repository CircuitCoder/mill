mod rtl;
mod mem;
mod cmd;

use anyhow::Error;
use cmd::Args;

#[paw::main]
fn main(args: Args) -> Result<(), Error>{
    env_logger::init();
    args.run()
}
