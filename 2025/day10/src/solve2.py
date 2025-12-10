#!/usr/bin/env python3

from scipy.optimize import milp, Bounds, LinearConstraint
import numpy as np
import sys

if __name__ == '__main__':
    with open(sys.argv[1],'r') as f:
        lines = f.readlines()

    S = 0
    for line in lines:
        buttons = line.strip().split(' ')[1:]
        joltages = np.array(list(map(int,buttons[-1].strip('{}').split(','))))
        buttons = [list(map(int,b.strip('()').split(','))) for b in buttons[:-1]]
        c = np.ones(len(buttons),dtype=np.int64)
        A = np.zeros((len(joltages),len(buttons)),dtype=np.int64)
        for j in range(len(buttons)):
            for b in buttons[j]:
                A[b,j] = 1
        sol = milp(c,integrality=1,bounds=Bounds(0,np.amax(joltages)),
                  constraints=LinearConstraint(A,joltages,joltages))
        S += int(round(sol.x.sum()))
    print(S)