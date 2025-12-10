use std::env;
use std::time::Instant;
use day10::graph::Graph;


fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();

    let mut sum1 = 0;
    
    let start = Instant::now();

    for line in data.trim().lines() {
        let fields: Vec<_> = line.split(" ").collect();
        let n_bits = fields[0].len()-2;
        let target = fields[0][1..fields[0].len()-1].chars().enumerate()
            .map(|(i,c)| match c {
                '#' =>  1 << i,
                _ => 0
            }).reduce(|x,y| x | y).unwrap();
        let buttons: Vec<_> = fields[1..fields.len()-1].iter()
            .map(|b| b[1..b.len()-1].split(",")
                .map(|b| 1 << b.parse::<usize>().unwrap())
                .reduce(|x,y| x | y).unwrap()).collect();

        let num_states = 1 << n_bits;
        let mut g = Graph::new(num_states);
        for state in 0..num_states {
            for button in &buttons {
                let new_state = state ^ button;
                g.add_edge(state,new_state);
            }
        }
        sum1 += g.bfs(0,|u| u == target).unwrap().1.len()-1;

    }

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}