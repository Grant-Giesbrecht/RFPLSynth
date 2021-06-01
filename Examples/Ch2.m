%
% Problem is error function for stage 2, gives gain_t = 0, thus inf.
%
% One problem is that the netowrk compute func is not .* but for loop.
% Makes more complicated. Change that. All freqs are independent of ea. so
% no problem there. Then debug again and find out why gain-t is being
% calcaulated incorrectly for k=2+
%

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
net.vswr_in_t = 1.5;
net.vswr_out_t = 1.5;

h_coef = [1,1,0];

% Set weights in evaluation functions for ea. stage
net.getStg(1).weights = [1, 5, 0];
net.getStg(2).weights = [1, 5, 0];
net.getStg(3).weights = [1, 0, 0];
net.getStg(4).weights = [1, 0, 0];
net.getStg(5).weights = [0, 0, 1];

net.setEvalFunc(@error_fn1);


% Define the error function for this iteration
fn1 = @(h, s_data) default_opt(h, net, 1);
fn2 = @(h, s_data) default_opt(h, net, 2);
fn3 = @(h, s_data) default_opt(h, net, 3);
fn4 = @(h, s_data) default_opt(h, net, 4);
fn5 = @(h, s_data) default_opt(h, net, 5); %TODO: Put 'k' as a parameter in network
% func = @(h,s_data) error_function(h, s_data, net, vswr_in_t, SParam_Q, s_raw);

% Prepare the Levenberg-Marquardt optimization algorithm
default_tol = 1e-6;
options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100);
options.MaxFunctionEvaluations = 6e3;
options.MaxIterations = 4e3;
% options.Display = 'none';
lb = [];
ub = [];

% Run Optimizer for Stage 1
[h_opt,resnorm,residual,exitflag,output] = lsqcurvefit(fn1, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-1 computations
net.getStg(1).compute_fsimple(h_opt);
net.compute_rcsv();
displ("Stage 1 Polynomials:", newline, net.getStg(1).polystr());

% Run Optimizer for Stage 2
[h_opt,resnorm,residual,exitflag,output] = lsqcurvefit(fn2, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-2 computations
net.getStg(2).compute_fsimple(h_opt);
net.compute_rcsv();
displ("Stage 2 Polynomials:", newline, net.getStg(2).polystr());



function error_sum = error_fn1(net, k)
	
	stg = net.getStg(k);

	error_sum = sum( stg.weights(1) * (stg.gain./stg.gain_t - 1).^2 + stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2 );

end



















































