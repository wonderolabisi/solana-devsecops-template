#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: (u64, u64)| {
    let (a, b) = data;
    let _ = a.checked_add(b);
});
