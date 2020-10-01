fn main() {
    let dst = cmake::build("bridge");
    println!("cargo:rustc-link-search=native={}", dst.join("lib").display());
    println!("cargo:rustc-link-lib=dylib=millrtl");
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=bridge/bridge.h");
}
