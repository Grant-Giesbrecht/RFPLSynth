%=========================================================================%
% This example demonstrates a simple appllication of Cauer synthesis to
% generate a circuit from a polynomial. Note the polynomial here is
% provided and not derived from a set of abstract conditions using SRFT.
% The main purpose of this example is to show how multiple forms of network
% synthesis can be used together on one network. In this example, Cauer
% forms 1 and 2 are used together. This example comes from Harry Y-F. Lam's
% 1979 book "Analog and Digital Filters: Design and Realization" as
% example 5-4.
%
%
%
% PROBLEM DESCRIPTION:
% Generate a circuit for the polynomial below using Cauer's 2nd form,
% followed by Cauer's 1st form.
%
%				   s^2 + 1
%		Zin(s) = -----------
%				  s^3 + 3*s
%
%
%
% Author: G. Giesbrecht
% Contact: grant.giesbrecht@colorado.edu
%
%=========================================================================%


Z_num = [1, 0, 1];
Z_den = [1, 0, 3, 0];

synth = NetSynth(Z_num, Z_den);

synth.cauer2();
synth.cauer1();

displ("Circuit Output:");
for c=synth.circ
	displ("  ", c.str());
end