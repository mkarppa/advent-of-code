use std::env;
use std::time::Instant;
use std::collections::{HashSet,HashMap};
use day11::graph::{Graph,DirectedGraph};


fn main() {
    let args: Vec<String> = env::args().collect();
    let filename = &args[1];
    let data = std::fs::read_to_string(filename).unwrap();
   
    let start = Instant::now();

    let mut vertices: HashSet<String> = HashSet::new();
    for line in data.lines() {
        let vv: Vec<_> = line.split(": ").collect();
        vertices.insert(vv[0].to_owned());
        for v in vv[1].split(" ") {
            vertices.insert(v.to_owned());
        }
    }
    let vertices_to_id: HashMap<&str,usize> = vertices.iter().enumerate().map(|(i,v)| (v.as_str(),i)).collect();

    let mut g = DirectedGraph::new(vertices.len());
    for line in data.lines() {
        let vv: Vec<_> = line.split(": ").collect();
        let u = vertices_to_id[&vv[0]];
        for vs in vv[1].split(" ") {
            let v = vertices_to_id[&vs];
            g.add_edge(u,v);
        }   
    }

    let mut sum1 = 0;

    let mut cache: HashMap<(usize,usize),usize> = HashMap::new();

    if vertices_to_id.contains_key("you") {
        let startid = vertices_to_id["you"];
        let endid = vertices_to_id["out"];
        sum1 = g.count_paths_between_with_cache(startid,endid,&mut cache);
    }

    let mut sum2 = 0;
    if vertices_to_id.contains_key("svr") {
        let n1id = vertices_to_id["fft"];
        let n2id = vertices_to_id["dac"];
        let startid = vertices_to_id["svr"];
        let endid = vertices_to_id["out"];
        // sum2 = g.count_paths_between_through_n12(startid,endid,n1id,n2id);
        // sum1 = g.count_paths_between(startid,endid);
        // sum2 = g.count_paths_between_through_n12(startid,endid,n1id,n2id);
        // println!("paths svr->fft {}", g.count_paths_between(startid,n1id));
        let s1 = g.count_paths_between_with_cache(startid,n1id,&mut cache);
        let s2 = g.count_paths_between_with_cache(n1id,n2id,&mut cache);
        let s3 = g.count_paths_between_with_cache(n2id,endid,&mut cache);

        let s4 = g.count_paths_between_with_cache(startid,n2id,&mut cache);
        let s5 = g.count_paths_between_with_cache(n2id,n1id,&mut cache);
        let s6 = g.count_paths_between_with_cache(n1id,endid,&mut cache);

        sum2 = s1*s2*s3 + s4*s5*s6;
    }

    let end = Instant::now();
    let tdelta = end - start;

    println!("Part 1: {sum1}");
    println!("Part 2: {sum2}");

    println!("Took {} s", tdelta.as_nanos() as f64 / 1e9);
}