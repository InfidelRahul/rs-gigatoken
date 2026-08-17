#![no_main]

use libfuzzer_sys::fuzz_target;
use rs_gigatoken::load_tokenizer::hf::load_hf_slice;

fuzz_target!(|data: &[u8]| {
    // The parser must never panic on arbitrary tokenizer.json bytes. If the
    // input happens to describe a supported tokenizer, exercise the loader's
    // construction path as well.
    let _ = load_hf_slice(data);
});
