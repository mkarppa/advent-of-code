use std::env;
use std::time::Instant;
use std::collections::{HashSet,HashMap};

#[allow(dead_code)]
fn print_shape(shape: &HashSet<(usize,usize)>) {
    for i in 0..3 {
        for j in 0..3 {
            print!("{}",
                if shape.contains(&(i,j)) {
                    "#"
                }
                else {
                    "."
                }
            );
        }
        println!();
    }
}

// id
// 123    123
// 456 -> 456
// 789    789
fn id(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    shape.clone()
}

// rot90
// 123    741
// 456 -> 852
// 789    963
fn rot90(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    let trans: HashMap<(usize,usize),(usize,usize)> = HashMap::from(
        [
            ((0,0), (0,2)),
            ((0,1), (1,2)),
            ((0,2), (2,2)),
            ((1,0), (0,1)),
            ((1,1), (1,1)),
            ((1,2), (2,1)),
            ((2,0), (0,0)),
            ((2,1), (1,0)),
            ((2,2), (2,0)),
        ]
    );
    shape.iter().map(|x| trans[x]).collect()
}

// rot180
// 123    987   
// 456 -> 654
// 789    321
fn rot180(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    let trans: HashMap<(usize,usize),(usize,usize)> = HashMap::from(
        [
            ((0,0), (2,2)),
            ((0,1), (2,1)),
            ((0,2), (2,0)),
            ((1,0), (1,2)),
            ((1,1), (1,1)),
            ((1,2), (1,0)),
            ((2,0), (0,2)),
            ((2,1), (0,1)),
            ((2,2), (0,0)),
        ]
    );
    shape.iter().map(|x| trans[x]).collect()
}

// rot270
// 123    369   
// 456 -> 258
// 789    147
fn rot270(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    let trans: HashMap<(usize,usize),(usize,usize)> = HashMap::from(
        [
            ((0,0), (2,0)),
            ((0,1), (1,0)),
            ((0,2), (0,0)),
            ((1,0), (2,1)),
            ((1,1), (1,1)),
            ((1,2), (0,1)),
            ((2,0), (2,2)),
            ((2,1), (1,2)),
            ((2,2), (0,2)),
        ]
    );
    shape.iter().map(|x| trans[x]).collect()
}

// flipud
// 123    789
// 456 -> 456
// 789    123
fn flipud(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    let trans: HashMap<(usize,usize),(usize,usize)> = HashMap::from(
        [
            ((0,0), (2,0)),
            ((0,1), (2,1)),
            ((0,2), (2,2)),
            ((1,0), (1,0)),
            ((1,1), (1,1)),
            ((1,2), (1,2)),
            ((2,0), (0,0)),
            ((2,1), (0,1)),
            ((2,2), (0,2)),
        ]
    );
    shape.iter().map(|x| trans[x]).collect()
}

// fliplr
// 123    321
// 456 -> 654
// 789    987
fn fliplr(shape: &HashSet<(usize,usize)>) -> HashSet<(usize,usize)> {
    let trans: HashMap<(usize,usize),(usize,usize)> = HashMap::from(
        [
            ((0,0), (0,2)),
            ((0,1), (0,1)),
            ((0,2), (0,0)),
            ((1,0), (1,2)),
            ((1,1), (1,1)),
            ((1,2), (1,0)),
            ((2,0), (2,2)),
            ((2,1), (2,1)),
            ((2,2), (2,0)),
        ]
    );
    shape.iter().map(|x| trans[x]).collect()
}

fn translate(shape: &HashSet<(usize,usize)>, di: usize, dj: usize, width: usize, height: usize) 
    -> Vec<u8> {
    let mut v = vec![0;width*height];
    shape.iter()
    .map(|(i,j)| (i+di)*width + j + dj)
    .for_each(|i| { v[i] = 1 });
    v
}

fn vecs_are_disjoint(a: &Vec<u8>, b: &Vec<u8>) -> bool {
    for i in 0..a.len() {
        if (a[i]&b[i]) != 0 {
            return false;
        }
    }
    return true;
}

fn rec(solution: &mut Vec<u8>,
        shapes: &Vec<Vec<Vec<u8>>>,
        counts: &mut Vec<usize>,
        width: usize, height: usize,
        cache: &mut HashMap<(Vec<u8>,Vec<usize>),bool>
    ) -> bool {
    let key = (solution.clone(), counts.clone());
    if cache.contains_key(&key) {
        return cache[&key];
    }

    for i in 0..counts.len() {
        if counts[i] > 0 {
            counts[i] -= 1;
            for shape in &shapes[i] {
                if vecs_are_disjoint(shape,solution) {
                    for i in 0..shape.len() {
                        if shape[i] == 1 {
                            solution[i] = 1;
                        }
                    }
                    if rec(solution,shapes,counts,width,height,cache) {
                        return true;
                    }
                    for i in 0..shape.len() {
                        if shape[i] == 1 {
                            solution[i] = 0;
                        }
                    }
                }
            }
            counts[i] += 1;
            cache.insert(key,false);
            return false;
        }
    }
    true
}


fn solve(shapes: &Vec<Vec<HashSet<(usize,usize)>>>, counts: &Vec<usize>, 
    width: usize, height: usize) -> bool {
    let grid_area = width * height;
    let total_occupied: usize = counts.iter().enumerate().map(|(i,c)| shapes[i].len() * c).sum();
    if grid_area < total_occupied {
        false
    }
    else if (width/3) * (height/3) >= counts.iter().sum() {
        true
    } 
    else {
        // actually solve the case
        let mut counts = counts.clone();
        let mut solution: Vec<u8> = vec![0;width*height];

        let mut translated_shapes: Vec<Vec<Vec<u8>>> = Vec::new();
        for i in 0..shapes.len() {
            translated_shapes.push(Vec::new());
            for j in 0..shapes[i].len() {
                for di in 0..=height - 3 {
                    for dj in 0..=width - 3 {
                        translated_shapes[i].push(translate(&shapes[i][j],di,dj,width,height));
                    }
                }
                
            }
        }

        let mut cache: HashMap<(Vec<u8>,Vec<usize>),bool> = HashMap::new();
        rec(&mut solution, &translated_shapes, &mut counts, width, height, &mut cache)
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
   
    let start = Instant::now();

    let mut current_shape = 0;
    let mut current_shape_row = 0;
    let mut shapes: Vec<HashSet<(usize,usize)>> = Vec::new();

    let mut sum1 = 0;
    for line in data.lines() {
        if line.len() > 0 {
            if &line[1..2] == ":" {
                current_shape = line[0..1].parse().unwrap();
                current_shape_row = 0;
                shapes.push(HashSet::new());
            }
            else if let Some(_) = line.find(':') {
                break;
            }
            else {
                line.chars().enumerate().filter(|(_,c)| *c == '#')
                    .map(|(i,_)| (current_shape_row,i))
                    .for_each(|c| {
                        shapes[current_shape].insert(c);
                    });
                current_shape_row += 1;
            }
        }
    }

    let transformations = [id, rot90, rot180, rot270, flipud, fliplr];
    let shapes: Vec<Vec<HashSet<(usize,usize)>>> = shapes.iter()
        .map(|s| transformations.iter().map(|t| t(s)).collect::<Vec<_>>())
        .collect();

    for line in data.lines() {
        if line.len() > 0 {
            if let Some(i) = line.find(':') {
                if i != 1{
                    let counts: Vec<usize> = line[i+2..].split(" ")
                        .map(|c| c.parse().unwrap()).collect();
                    let j = line.find('x').unwrap();
                    let width: usize = line[..j].parse().unwrap();
                    let height: usize = line[j+1..i].parse().unwrap();

                    if solve(&shapes, &counts, width, height) {
                       sum1 += 1;
                    }
                }
            }
        }
    }

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
