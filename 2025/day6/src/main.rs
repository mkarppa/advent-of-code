use std::env;
use std::time::Instant;
use std::iter::zip;

use day6::*;

const MULTIPLY: i64 = 1;
const ADD: i64 = 2;

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let rows = data.trim().lines().count() - 1;
    let cols = data.lines().next().unwrap().split_whitespace().count();
    let mut ops = vec![0;cols];
    let mut m = Matrix::zeros(rows,cols);
    let mut m = m.view_mut();

    for (i,line) in data.trim().lines().enumerate() {
        if i >= rows {
            for (j,o) in line.split_whitespace().enumerate() {
                match o {
                    "*" => ops[j] = MULTIPLY,
                    "+" => ops[j] = ADD,
                    _ => panic!(),
                }
            }
        }
        else {
            for (j,v) in line.split_whitespace().enumerate() {
                m[(i,j)] = v.parse().unwrap();
            }
        }
    }

    let mut sum1 = 0;
    let m = m.view();
    for j in 0..cols {
        if ops[j] == MULTIPLY{
            sum1 += m.col(j).iter().fold(1,|x,y| x*y);
        }
        else if ops[j] == ADD {
            sum1 += m.col(j).iter().fold(0,|x,y| x+y);
        }
    }

    println!("{rows} {cols}");
    let last_line = data.lines().last().unwrap();
    let mut col_widths: Vec<usize> = last_line.chars()
        .enumerate().filter(|c| c.1 != ' ').map(|c| c.0).collect();
    for i in 0..cols-1 {
        col_widths[i] = col_widths[i+1] - col_widths[i] - 1;
    }
    col_widths[cols-1] = last_line.len() - col_widths.last().unwrap();

    let col_starts: Vec<usize> = last_line.chars()
        .enumerate().filter(|c| c.1 != ' ').map(|c| c.0).collect();
    let col_widths: Vec<usize> = zip(col_starts.iter().skip(1)
                                        .map(|x| *x).chain([last_line.len()+1]),
                                        col_starts.iter())
        .map(|x| x.0 - x.1 - 1).collect();

    let cols: usize = col_widths.iter().sum();

    let mut m = Matrix::zeros(rows,cols);
    let mut m = m.view_mut();

    for (i,line) in data.lines().enumerate() {
        if i >= rows {
            break;
        }
        
        let mut it = line.chars();
        let mut j = 0;
        for k in 0..ops.len() {
            for _ in 0..col_widths[k] {
                m[(i,j)] = match it.next().unwrap() {
                    ' ' => -1,
                    c if c >= '0' && c <= '9' => c as i64 - '0' as i64,
                    _ => panic!(),
                };
                j += 1;
            }
            it.next();
        }
    }

    let mut sum2 = 0;
    let mut j = 0;
    let m = m.view();
    for (k,o) in ops.iter().enumerate() {
        let mut s = match *o {
            MULTIPLY => 1,
            ADD => 0,
            _ => panic!(),
        };
        for _ in 0..col_widths[k] {
            let v: i64 = m.col(j).iter().filter(|x| **x >= 0)
                .fold(String::new(), |x,y| x + &y.to_string())
                .parse().unwrap();
            if *o == MULTIPLY {
                s *= v;
            }
            else {
                s += v;
            }
            j += 1;
        }
        sum2 += s;
    }

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
