use std::env;
use std::time::Instant;
use std::collections::HashSet;
use std::collections::HashMap;
use std::iter::zip;
use std::cmp::min;
use std::cmp::max;
use day9::{VariableWidthMatrix,Point2d,Direction};

enum Handedness {
    LEFT, RIGHT
}

const EMPTY: i64 = 0;
const RED_TILE: i64 = 1;
const GREEN_TILE: i64 = 2;

#[allow(dead_code)]
fn print_map(m: &VariableWidthMatrix) {
    for i in 0..m.rows() {
        for _ in 0..m.row_height(i) {
            for j in 0..m.cols() {
                let c = match m[(i,j)] {
                    EMPTY => '.',
                    RED_TILE => '#',
                    GREEN_TILE => 'X',
                    _ => '?',
                };
                for _ in 0..m.col_width(j) {
                    print!("{c}");
                }
            }
            println!();
        }
    }
}

#[allow(dead_code)]
fn print_compressed_map(m: &VariableWidthMatrix) {
    for i in 0..m.rows() {
        for j in 0..m.cols() {
            let c = match m[(i,j)] {
                EMPTY => '.',
                RED_TILE => '#',
                GREEN_TILE => 'X',
                _ => '?',
            };
            print!("{c}");
        }
        println!();
    }
}


fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    
    let start = Instant::now();

    let pairs: Vec<(usize,usize)> = data.trim().lines()
        .map(|l| l.split(",").collect::<Vec<_>>())
        .map(|v| (v[0].parse().unwrap(), v[1].parse().unwrap())).collect();
    
    let mut sum1 = 0;
    for i in 0..pairs.len()-1 {
        let x = (pairs[i].0 as i64, pairs[i].1 as i64);
        for j in i+1..pairs.len() {
            let y = (pairs[j].0 as i64, pairs[j].1 as i64);
            let width = (y.0-x.0).abs()+1;
            let height = (y.1-x.1).abs()+1;
            let area = width*height;
            if area > sum1 {
                sum1 = area;
            }
        }
    }

    let mut xs: Vec<usize> = pairs.iter().map(|p| p.0 as usize)
        .collect::<HashSet<_>>().into_iter().collect();
    xs.sort();
    assert!(xs[0] > 0);
    for j in 0..xs.len()-1 {
        if xs[j+1]-xs[j] > 1 {
            xs.push(xs[j]+1)
        }
    }
    xs.push(0);
    xs.sort();

    let mut ys: Vec<usize> = pairs.iter().map(|p| p.1 as usize)
        .collect::<HashSet<_>>().into_iter().collect();
    ys.sort();
    assert!(ys[0] > 0);
    for j in 0..ys.len()-1 {
        if ys[j+1]-ys[j] > 1 {
            ys.push(ys[j]+1)
        }
    }
    ys.push(0);
    ys.sort();

    let y_to_i = ys.iter().enumerate().map(|(i,y)| (*y,i)).collect::<HashMap<usize,usize>>();
    let x_to_j = xs.iter().enumerate().map(|(j,x)| (*x,j)).collect::<HashMap<usize,usize>>();

    let mut m = VariableWidthMatrix::new(&ys,&xs);

    let pairs: Vec<_> = pairs.iter()
        .map(|(x,y)| Point2d::new(y_to_i[y] as i64, x_to_j[x] as i64))
        .collect();

    for x in &pairs {
        m[x] = RED_TILE;
    }

    let mut top_left_point = Point2d::new(ys[ys.len()-1] as i64,xs[xs.len()-1] as i64);
    for (x,y) in zip(pairs.iter(), pairs[1..].iter().chain([&pairs[0]])) {
        if x < &top_left_point {
            top_left_point = *x;
        }
        let dir = Point2d::from(&match (x,y) {
            _ if x.i == y.i && x.j < y.j => Direction::EAST,
            _ if x.i > y.i && x.j == y.j => Direction::NORTH,
            _ if x.i == y.i && x.j > y.j => Direction::WEST,
            _ if x.i < y.i && x.j == y.j => Direction::SOUTH,
            _ => panic!(),
        });
        let mut z = *x + dir;
        while z != *y {
            m[&z] = GREEN_TILE;
            z += dir;
        }
    }

    let first_idx = pairs.iter().enumerate().find(|(_,x)| *x == &top_left_point).unwrap().0;
    let mut cur = first_idx;
    let mut next = (cur+1) % pairs.len();
    let inside_handedness = match Direction::from(pairs[next] - pairs[cur]) {
        Direction::EAST => Handedness::RIGHT,
        Direction::SOUTH => Handedness::LEFT,
        _ => panic!(),
    };
    loop {
        let curp = &pairs[cur];
        let nextp = &pairs[next];
        let cur_dir = Direction::from(*nextp-*curp);
        let indir = match inside_handedness {
            Handedness::LEFT => cur_dir.left(),
            Handedness::RIGHT => cur_dir.right(),
        };

        let dp = Point2d::from(&cur_dir);
        let dq = Point2d::from(&indir);
        let mut p = *curp + dp;
        while p != *nextp {
            let mut q = p + dq;
            while m[&q] == EMPTY {
                m[&q] = GREEN_TILE;
                q += dq;
            }
            p += dp;
        }

        cur = next;
        next = (next + 1) % pairs.len();
        if cur == first_idx {
            break;
        }
    }

    let mut sum2 = 0;

    for x in &pairs[..pairs.len()-1] {
        for y in &pairs[1..] {
            let tl = Point2d::new(min(x.i,y.i),min(x.j,y.j));
            let br = Point2d::new(max(x.i,y.i),max(x.j,y.j));

            let width: usize = (tl.j..=br.j).map(|j| m.col_width(j as usize)).sum();
            let height: usize = (tl.i..=br.i).map(|i| m.row_height(i as usize)).sum();
            let area = width*height; 

            if area > sum2 {
                let mut ok = true;
                'okloop: for i in tl.i..=br.i {
                    for j in tl.j..=br.j {
                        if m[(i as usize, j as usize)] == EMPTY {
                            ok = false;
                            break 'okloop;
                        }
                    }
                }
                if ok {
                    sum2 = area;
                }
            }
        }
    }


    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
