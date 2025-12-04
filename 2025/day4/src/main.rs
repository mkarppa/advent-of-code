use std::env;
use std::time::Instant;
use std::ops::{Index,IndexMut};
use std::fmt;
use std::cmp::max;
use std::collections::HashMap;

const EMPTY: i64 = 0;
const PAPER: i64 = 1;

pub struct Matrix {
    pub rows: usize,
    pub cols: usize,
    data: Vec<i64>,
}

impl Matrix {
    pub fn zeros(rows: usize, cols: usize) -> Matrix {
        Matrix {
            rows, 
            cols, 
            data: vec![0;rows*cols],
        }
    }
}

impl Index<(usize,usize)> for Matrix {
    type Output = i64;

    fn index(&self, index: (usize,usize)) -> &Self::Output {
        &self.data[index.0 * self.cols + index.1]
    }
}

impl IndexMut<(usize,usize)> for Matrix {
    fn index_mut(&mut self, index: (usize,usize)) -> &mut Self::Output {
        &mut self.data[index.0 * self.cols + index.1]
    }
}

impl fmt::Display for Matrix {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.rows == 0 {
            write!(f,"[]\n")?;
        }
        for i in 0..self.rows {
            write!(f, "[")?;
            for j in 0..self.cols {
                write!(f,"{:1}",self[(i,j)])?;
            }
            write!(f, "]\n")?;
        }
        Ok(())
    }
}

fn print_map(map: &Matrix) {
    for i in 1..map.rows-1 {
        for j in 1..map.cols-1 {
            match map[(i,j)] {
                EMPTY => print!("."),
                PAPER => print!("@"),
                _ => panic!(),
            }
        }
        println!();
    }
}

fn neighborhood_sum(map: &Matrix, i: usize, j: usize) -> i64 {
    map[(i-1,j-1)] + map[(i-1,j)] + map[(i-1,j+1)] +
    map[(i  ,j-1)] +                map[(i  ,j+1)] +
    map[(i+1,j-1)] + map[(i+1,j)] + map[(i+1,j+1)]
}

fn solve1(map: &Matrix)->i64 {
    let mut sum = 0;
    for i in 1..map.rows-1 {
        for j in 1..map.cols-1 {
            if map[(i,j)] == PAPER && neighborhood_sum(map,i,j) < 4 {
                sum += 1;
            }
        }
    }
    sum
}

fn solve2(map: &mut Matrix)->i64 {
    let mut sum = 0;
    let mut should_quit = false;
    while !should_quit {
        should_quit = true;
        for i in 1..map.rows-1 {
            for j in 1..map.cols-1 {
                if map[(i,j)] == PAPER && neighborhood_sum(map,i,j) < 4 {
                    should_quit = false;
                    sum += 1;
                    map[(i,j)] = EMPTY;
                }
            }
        }
    }
    sum
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let rows = data.trim().split("\n").count();
    let cols = data.find("\n").unwrap();

    let mut map = Matrix::zeros(rows+2,cols+2);
    for (i,row) in data.trim().split("\n").enumerate() {
        for (j,col) in row.chars().enumerate() {
            map[(i+1,j+1)] = match col {
                '.' => EMPTY,
                '@' => PAPER,
                _ => panic!()
            }
        }
    }

    let sum1 = solve1(&map);
    let sum2 = solve2(&mut map);

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
