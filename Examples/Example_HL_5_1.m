syms s;
Zin = (s^2 + 1)*(s^2 + 9) / s/(s^2 + 4)/(s^2 + 16);

[Zn, Zd] = sym2nd(Zsym);

synth = NetSynth(Zd, Zn);

synth.generate('Foster1');