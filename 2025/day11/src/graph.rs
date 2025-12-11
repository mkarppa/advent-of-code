use std::collections::{HashMap,HashSet,VecDeque};

// shared graph behavior
pub trait Graph {
    type Vertex;

    fn add_edge(&mut self, u: Self::Vertex, v: Self::Vertex);
    fn num_vertices(&self) -> usize;
}

// undirected graph on n vertices with neighbor lists
pub struct UndirectedGraph {
    edges: Vec<HashSet<usize>>,
}

impl UndirectedGraph {
    pub fn new(num_vertices: usize) -> UndirectedGraph {
        UndirectedGraph {
            edges: (0..num_vertices).map(|_| HashSet::new()).collect()
        }
    }

    pub fn extract_connected_component(&self, u: usize) -> Vec<usize> {
        let mut visited = vec![false; self.num_vertices()];
        let mut stack = vec![u];
        let mut res = Vec::new();

        while let Some(v) = stack.pop() {
            if !visited[v] {
                res.push(v);
                visited[v] = true;
                for w in &self.edges[v] {
                    stack.push(*w);
                }
            }
        }

        res
    }

    // bfs
    // returns the first node that satisfies the predicate and the shortest 
    // path from start to the node
    pub fn bfs<F>(&self, start: usize, pred: F) -> Option<(usize,Vec<usize>)>
        where F: Fn(usize) -> bool {
        const NOT_VISITED: usize = !0;
        const FIRST: usize = NOT_VISITED-1;
        let mut predecessors = vec![NOT_VISITED; self.num_vertices()];
        let mut queue = VecDeque::from([(start,FIRST)]);

        while let Some((u,from)) = queue.pop_front() {
            if predecessors[u] == NOT_VISITED {
                predecessors[u] = from;

                if pred(u) {
                    let mut path = vec![u];
                    let mut v = predecessors[u];
                    while v != FIRST {
                        path.push(v);
                        v = predecessors[v];
                    }
                    path = path.into_iter().rev().collect();

                    return Some((u,path))
                }
                else {
                    for v in &self.edges[u] {
                        if predecessors[*v] == NOT_VISITED {
                            queue.push_back((*v,u));
                        }
                    }
                }
            }
        }
        None
    }
}

impl Graph for UndirectedGraph {
    type Vertex = usize;
    
    fn add_edge(&mut self, u: usize, v: usize) {
        self.edges[u].insert(v);
        self.edges[v].insert(u);
    }

    fn num_vertices(&self) -> usize {
        self.edges.len()
    }
}


// directed graph
pub struct DirectedGraph {
    edges: Vec<HashSet<usize>>,
}

impl DirectedGraph {
    pub fn new(num_vertices: usize) -> DirectedGraph {
        DirectedGraph {
            edges: (0..num_vertices).map(|_| HashSet::new()).collect(),
        }
    }

    pub fn has_cycle(&self) -> bool {
        type Vertex = <DirectedGraph as Graph>::Vertex;
        fn visit(u: Vertex, 
            edges: &Vec<HashSet<Vertex>>,
            discovered: &mut HashSet<Vertex>, 
            finished: &mut HashSet<Vertex>) -> bool{
            discovered.insert(u);
            for v in &edges[u] {
                if discovered.contains(v) {
                    return true;
                }
                if !finished.contains(v) {
                    if visit(*v,edges,discovered,finished) {
                        return true;
                    }
                }
            }
            discovered.remove(&u);
            finished.insert(u);
            false
        }

        let mut discovered = HashSet::new();
        let mut finished = HashSet::new();
        for u in 0..self.num_vertices() {
            if !discovered.contains(&u) && !finished.contains(&u) {
                if visit(u, &self.edges, &mut discovered, &mut finished) {
                    return true;
                }
            }
        }
        false
    }

    pub fn count_paths_between(&self, start: usize, end: usize) -> usize {
        let mut stack: Vec<usize> = vec![start];
        let mut res = 0;
        while let Some(u) = stack.pop() {
            if u == end {
                res += 1;
            }
            else {
                for v in &self.edges[u] {
                    stack.push(*v);
                }
            }
        }
        res
    }

    pub fn count_paths_between_with_cache(&self, start: usize, 
        end: usize, cache: &mut HashMap<(usize,usize),usize>) -> usize {
        let mut res = 0;
        if cache.contains_key(&(start,end)) {
            res = cache[&(start,end)];
        }
        else {
            if self.edges[start].contains(&end) {
                res = 1
            }
            else {
                for v in &self.edges[start] {
                    res += self.count_paths_between_with_cache(*v,end,cache);
                }
            }
            cache.insert((start,end),res);
        }
        res
    }
}

impl Graph for DirectedGraph {
    type Vertex = usize;

    fn add_edge(&mut self, u: Self::Vertex, v: Self::Vertex) {
        self.edges[u].insert(v);
    }

    fn num_vertices(&self) -> usize {
        self.edges.len()
    }
}