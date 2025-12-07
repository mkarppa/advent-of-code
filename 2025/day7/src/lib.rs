use std::ops::{Index,IndexMut};
use std::fmt;
use std::cmp::{max,min};

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
