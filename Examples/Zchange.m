synth = NetSynth([1], [1]);
synth.freq = 1e9;

tl1 = CircElement(90, "DEG");
tl1.props("Z0") = 26;
tl1.nodes(1) = "IN";
tl1.nodes(2) = "n1";

tl2 = CircElement(90, "DEG");
tl2.props("Z0") = 19;
tl2.nodes(1) = "n1";
tl2.nodes(2) = "n2";

tl3 = CircElement(90, "DEG");
tl3.props("Z0") = 18.5;
tl3.nodes(1) = "n2";
tl3.nodes(2) = "OUT";
synth.node_iterator = 3;

synth.circ.add(tl1);
synth.circ.add(tl2);
synth.circ.add(tl3);

synth.changeZaddStubs('Zmin', 40);

% synth.raiseZ(1, 40);
% synth.raiseZ(4, 40);
% synth.raiseZ(7, 40);

displ(synth.circ.str());

synth.circ.simplify();

displ(newline, synth.circ.str());

synth.toStub();

displ(newline, synth.circ.str());