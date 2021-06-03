force_h0 = true;

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
if force_h0
	h_coef = [1, 1];
	net.forceCoef(0, 0);
end

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
options.Display = 'none';
lb = [];
ub = [];

% Run Optimizer for Stage 1
[h_opt,resnorm,residual,exitflag,net.getStg(1).optim_out] = lsqcurvefit(fn1, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-1 computations
net.getStg(1).compute_fsimple(h_opt);
net.compute_rcsv();
displ(newline, "Stage 1 Polynomials:", newline, net.getStg(1).polystr());

% Run Optimizer for Stage 2
[h_opt,resnorm,residual,exitflag,net.getStg(2).optim_out] = lsqcurvefit(fn2, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-2 computations
net.getStg(2).compute_fsimple(h_opt);
net.compute_rcsv();
displ(newline, "Stage 2 Polynomials:", newline, net.getStg(2).polystr());

% Run Optimizer for Stage 3
[h_opt,resnorm,residual,exitflag,net.getStg(3).optim_out] = lsqcurvefit(fn3, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-3 computations
net.getStg(3).compute_fsimple(h_opt);
net.compute_rcsv();
displ(newline, "Stage 3 Polynomials:", newline, net.getStg(3).polystr());

% Run Optimizer for Stage 4
[h_opt,resnorm,residual,exitflag,net.getStg(4).optim_out] = lsqcurvefit(fn4, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-4 computations
net.getStg(4).compute_fsimple(h_opt);
net.compute_rcsv();
displ(newline, "Stage 4 Polynomials:", newline, net.getStg(4).polystr());

% Run Optimizer for Stage 5
[h_opt,resnorm,residual,exitflag,net.getStg(5).optim_out] = lsqcurvefit(fn5, h_coef, s_vec, [0], lb, ub, options);

% Perform Stage-5 computations
net.getStg(5).compute_fsimple(h_opt);
net.compute_rcsv();
displ(newline, "Stage 5 Polynomials:", newline, net.getStg(5).polystr());



function error_sum = error_fn1(net, k)
	
	stg = net.getStg(k);

	gain_term = stg.weights(1) * (stg.gain./stg.gain_t - 1).^2;
	vswr_in_term = stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2;
	vswr_out_term = stg.weights(2) * (net.vswr_out./net.vswr_out_t - 1).^2;
	
	error_sum = sum( gain_term + vswr_in_term + vswr_out_term );

end



















































