%=========================================================================%
% This example shows how to use Richard's extraction to realize a
% distributed element circuit from an impedance function. The impedance
% function must be in terms of te Richard's variable (t = j*Z0*tan(theta))
% rather than the laplace variable 's'. This example demonstrates circuits
% with both stubs and stepped impedance lines. This example replicates the
% example in Section 3,8,1 and 3,8,2 of "Microwave Amplifier and Active
% Circuit Design Using the Real Frequency Technique" by P. Jarry & J.
% Beneat.
%
% PROBLEM DESCRIPTION:
% Design a distributed element circuit realizing the input impedance
% functions:
%    1.         100*t^3 + 50*t^2 + 300*t + 30
%		Z(t) = -------------------------------	(Section 3,8,1 Ex.)
%                9*t^3 + 170*t^2 + 31*t + 30
%
%    2.               18*t^2 + 240*t + 30
%		Z(t) = -------------------------------	(Section 3,8,2 Ex.)
%                9*t^3 + 170*t^2 + 31*t + 30
%
% such that 't' is the Richard's variable.
%
% 
% Author: G. Giesbrecht
% Contact: grant.giesbrecht@colorado.edu
%
%=========================================================================%


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