syms s;
Zsym = ( 64*s + 20*s^3 + s^5 )/( 9 + 10*s^2 + s^4 );

[Zn, Zd] = sym2nd(Zsym);

synth = NetSynth(Zd, Zn);
synth.c_isadm = true;

synth.generate('Cauer2');

disp(synth.circ.str());