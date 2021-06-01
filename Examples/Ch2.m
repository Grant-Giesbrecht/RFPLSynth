

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
% func = @(h,s_data) error_function(h, s_data, net, vswr_in_t, SParam_Q, s_raw);

% Run the Levenberg-Marquardt optimization algorithm
default_tol = 1e-6;
options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100);
options.MaxFunctionEvaluations = 6e3;
options.MaxIterations = 4e3;
% options.Display = 'none';
lb = [];
ub = [];
[h_opt,resnorm,residual,exitflag,output] = lsqcurvefit(fn1, h_coef, s_vec, [0], lb, ub, options);


% Feed in Stage-1 Polynomial
net.getStg(1).compute_fsimple([-.668, -.445, 0]);
net.getStg(1).compute_fsimple(h_opt);
displ("Stage 1 Polynomials:", newline, net.getStg(1).polystr());

% Run algorithm on first stage


net.compute_rcsv();


function error_sum = error_fn1(net, k)
	
	stg = net.getStg(k);

	error_sum = sum( stg.weights(1) * (stg.gain./stg.gain_t - 1).^2 + stg.weights(2) * (net.vswr_in./net.vswr_in_t - 1).^2 );

end



















































