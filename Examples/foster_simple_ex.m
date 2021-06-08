syms s;

% First form example
p2 = 2.48*s/(3.93*s^2 + 1);
[L, C] = fost2el(p2);
displ("L = ", L);
displ("C = ", C);

% Second form example
p2y = 2.498*s/(.6346*s^2 + 1);
[C, L] = fost2el(p2y);
displ(" ");
displ("L = ", L);
displ("C = ", C);
