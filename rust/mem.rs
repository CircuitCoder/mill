use anyhow::{anyhow, Error};
use byteorder::LittleEndian;
use byteorder::ReadBytesExt;
use std::collections::HashMap;
use std::io::Read;

#[derive(Default)]
pub struct Mem {
    pub(crate) mem: HashMap<u64, u32>,
}

impl Mem {
    pub fn init_with<R: Read>(&mut self, mut r: R, offset: u64) -> Result<usize, Error> {
        // Should be aligned
        if offset % 4 != 0 {
            return Err(anyhow!("Offset must align on 4-byte"));
        }

        let mut buffer = Vec::new();
        let all = r.read_to_end(&mut buffer)?;

        while buffer.len() % 4 != 0 {
            buffer.push(0);
        }

        let tot_len = buffer.len();

        let mut cursor = std::io::Cursor::new(buffer);

        for idx in (offset..(offset + tot_len as u64)).step_by(4) {
            let readout = cursor.read_u32::<LittleEndian>()?;
            self.mem.insert(idx, readout);
        }

        Ok(all)
    }
}
