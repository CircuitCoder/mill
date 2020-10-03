fn main() {
    let dst = cmake::build("bridge");
    println!(
        "cargo:rustc-link-search=native={}",
        dst.join("lib").display()
    );
    println!("cargo:rustc-link-lib=dylib=millrtl");

    // Rerun on build.rs changes
    println!("cargo:rerun-if-changed=build.rs");

    // Only rerun on bridge and bridge/* changes
    println!("cargo:rerun-if-changed=bridge");
    for entry in glob::glob("bridge/*").unwrap() {
        println!("cargo:rerun-if-changed={}", entry.unwrap().display());
    }

    // Rerun on rtl/**/*
    println!("cargo:rerun-if-changed=rtl");
    for entry in glob::glob("rtl/**/*").unwrap() {
        println!("cargo:rerun-if-changed={}", entry.unwrap().display());
    }
}
