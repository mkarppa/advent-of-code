use std::env;
use std::time::Instant;

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();

    let mut d: i32 = 50;
    let mut count = 0;
    let mut count2 = 0;

    let start = Instant::now();
    for part in data.trim().split('\n') {
        let mut amount: i32 = part[1..].parse().unwrap();
        let mut d_end = d;
        count2 += amount/100;
        amount -= 100 * (amount/100);
        if part.starts_with("L") {
            d_end -= amount;
            if d > 0 && amount > d {
                count2 += 1;
            }
        }
        else {
            d_end += amount;
            if d + amount > 100 {
                count2 += 1;
            }
        }
  
        d = d_end.rem_euclid(100);
        if d == 0 {
            count += 1;
        }
    }
    count2 += count;
    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {count}");
    println!("Part 2: {count2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
