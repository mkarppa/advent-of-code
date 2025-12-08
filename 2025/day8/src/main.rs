use std::env;
use std::time::Instant;
use day8::{Matrix,Graph};

fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
    let num_connections: usize = args[2].parse().unwrap();
    
    let start = Instant::now();

    let mut coordinates: Vec<(i64,i64,i64)> = Vec::new();

    for line in data.trim().lines() {
        let coords: Vec<i64> = line.split(",").map(|v| v.parse().unwrap()).collect();
        coordinates.push((coords[0],coords[1],coords[2]));
    }

    let n = coordinates.len();
    
    let mut d = Matrix::zeros(n,n);
    let mut pairs: Vec<(usize,usize)> = Vec::new();
    for i in 0..n-1 {
        let x = &coordinates[i];
        for j in i+1..n {
            pairs.push((i,j));
            let y = &coordinates[j];
            let dx = x.0-y.0;
            let dy = x.1-y.1;
            let dz = x.2-y.2;
            let dist = dx*dx + dy*dy + dz*dz;
            d[(i,j)] = dist;
            d[(j,i)] = dist;
        }
    }

    pairs.sort_by(|le,ri| {
        let dle = d[*le];
        let dri = d[*ri];
        dle.cmp(&dri)
    });

    let mut g = Graph::new(n);

    for i in 0..num_connections {
        g.add_edge(pairs[i].0, pairs[i].1);
    }

    let mut components = vec![0;n];
    let mut num_components = 0;
    for u in 0..n {
        if components[u] == 0 {
            num_components += 1;
            for v in g.extract_connected_component(u) {
                components[v] = num_components;
            }
        }
    }
    let mut component_sizes = vec![0;num_components];
    for c in &components {
        component_sizes[c-1] += 1;
    }
    component_sizes.sort_by(|a,b| b.cmp(a));
    let sum1: usize = component_sizes[..3].iter().product();

    
    let mut sum2 = 0;
    for i in num_connections..pairs.len() {
        let (u,v) = pairs[i];
        g.add_edge(u,v);
        if components[u] == 0 || components[v] == 0 || components[u] != components[v] {
            let component_id = components[u];
            let component = g.extract_connected_component(u);
            if component.len() == n {
                sum2 = coordinates[u].0 * coordinates[v].0;
                break;
            }
            for w in component {
                components[w] = component_id;
            }
        }
    }
    
    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}
