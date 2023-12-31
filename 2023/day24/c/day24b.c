#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <inttypes.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#define MAX_LINE_LENGTH 128
#define MAX_ROWS 300

static void read_data(char* filename, int64_t* data, int* num_rows) {
  static char line[MAX_LINE_LENGTH];
  FILE* f = fopen(filename, "r");
  int64_t* d = data;
  *num_rows = 0;
  while (fgets(line, MAX_LINE_LENGTH, f)) {
    char* p = strchr(line,'@');
    *p++ = '\0';

    char* q = strtok(line, ",");
    sscanf(q, "%" SCNd64, d++);
    q = strtok(NULL, ",");
    sscanf(q, "%" SCNd64, d++);
    q = strtok(NULL, ",");
    sscanf(q, "%" SCNd64, d++);
    q = strtok(p, ",");
    sscanf(q, "%" SCNd64, d++);
    q = strtok(NULL, ",");
    sscanf(q, "%" SCNd64, d++);
    q = strtok(NULL, ",");
    sscanf(q, "%" SCNd64, d++);

    ++*num_rows;
  }
  fclose(f);
}

static double time_diff(struct timespec* start, struct timespec* end) {
  double ed = end->tv_sec + end->tv_nsec/1e9;
  double sd = start->tv_sec + start->tv_nsec/1e9;
  return ed - sd;  
}

static double absmax_in_range(const double* begin, const double* end) {
  double m = fabs(*begin++);
  while (begin < end) {
    if (fabs(*begin) > m)
      m = fabs(*begin);
    ++begin;
  }
  return m;
}

static void swap_row(double* A, int n, int i1, int i2) {
  for (int j = 0; j < n; ++j) {
    double t = A[n*i1+j];
    A[n*i1+j] = A[n*i2+j];
    A[n*i2+j] = t;
  }
}

static void mulsub(double* A, int n, int i0, int i, double f) {
  for (int j = 0; j < n; ++j) {
    A[n*i0+j] -= A[n*i+j]*f;
  }
}


static char* format_time(double secs) {
  static char buffer[256];
  if (secs >= 3600) {
    int hs = secs / 3600;
    int mins = (secs - hs*3600) / 60;
    int ss = secs - hs*3600 - mins*60;
    sprintf(buffer, "%d h %d min %d s", hs, mins, ss);
  }
  else if (secs >= 60) {
    int mins = secs / 60;
    int ss = secs - mins*60;
    sprintf(buffer, "%d min %d s", mins, ss);
  }
  else if (secs >= 1) {
    sprintf(buffer, "%.3f s", secs);
  }
  else if (secs >= 1e-3) {
    sprintf(buffer, "%.3f ms", secs*1e3);
  }
  else if (secs >= 1e-6) {
    sprintf(buffer, u8"%.3f μs", secs*1e6);
  }
  else if (secs >= 1e-9) {
    sprintf(buffer, "%.3f ns", secs*1e9);
  }
  else {
    sprintf(buffer, "0");
  }
  return buffer;
}

uint64_t solve(int64_t* data) {
  double x1 = data[0];
  double y1 = data[1];
  double z1 = data[2];
  double vx1 = data[3];
  double vy1 = data[4];
  double vz1 = data[5];

  double x2 = data[6];
  double y2 = data[7];
  double z2 = data[8];
  double vx2 = data[9];
  double vy2 = data[10];
  double vz2 = data[11];

  double x3 = data[12];
  double y3 = data[13];
  double z3 = data[14];
  double vx3 = data[15];
  double vy3 = data[16];
  double vz3 = data[17];

  const int n = 6;

  double A[] = {
    0, -vz1 + vz2, vy1-vy2, 0, z1-z2, -y1+y2,
    vz1-vz2, 0, -vx1+vx2, -z1+z2, 0, x1-x2,
    -vy1+vy2, vx1-vx2, 0, y1-y2, -x1+x2, 0,
    0, -vz1 + vz3, vy1-vy3, 0, z1-z3, -y1+y3,
    vz1-vz3, 0, -vx1+vx3, -z1+z3, 0, x1-x3,
    -vy1+vy3, vx1-vx3, 0, y1-y3, -x1+x3, 0,    
  };

  double b[] = {
    vy2*z2+vz1*y1-vz2*y2-vy1*z1,
    -vz1*x1+vz2*x2+vx1*z1-vx2*z2,
    vy1*x1-vy2*x2-vx1*y1+vx2*y2,
    vy3*z3+vz1*y1-vz3*y3-vy1*z1,
    -vz1*x1+vz3*x3+vx1*z1-vx3*z3,
    vy1*x1-vy3*x3-vx1*y1+vx3*y3
  };
  for (int j = 0; j < n; ++j)
    b[j] = -b[j];

  double scale = 100;

  for (int i = 0; i < n*n; ++i)
    A[i] /= scale;

  double AI[] = {
    1, 0, 0, 0, 0, 0,
    0, 1, 0, 0, 0, 0,
    0, 0, 1, 0, 0, 0,
    0, 0, 0, 1, 0, 0,
    0, 0, 0, 0, 1, 0,
    0, 0, 0, 0, 0, 1
  };

  int h = 0;
  int k = 0;
  
  while (h < n && k < n) {
    int i_max = h;
    double rel_max_size = fabs(A[n*h+k])/absmax_in_range(A+n*h+k, A+n*h+n);
    for (int i = h; i < n; ++i) {
      double rel_size = fabs(A[n*i+k])/absmax_in_range(A+n*i+k, A+n*i+n);
      if (rel_size > rel_max_size) {
        i_max = i;
        rel_max_size = rel_size;
      }
    }
    if (A[n*i_max+k] == 0) {
      ++k;
    }
    else {
      if (i_max != h) {
        swap_row(A, n, i_max, h);
        swap_row(AI, n, i_max, h);
      }

      for (int i = h+1; i < n; ++i) {
        double f = A[n*i+k] / A[n*h+k];
        mulsub(A, n, i, h, f);
        mulsub(AI, n, i, h, f);
      }
      ++h;
      ++k;
    }
  }


  for (int h = n-1; h >= 0; --h) {
    double f = A[n*h+h];
    for (int j = 0; j < n; ++j) {
      A[n*h+j] /= f;
      AI[n*h+j] /= f;
    }
    for (int i = h-1; i >= 0; --i) {
      f = A[n*i+h];
      mulsub(A, n, i, h, f);
      mulsub(AI, n, i, h, f);
    }
  }

  double res[3] = { 0, 0, 0 };
  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < n; ++j) {
      res[i] += AI[n*i+j]*b[j]/scale;
    }
    res[i] = round(res[i]);
  }
  return res[0] + res[1] + res[2];
}

int main(int argc, char* argv[]) {
  struct timespec start, end;
  timespec_get(&start, TIME_UTC);

  if (argc != 2) {
    fprintf(stderr, "usage: %s <input.txt>\n", argv[0]);
    return EXIT_FAILURE;
  }
  int64_t data[MAX_ROWS*6];
  int num_rows;

  read_data(argv[1], data, &num_rows);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 

  printf("%" PRIu64 "\n", solve(data));

  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end)));
  return EXIT_SUCCESS;
}
