syms s;
Zsym = ( 64*s + 20*s^3 + s^5 )/( 9 + 10*s^2 + s^4 );

[Zn, Zd] = sym2nd(Zsym);

% Note: THe inputs to NetSynth are flipped and it is marked as being in
% admittance mode
synth = NetSynth(Zd, Zn);
synth.is_admit = true;

synth.generate('Cauer2');

disp(synth.circ.str());