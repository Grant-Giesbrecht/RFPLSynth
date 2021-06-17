% Create symbolic polynomial being synthesized
syms s;
Zin = (s^2 + 1)*(s^2 + 9) / s/(s^2 + 4)/(s^2 + 16);

% Get numerator and denominator polynomial vectors
[Zn, Zd] = sym2nd(Zin);

% Create Network Synthesizer Object
synth = NetSynth(Zn, Zd);

% Evaluate Realizability
displ("Realizable formats:");
displ(synth.realizable());

% Generate Foster-I Network
synth.generate('Foster1');

% Save Circuit
foster1_cr = synth.circ;

%Reset synthesizer
synth.reset();

% Generate Foster-II Network
synth.generate('Foster2');
synth.circ.purge();

% Save circuit
foster2_cr = synth.circ;

% Display Results
displ("Foster-I Circuit:");
disp(foster1_cr.str());
displ(newline, "Foster-II Circuit:");
disp(foster2_cr.str());













