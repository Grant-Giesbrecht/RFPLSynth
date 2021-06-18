%
%
%
%
%
%


% Define polynomial vectors
num_1 = [100, 50, 300, 30];
num_2 = [18, 240, 30];
den = [9, 170, 31, 30];

% Example from J+B Section 3,8,1
synth_1 = NetSynth(num_1, den);
synth_1.generate("Richard");

% Example from J+B Section 3,8,2
synth_2 = NetSynth(num_2, den);
synth_2.generate("Richard");

% Print Results
displ("Section 3,8,1 Example:");
displ(synth_1.circ.str());

displ(newline, "Section 3,8,2 Example:");
displ(synth_2.circ.str());