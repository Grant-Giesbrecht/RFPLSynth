

SParam_Q = sparameters("JB_Ch2_Ex_Q.s2p"); % Read transistor S-parameter data

s_raw = sqrt(-1).*[18, 19, 20, 21].*1e9;
f_scale = 21e9;
s_vec = s_raw./f_scale;

vswr_in_t = 2;

% Create network object
net = Network(4);
net.setSPQ(SParam_Q); % Set all transistor S-parameters
net.setFreqs(s_vec, s_raw);
net.reset();
net.showErrors = true;

% Set weights in evaluation functions for ea. stage
net.getStg(1).weights = [1, 5, 0];
net.getStg(2).weights = [1, 5, 0];
net.getStg(3).weights = [1, 0, 0];
net.getStg(4).weights = [1, 0, 0];
net.getStg(5).weights = [0, 0, 1];

% Feed in Stage-1 Polynomial
net.getStg(1).compute_fsimple([-.668, -.445, 0]);
displ("Stage 1 Polynomials:", newline, net.getStg(1).polystr());

% Run algorithm on first stage
net.compute_rcsv();

% Feed in Stage-2 Polynomial
net.getStg(2).compute_fsimple([-.484, -.287, 0]);
displ(newline, "Stage 2 Polynomials:", newline, net.getStg(2).polystr());
net.compute_rcsv();

% Feed in Stage-3 Polynomial
net.getStg(3).compute_fsimple([-.251, -.090, 0]);
displ(newline, "Stage 3 Polynomials:", newline, net.getStg(3).polystr());
net.compute_rcsv();

% Feed in Stage-4 Polynomial
net.getStg(4).compute_fsimple([-.248, .136, 0]);
displ(newline, "Stage 4 Polynomials:", newline, net.getStg(4).polystr());
net.compute_rcsv();

% Feed in Stage-5 Polynomial
net.getStg(5).compute_fsimple([.480, .271, 0]);
displ(newline, "Stage 5 Polynomials:", newline, net.getStg(5).polystr());
net.compute_rcsv();

% Plot gains (Should match Fig. 2,10)
net.plotGain(1e9, 1);

% Set strange axes/tick spacings to match Fig. 2,10 of book for easier
% comparison.
yticks(0:2.3:23);
ylim([0,23]);















































