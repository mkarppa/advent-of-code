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

int solve(int64_t* data, int num_rows, int64_t lb, int64_t ub) {
  int S = 0;
  for (int i = 0; i < num_rows; ++i) {
    int64_t* d1 = data + 6*i;
    double p1x = d1[0];
    double p1y = d1[1];
    double v1x = d1[3];
    double v1y = d1[4];
    for (int j = i+1; j < num_rows; ++j) {
      int64_t* d2 = data + 6*j;
      double p2x = d2[0];
      double p2y = d2[1];
      double v2x = d2[3];
      double v2y = d2[4];
      bool parallel = fabs(v2x-v2y*v1x/v1y) < 1e-6;
      double t2 = parallel ? -1 : ((p1x - p2x) + (p2y-p1y)*v1x/v1y)/(v2x-v2y*v1x/v1y);
      double t1 = parallel ? -1 : (p2x-p1x+v2x*t2)/v1x;
      if (!parallel && t1 > 0 && t2 > 0) {
        double ix = p1x + v1x*t1;
        double iy = p1y + v1y*t1;
        if (lb <= ix && ix <= ub && lb <= iy && iy <= ub)
          ++S;          
      }
    }
  }
  return S;
}

int main(int argc, char* argv[]) {
  struct timespec start, end;
  timespec_get(&start, TIME_UTC);

  if (argc != 4) {
    fprintf(stderr, "usage: %s <input.txt> <lb> <ub>\n", argv[0]);
    return EXIT_FAILURE;
  }
  int64_t lb, ub;
  sscanf(argv[2], "%" SCNd64, &lb);
  sscanf(argv[3], "%" SCNd64, &ub);
  int64_t data[MAX_ROWS*6];
  int num_rows;

  read_data(argv[1], data, &num_rows);
  timespec_get(&end, TIME_UTC);
  printf("data read in %s\n", format_time(time_diff(&start, &end))); 

  printf("%d\n", solve(data, num_rows, lb, ub));

  timespec_get(&end, TIME_UTC);
  printf("solved in %s\n", format_time(time_diff(&start, &end)));
  return EXIT_SUCCESS;
}
