use std::env;
use std::time::Instant;

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let mut parts = data.split("\n\n");
    let ranges = parts.next().unwrap();
    let ingredients = parts.next().unwrap();

    let mut good: Vec<(u64,u64)> = Vec::new();

    ranges.lines().map(|s| s.split("-").map(|v| v.parse::<u64>().unwrap())
        .collect::<Vec<_>>()).for_each(|r| good.push((r[0],r[1])));
    
    let mut sum1 = 0;

    'outer: for i in ingredients.lines().map(|l| l.parse().unwrap()) {
        for (a,b) in &good {
            if *a <= i && i <= *b {
                sum1 += 1;
                continue 'outer;
            }
        }
    }

    good.sort();
    let sum2: u64 = good.into_iter().fold(Vec::<(u64,u64)>::new(), 
        |acc,x| {
            if acc.len() == 0 {
                acc.into_iter().chain([x]).collect()
            }
            else {
                let l = acc.last().unwrap();
                if l.0 <= x.0 && x.1 <= l.1 {
                    acc
                }
                else if x.0 <= l.1 {
                    acc[..acc.len()-1].into_iter().cloned().chain([(l.0,x.1)]).collect()        
                }
                else if l.1 < x.0 {
                    acc.into_iter().chain([x]).collect()
                }
                else {
                    panic!()
                }
            }
        }
    ).iter().map(|x| x.1-x.0+1).sum();

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
