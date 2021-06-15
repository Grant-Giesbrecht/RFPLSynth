MultiStageforce_h0 = true;
give_good_guess = false;

SParam_Q = sparameters("JB_Ch2_Ex_Q.s2p"); % Read transistor S-parameter data

s_raw = sqrt(-1).*[18, 19, 20, 21].*1e9;
f_scale = 21e9;
s_vec = s_raw./f_scale;

% Create MultiStage object
net = MultiStage(4);
net.setSPQ(SParam_Q); % Set all transistor S-parameters
net.setFreqs(s_vec, s_raw);
net.reset();
net.showErrors = true;
net.vswr_in_t = 2;
net.vswr_out_t = 2;
net.ZL = 50;
net.Z0 = 50;

h_coef = [1,1,0];
if force_h0
	h_coef = [1, 1];
	net.forceCoef(0, 0);
end
net.setHGuess(h_coef);

if give_good_guess
	net.getStg(1).weights = [-.7, -.4];
	net.getStg(2).weights = [-.5, -.3];
	net.getStg(3).weights = [-.3, -.1];
	net.getStg(4).weights = [-.3, .1];
	net.getStg(5).weights = [.5, .3];
end

net.setEvalFunc(@error_fn1);

% Set weights in evaluation functions for ea. stage
net.getStg(1).weights = [1, 5, 0];
net.getStg(2).weights = [2, 3, 0];
net.getStg(3).weights = [1, 0, 0];
net.getStg(4).weights = [1, 0, 0];
net.getStg(5).weights = [0, 0, 1];




% Define the error function for this iteration

% Prepare the Levenberg-Marquardt optimization algorithm
default_tol = 1e-6;
default_iter = 400;
default_funceval = 100*numel(net.getStg(1).h_init_guess);
options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100/100);
% options.MaxFunctionEvaluations = 6e3;
% options.MaxIterations = 4e3;
options.MaxIterations = default_iter*100;
options.MaxFunctionEvaluations = default_funceval*100;
options.Display = 'none';

net.setOptOptions(options);

for k=1:5
	net.optimize(k, 'simple');
end

net.plotGain(1e9, 2);
subplot(1,3,1);
ylim([0, 23]);
yticks(0:2.3:23);
subplot(1,3,2);
ylim([0, 23]);
yticks(0:2.3:23);
net.optimSummary();


%==========================================================================

% Create MultiStage object
net_JB = MultiStage(4);
net_JB.setSPQ(SParam_Q); % Set all transistor S-parameters
net_JB.setFreqs(s_vec, s_raw);
net_JB.reset();
net_JB.showErrors = true;
net_JB.Z0 = 50;
net_JB.ZL = 50;
net_JB.vswr_in_t = 2;
net_JB.vswr_out_t = 2;

% Set weights in evaluation functions for ea. stage
net_JB.getStg(1).weights = [1, 5, 0];
net_JB.getStg(2).weights = [1, 5, 0];
net_JB.getStg(3).weights = [1, 0, 0];
net_JB.getStg(4).weights = [1, 0, 0];
net_JB.getStg(5).weights = [0, 0, 1];

% Feed in Stage-1 Polynomial
net_JB.getStg(1).compute_fsimple([-.668, -.445, 0]);
displ("Stage 1 Polynomials:", newline, net_JB.getStg(1).polystr());

% Run algorithm on first stage
net_JB.compute_rcsv();

% Feed in Stage-2 Polynomial
net_JB.getStg(2).compute_fsimple([-.484, -.287, 0]);
displ(newline, "Stage 2 Polynomials:", newline, net_JB.getStg(2).polystr());
net_JB.compute_rcsv();

% Feed in Stage-3 Polynomial
net_JB.getStg(3).compute_fsimple([-.251, -.090, 0]);
displ(newline, "Stage 3 Polynomials:", newline, net_JB.getStg(3).polystr());
net_JB.compute_rcsv();

% Feed in Stage-4 Polynomial
net_JB.getStg(4).compute_fsimple([-.248, .136, 0]);
displ(newline, "Stage 4 Polynomials:", newline, net_JB.getStg(4).polystr());
net_JB.compute_rcsv();

% Feed in Stage-5 Polynomial
net_JB.getStg(5).compute_fsimple([.480, .271, 0]);
displ(newline, "Stage 5 Polynomials:", newline, net_JB.getStg(5).polystr());
net_JB.compute_rcsv();

%==========================================================================

[e1, e2, e3] = error_fn_breakdown(net, 1);
[eJ1, eJ2, eJ3] = error_fn_breakdown(net, 1);

for i=2:5
	[e1(i), e2(i), e3(i)] = error_fn_breakdown(net, i);
	[eJ1(i), eJ2(i), eJ3(i)] = error_fn_breakdown(net_JB, i);
end

figure(1);
for k=1:5
	subplot(2, 3, k);
	srcs = categorical({'Gain','VSWR In','VSWR Out'});
	srcs = reordercats(srcs,{'Gain','VSWR In','VSWR Out'});
	bar(srcs,[e1(k), e2(k), e3(k); eJ1(k), eJ2(k), eJ3(k)]);
	ylabel("Residual");
	title(strcat("Stage ", num2str(k), " Error Sources"));
	legend("MATLAB Optimzer", "J+B");
end

% e1
% eJ1
% e2
% eJ2
% e3
% eJ3

function error_sum = error_fn1(net, k)

	stg = net.getStg(k);

	gain_term = stg.weights(1) * (stg.gain./stg.gain_t - 1).^2;
	vswr_in_term = stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2;
	vswr_out_term = stg.weights(3) * (net.vswr_out./net.vswr_out_t - 1).^2;

	error_sum = sum( gain_term + vswr_in_term + vswr_out_term );

end

function [err1, err2, err3] = error_fn_breakdown(net, k)

	stg = net.getStg(k);

	gain_term = stg.weights(1) * (stg.gain./stg.gain_t - 1).^2;
	vswr_in_term = stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2;
	vswr_out_term = stg.weights(3) * (net.vswr_out./net.vswr_out_t - 1).^2;

	err1 = sum(gain_term);
	err2 = sum(vswr_in_term);
	err3 = sum(vswr_out_term);

end
