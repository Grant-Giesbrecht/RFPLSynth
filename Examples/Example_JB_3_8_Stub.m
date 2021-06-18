num = [18, 240, 30];
den = [9, 170, 31, 30];

synth = NetSynth(num, den);

% synth.richardStepZ();
% displ("[", synth.num, "]/[", synth.den, "]");

synth.generate("Richard");

displ("Richard's Stepped Impedance Realization:");
displ(synth.circ.str());