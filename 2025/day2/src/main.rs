use std::env;
use std::time::Instant;

fn repeats_at_least_twice(i: i64)->bool {
    let i = i.to_string();
    for pattern_len in 1..i.len() {    
        let mut repeating = false;    
        if i.len() % pattern_len == 0 {
            repeating = true;
            let i0 = &i[..pattern_len];
            for j in 1..(i.len()/pattern_len) {
                let ij = &i[(j*pattern_len)..((j+1)*pattern_len)];
                if i0 != ij {
                    repeating = false;
                    break;
                }
            }
            if repeating {
                return true;
            }
        }
    }
    false
}

fn repeats_twice(i: i64)->bool {
    let i = i.to_string();
    if i.len() % 2 == 0 {
        let left = &i[..i.len()/2];
        let right = &i[i.len()/2..];
        left == right
    }
    else {
        false
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();
    let mut S = 0;
    let mut S2 = 0;
    for part in data.trim().split(',') {
        let endpoints: Vec<&str> = part.split('-').collect();
        let a: i64 = endpoints[0].parse().unwrap();
        let b: i64 = endpoints[1].parse().unwrap();
        let length = b-a+1;
        
        for i in a..=b {
            if repeats_twice(i) {
                S += i;
            }
            if repeats_at_least_twice(i) {
                S2 += i;
            }
        }
    }
    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {S}");
    println!("Part 2: {S2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
