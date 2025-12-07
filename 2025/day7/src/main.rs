use std::env;
use std::time::Instant;
use std::collections::HashSet;
use std::collections::HashMap;

use day7::*;

const EMPTY: i64 = 0;
const SPLITTER: i64 = 1;
const BEAM: i64 = 2;

#[allow(dead_code)]
fn print_map(map: &MatrixView, s: (usize,usize)) {
    for i in 0..map.rows {
        for j in 0..map.cols {
            print!("{}",
                if i == s.0 && j == s.1 {
                    "S"
                }
                else {
                    match map[(i,j)] {
                        EMPTY => ".",
                        SPLITTER => "^",
                        BEAM => "|",
                        _ => panic!(),
                    }
                }
            );
        }
        println!();
    }
}

fn solve(s: (usize,usize), rows: usize, splitters: &HashSet<(usize,usize)>, 
    cache: &mut HashMap<(usize,usize),usize>) -> usize {
    if let Some(res) = cache.get(&s) {
        *res
    }
    else {
        let (i,j) = s;
        let res = if i == rows-1 { 
            1 
        }
        else if splitters.contains(&(i+1,j)) {
            solve((i+1,j-1), rows, splitters, cache) + 
                solve((i+1,j+1), rows, splitters, cache)
        }
        else {
            solve((i+1,j), rows, splitters, cache)
        };
        cache.insert(s,res);
        res
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let rows = data.trim().lines().count();
    let cols = data.trim().lines().next().unwrap().len();
    let mut map = Matrix::zeros(rows,cols);
    let mut map = map.view_mut();
    let mut s = (0,0);

    let mut splitters: HashSet<(usize,usize)> = HashSet::new();

    for (i,row) in data.trim().lines().enumerate() {
        for (j,c) in row.chars().enumerate() {
            match c {
                '.' => map[(i,j)] = EMPTY,
                'S' => {
                    s = (i,j);
                    map[(i,j)] = BEAM;
                },
                '^' => {
                    splitters.insert((i,j));
                    map[(i,j)] = SPLITTER;
                },

                _ => panic!(),
            };
        }
    }

    let mut sum1 = 0;

    for i in 0..rows-1 {
        for j in 0..cols {
            if map[(i,j)] == BEAM {
                if map[(i+1,j)] == SPLITTER {
                    map[(i+1,j-1)] = BEAM;
                    map[(i+1,j+1)] = BEAM;
                    sum1 += 1;
                }
                else {
                    map[(i+1,j)] = BEAM;
                }
            }
        }
    }

    let mut cache: HashMap<(usize,usize),usize> = HashMap::new();
    let sum2 = solve(s, rows, &splitters, &mut cache);
    
    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
