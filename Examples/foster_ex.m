Zn = [9, 0, 30, 0, 24, 0];
Zd = [18, 0, 36, 0, 8];

[Ls, Cs] = foster1(Zn, Zd);
displ("Inductors: ", Ls)
displ("Capacitors: ", Cs);

[Ls2, Cs2] = foster2(Zn, Zd);
displ(" ");
displ("Inductors: ", Ls2)
displ("Capacitors: ", Cs2);