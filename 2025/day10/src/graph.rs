use std::collections::HashSet;
use std::collections::VecDeque;

// undirected graph on n vertices with neighbor lists
pub struct Graph {
    edges: Vec<HashSet<usize>>,
}

impl Graph {
    pub fn new(num_vertices: usize) -> Graph {
        Graph {
            edges: (0..num_vertices).map(|_| HashSet::new()).collect()
        }
    }

    pub fn add_edge(&mut self, u: usize, v: usize) {
        self.edges[u].insert(v);
        self.edges[v].insert(u);
    }

    pub fn num_vertices(&self) -> usize {
        self.edges.len()
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
