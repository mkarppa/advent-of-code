use std::env;
use std::time::Instant;
use std::ops::{Index,IndexMut};
use std::fmt;
use std::cmp::max;
use std::collections::HashMap;

struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<i64>,
}

impl Matrix {
    fn new(rows: usize, cols: usize) -> Matrix {
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

fn turn_on_exactly(bank: &str, needed: usize, 
                    cache: &mut HashMap<(String,usize),i64>)->i64 {
    let key = (bank.to_owned(),needed);
    if let Some(v) = cache.get(&key) {
        *v
    }
    else {
        let v;
        if bank.len() == 0  || needed == 0 || needed > bank.len() {
            v = 0
        }
        else if needed == 1 && bank.len() == 1 {
            v = bank.parse().unwrap();
        }
        else if needed == 1 {
            let v1 = bank[0..1].parse().unwrap();
            let v2 = turn_on_exactly(&bank[1..],needed, cache);
            v = max(v1,v2);
        }
        else {
            let v1 = format!("{}{}",&bank[0..1],
                turn_on_exactly(&bank[1..],needed-1,cache)).parse().unwrap();
            let v2 = turn_on_exactly(&bank[1..],needed, cache);
            v = max(v1,v2);
        }
        cache.insert(key,v);
        v
    }
}


fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let rows = data.trim().split("\n").count();
    let cols = data.find("\n").unwrap();

    let mut banks = Matrix::new(rows,cols);

    for (i,line) in data.trim().split("\n").enumerate() {
        for (j,c) in line.chars().enumerate() {
            banks[(i,j)] = c as i64 - '0' as i64;
        }
    }

    let mut max_to_right = Matrix::new(rows,cols);
    for i in 0..rows {
        for j in (0..cols-1).rev() {
            max_to_right[(i,j)] = max(banks[(i,j+1)], max_to_right[(i,j+1)]);
        }
    }

    let mut sum1 = 0;
    
    for i in 0..rows {
        let mut biggest = 0;
        for j in 0..cols-1 {
            let val = banks[(i,j)]*10 + max_to_right[(i,j)];
            if val > biggest {
                biggest = val;
            }
        }
        sum1 += biggest;
    }

    let mut sum2 = 0;
    let mut cache: HashMap<(String,usize),i64> = HashMap::new();
    for line in data.trim().split("\n") {
        let v = turn_on_exactly(line,12,&mut cache);
        sum2 += v;
    }

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
