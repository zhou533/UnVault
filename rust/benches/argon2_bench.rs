use criterion::{criterion_group, criterion_main, Criterion};

use unvault_core::crypto::argon2::{self, Argon2Params};

fn bench_argon2_safety_floor(c: &mut Criterion) {
    let params = Argon2Params {
        memory_kib: 32 * 1024, // 32 MB
        iterations: 2,
        parallelism: 1,
    };
    let salt = argon2::generate_salt();
    let password = b"benchmark_password";

    c.bench_function("argon2id_safety_floor_32MB_2iter", |b| {
        b.iter(|| {
            argon2::derive_key(password, &salt, &params).unwrap();
        })
    });
}

fn bench_argon2_default_high(c: &mut Criterion) {
    let params = Argon2Params {
        memory_kib: 64 * 1024, // 64 MB
        iterations: 3,
        parallelism: 2,
    };
    let salt = argon2::generate_salt();
    let password = b"benchmark_password";

    c.bench_function("argon2id_default_high_64MB_3iter", |b| {
        b.iter(|| {
            argon2::derive_key(password, &salt, &params).unwrap();
        })
    });
}

criterion_group! {
    name = argon2_benches;
    config = Criterion::default().sample_size(10);
    targets = bench_argon2_safety_floor, bench_argon2_default_high
}
criterion_main!(argon2_benches);
