use std::path::PathBuf;

use anyhow::Error;

use super::SharedArgs;

use structopt::StructOpt;

fn run_internal<I>(it: I, shared: SharedArgs) -> Result<(), Error>
where
    I: IntoIterator<Item = PathBuf>,
{
    for path in it {
        log::debug!("Running file: {}", path.display());
    }

    Ok(())
}

#[derive(StructOpt, Debug)]
pub struct TestArgs {
    /// A list file as bare binary executable. If not present, mill will try to read from stdin and use that as the file list (one path per line)
    #[structopt(short, long)]
    files: Option<Vec<PathBuf>>,
}

impl TestArgs {
    pub fn run(self, shared: SharedArgs) -> Result<(), Error> {
        match self.files {
            Some(vec) => run_internal(vec, shared),
            None => {
                use std::io::prelude::*;
                let it = std::io::stdin();
                let lines = it.lock().lines();
                let lines = lines.map(|l| PathBuf::from(l.unwrap()));
                run_internal(lines, shared)
            }
        }
    }
}
