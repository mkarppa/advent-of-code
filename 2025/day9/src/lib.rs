use std::ops::{Index,IndexMut};
use std::fmt;
use std::cmp::{max,min,PartialEq,PartialOrd,Ordering};
use std::collections::HashSet;
use std::ops::{Add,AddAssign,Sub};

pub struct Matrix {
    pub rows: usize,
    pub cols: usize,
    data: Vec<i64>,
}

pub struct MatrixViewMut<'a> {
    pub rows: usize,
    pub cols: usize,
    start: usize,
    stride: usize,
    data: &'a mut Vec<i64>,
}

pub struct MatrixViewMutIter<'a> {
    i: usize,
    j: usize,
    m: &'a MatrixViewMut<'a>,
}

pub struct MatrixView<'a> {
    pub rows: usize,
    pub cols: usize,
    start: usize,
    stride: usize,
    data: &'a Vec<i64>,
}

pub struct MatrixViewIter<'a> {
    i: usize,
    j: usize,
    m: &'a MatrixView<'a>,
}

impl Matrix {
    pub fn zeros(rows: usize, cols: usize) -> Matrix {
        Matrix {
            rows, 
            cols, 
            data: vec![0;rows*cols],
        }
    }

    pub fn view(&self) -> MatrixView {
        MatrixView { 
            rows: self.rows, 
            cols: self.cols, 
            start: 0, 
            stride: self.cols, 
            data: &self.data,
        }
    }

    pub fn view_mut(&mut self) -> MatrixViewMut {
        MatrixViewMut { 
            rows: self.rows, 
            cols: self.cols, 
            start: 0, 
            stride: self.cols, 
            data: &mut self.data,
        }
    }
}

impl<'a> MatrixView<'a> {
    pub fn max(&self) -> i64 {
        *self.iter().reduce(|x,y| max(x,y)).unwrap()
    }

    pub fn min(&self) -> i64 {
        *self.iter().reduce(|x,y| min(x,y)).unwrap()
    }

    pub fn iter(&self) -> MatrixViewIter {
        MatrixViewIter {
            i: 0, 
            j: 0, 
            m: self,
        }
    }

    pub fn row(&self, i: usize) -> MatrixView<'a> {
        MatrixView {
            rows: 1, 
            cols: self.cols, 
            start: self.start + i*self.stride, 
            stride: self.stride, 
            data: &self.data,            
        }
    }

    pub fn col(&self, j: usize) -> MatrixView<'a> {
        MatrixView {
            rows: self.rows,
            cols: 1,
            start: self.start + j,
            stride: self.stride,
            data: &self.data,
        }
    }
}

impl<'a> MatrixViewMut<'a> {
    pub fn view(&'a self) -> MatrixView<'a> {
        MatrixView {
            rows: self.rows,
            cols: self.cols,
            start: self.start,
            stride: self.stride,
            data: &self.data,
        }
    }

    pub fn row(&'a mut self, i: usize) -> MatrixViewMut<'a> {
        MatrixViewMut {
            rows: 1, 
            cols: self.cols, 
            start: self.start + i*self.stride, 
            stride: self.stride, 
            data: &mut self.data,            
        }
    }

    pub fn col(&'a mut self, j: usize) -> MatrixViewMut<'a> {
        MatrixViewMut {
            rows: self.rows,
            cols: 1,
            start: self.start + j,
            stride: self.stride,
            data: &mut self.data,
        }
    }

    pub fn iter(&self) -> MatrixViewMutIter {
        MatrixViewMutIter {
            i: 0,
            j: 0,
            m: self,
        }
    }
}

impl<'a> Iterator for MatrixViewIter<'a> {
    type Item = &'a i64;

    fn next(&mut self) -> Option<Self::Item> {
        if self.i >= self.m.rows {
            None
        }
        else {
            let v = &self.m[(self.i,self.j)];
            self.j += 1;
            if self.j >= self.m.cols {
                self.j = 0;
                self.i += 1;
            }
            Some(v)
        }
    }
}

impl<'a> Iterator for MatrixViewMutIter<'a> {
    type Item = &'a i64;

    fn next(&mut self) -> Option<Self::Item> {
        if self.i >= self.m.rows {
            None
        }
        else {
            let v = &self.m[(self.i,self.j)];
            self.j += 1;
            if self.j >= self.m.cols {
                self.j = 0;
                self.i += 1;
            }
            Some(v)
        }
    }
}

impl fmt::Display for Matrix {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        self.view().fmt(f)
    }
}

impl<'a> fmt::Display for MatrixView<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let maximal = self.max();
        let minimal = self.min();

        let elem_size = match (maximal,minimal) {
            (0,0) => 1,
            (ma,mi) if mi < 0 => ((max(ma.abs(),mi.abs()) as f64).log10()
                                    .ceil() as usize) + 1,
            _ => (maximal as f64).log10().ceil() as usize,
        };

        if self.rows == 0 {
            write!(f,"[]\n")?;
        }
        for i in 0..self.rows {
            write!(f, "[ ")?;
            write!(f, "{}", (0..self.cols)
                .map(|j| format!("{:1$}",self[(i,j)],elem_size))
                .reduce(|x,y| x + " " + &y).unwrap()
            )?;
            write!(f, " ]\n")?;
        }
        Ok(())
    }
}

impl<'a> fmt::Display for MatrixViewMut<'a> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        self.view().fmt(f)
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

impl<'a> Index<(usize,usize)> for MatrixView<'a> {
    type Output = i64;

    fn index(&self, index: (usize,usize)) -> &Self::Output {
        &self.data[self.start + index.0 * self.stride + index.1]
    }
}

impl<'a> Index<(usize,usize)> for MatrixViewMut<'a> {
    type Output = i64;

    fn index(&self, index: (usize,usize)) -> &Self::Output {
        &self.data[self.start + index.0 * self.stride + index.1]
    }
}


impl<'a> IndexMut<(usize,usize)> for MatrixViewMut<'a> {
    fn index_mut(&mut self, index: (usize,usize)) -> &mut Self::Output {
        &mut self.data[self.start + index.0 * self.stride + index.1]
    }
}



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
}

pub struct VariableWidthMatrix {
    rows: usize,
    cols: usize,
    height: usize,
    width: usize,
    heights: Vec<usize>,
    widths: Vec<usize>,
    data: Vec<i64>,
}

impl VariableWidthMatrix {
    pub fn new(ys: &[usize], xs: &[usize]) -> VariableWidthMatrix {
        let rows = ys.len();
        let cols = xs.len();
        let mut widths = Vec::new();
        let mut heights = Vec::new();
        for i in 1..xs.len() {
            widths.push(xs[i]-xs[i-1]);
        }
        widths.push(1);
        let width = widths.iter().sum();
        for i in 1..ys.len() {
            heights.push(ys[i]-ys[i-1]);
        }
        heights.push(1);
        let height = heights.iter().sum();

        VariableWidthMatrix {
            rows: rows,
            cols: cols,
            height: height,
            width: width,
            heights: heights,
            widths: widths,
            data: vec![0;rows*cols],
        }
    }

    pub fn cols(&self) -> usize {
        self.cols
    }

    pub fn rows(&self) -> usize {
        self.rows
    }

    pub fn height(&self) -> usize {
        self.height
    }

    pub fn width(&self) -> usize {
        self.height
    }

    pub fn row_height(&self, i: usize) -> usize {
        self.heights[i]
    }

    pub fn col_width(&self, j: usize) -> usize {
        self.widths[j]
    }
}

impl Index<(usize,usize)> for VariableWidthMatrix {
    type Output = i64;

    fn index(&self, index: (usize,usize)) -> &Self::Output {
        &self.data[index.0 * self.cols + index.1]
    }
}

impl IndexMut<(usize,usize)> for VariableWidthMatrix {
    fn index_mut(&mut self, index: (usize,usize)) -> &mut Self::Output {
        &mut self.data[index.0 * self.cols + index.1]
    }
}

impl Index<&Point2d> for VariableWidthMatrix {
    type Output = i64;

    fn index(&self, index: &Point2d) -> &Self::Output {
        &self[(index.i as usize, index.j as usize)]
    }
}

impl IndexMut<&Point2d> for VariableWidthMatrix {
    fn index_mut(&mut self, index: &Point2d) -> &mut Self::Output {
        &mut self[(index.i as usize, index.j as usize)]
    }
}

pub enum Direction {
    EAST,
    NORTH,
    WEST,
    SOUTH,
}

impl Direction {
    pub fn left(&self) -> Direction {
        match self {
            Direction::EAST => Direction::NORTH,
            Direction::NORTH => Direction::WEST,
            Direction::WEST => Direction::SOUTH,
            Direction::SOUTH => Direction::EAST,
        }
    }

    pub fn right(&self) -> Direction {
        match self {
            Direction::EAST => Direction::SOUTH,
            Direction::NORTH => Direction::EAST,
            Direction::WEST => Direction::NORTH,
            Direction::SOUTH => Direction::WEST,
        }
    }
}

#[derive(Copy,Clone,Debug)]
pub struct Point2d {
    pub i: i64,
    pub j: i64,
}

impl Point2d {
    pub fn new(i: i64, j: i64) -> Point2d {
        Point2d {
            i: i,
            j: j,
        }
    }
}

impl From<&Direction> for Point2d {
    fn from(dir: &Direction) -> Self {
        match dir {
            Direction::EAST => Point2d::new(0,1),
            Direction::NORTH => Point2d::new(-1,0),
            Direction::WEST => Point2d::new(0,-1),
            Direction::SOUTH => Point2d::new(1,0),
        }
    }
}

impl fmt::Display for Point2d {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "({},{})",self.i,self.j)
    }
}

impl fmt::Display for Direction {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}",
            match self {
                Direction::EAST => "EAST",
                Direction::NORTH => "NORTH",
                Direction::WEST => "WEST",
                Direction::SOUTH => "SOUTH",
            })
    }
}

impl Add for Point2d {
    type Output = Self;

    fn add(self, other: Self) -> Self {
        Self {
            i: self.i + other.i,
            j: self.j + other.j,
        }
    }
}

impl Sub for Point2d {
    type Output = Self;

    fn sub(self, other: Self) -> Self {
        Self {
            i: self.i - other.i,
            j: self.j - other.j,
        }
    }
}


impl AddAssign for Point2d {
    fn add_assign(&mut self, rhs: Self) {
        self.i += rhs.i;
        self.j += rhs.j;
    }
}

impl PartialEq for Point2d {
    fn eq(&self, other: &Self) -> bool {
        self.i == other.i && self.j == other.j
    }
}

impl PartialOrd for Point2d {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some((self.i,self.j).cmp(&(other.i,other.j)))
    }
}

impl From<Point2d> for Direction {
    fn from(p: Point2d) -> Self {
        if p.i == 0 && p.j > 0 {
            Direction::EAST
        }
        else if p.i < 0 && p.j == 0 {
            Direction::NORTH
        }
        else if p.i == 0 && p.j < 0 {
            Direction::WEST
        }
        else if p.i > 0 && p.j == 0 {
            Direction::SOUTH
        }
        else {
            panic!()
        }
    }
}