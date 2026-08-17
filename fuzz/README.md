# rs-gigatoken fuzzing

The first target stress-tests the Hugging Face tokenizer JSON parser and
loader. It is intentionally independent of the large benchmark datasets.

Install cargo-fuzz and run:

```bash
cargo fuzz run hf_tokenizer_json
```

The target is expected to reject malformed or unsupported inputs with an
ordinary `Result` rather than panicking.
