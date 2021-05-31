

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
disp(net.getStg(1).polystr());

% Run algorithm on first stage
net.compute_rcsv();

% % Define the error function for this iteration
% func = @(h,s_data) error_function(h, s_data, net, vswr_in_t, SParam_Q, s_raw);
% 
% % Run the Levenberg-Marquardt optimization algorithm
% default_tol = 1e-6;
% options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt', 'FunctionTolerance', default_tol/100);
% options.MaxFunctionEvaluations = 6e3;
% options.MaxIterations = 4e3;
% % options.Display = 'none';
% lb = [];
% ub = [];
% [h_opt,resnorm,residual,exitflag,output] = lsqcurvefit(func, h_coef, s_vec, [0], lb, ub, options);
% 
% % Print basic info about the optimization results
% displ("Starting coefficients: ", h_coef);
% displ("Optimized coefficients: ", h.str("s"));
% displ("Residual norm: ", resnorm);
% 
% % Add missing 0 to h
% h_opt = addTo(h_opt, 0);
% 
% % Update stage 1 to reflect optimized values
% net.getStg(1).compute_fsimple(h_opt, s_vec, s_raw);
% 
% % Run the networks







% % "Run" the new h polynomial. This calculates g, gain, etc for this final
% % value. This is essentially the same as the error function used in the
% % optimizer, except it outputs the gain and vswr instead of an error.
% [gain, vswr] = JBCh2_run(h.getVec(), s_vec, SParam_Q, s_raw);
% 
% 
% 
% % Plot gain and vswr
% figure(1);
% yyaxis left;
% plot(imag(s_vec).*f_scale/1e9, lin2dB(gain)./2);
% ylabel("Gain (dB)");
% % yl = ylim;
% % if yl(2) < 1
% % 	yl(2) = 1;
% % end
% % ylim([0, yl(2)]);
% grid on;
% yyaxis right;
% plot(imag(s_vec).*f_scale/1e9, lin2dB(vswr)./2);
% ylabel("VSWR (a.u.)");
% yl = ylim;
% if yl(2) < 2
% 	yl(2) = 2;
% end
% ylim([0, yl(2)]);
% xlabel("Frequency (GHz)");
% legend('Gain', 'VSWR');






function error_sum = error_function_stg2(h_vec, s_vec, net, stg_no, vswr_in_t, SParam_Q, s_raw)
% ERROR_FUNCTION_STG2 This is the error function for using SRFT to optimize a
% polynomial to meet certain circuit design goals. This is specifically for
% stage 2.
%
%	ERROR_FUNCTION_STG2(H_VEC, S_VEC, W1, W2, VSWR_IN_T, SPARAM_Q, S_RAW) Error
%	function for SRFT optimization. H_VEC is the vector of h(s)
%	coefficients provided by the optimizer. It is expected in MATLAB
%	polynomial vector format (ie. that used by roots(), for example). S_VEC
%	is a vector of frequencies in the laplace domain (sigma + j*omega) at
%	which the polynomials will be evaluated. W1 is the weight gain in the
%	error sum. W2 is the weight for input VSWR in the error sum. VSWR_IN_T
%	is the target input VSWR. SPARAM_Q is an S Parameter object containing
%	the data for the transistor in this stage of the circuit. S_RAW are the
%	frequencies, not scaled (s_vec's values can be scaled if so desired),
%	which are looked for in SPARAM_Q. If any of the frequencies are not
%	found in SPARAM_Q, and error will be thrown.
%
%

	h_vec = addTo(h_vec, 0);
	error_sum = 0;
	
	%=====================================================================%
	%		Calculate Polynomials
	
	% Create h(s) Polynomial object from h vector
	h = Polynomial(h_vec);

	% Calculate G(s)
	%
	% NOTE: In this example, we no zeros appear in f(s), ie. f(s) = 1. 'k' is
	% usually used by JB to describe the number of stages, however here they're
	% using it to describe the number of zeros in f(s)/g(s), and thus in the
	% function JB_hfsimple2G the term 'k' is used to describe the numerator,
	% ie. number of zeros.
	G = JB_hfsimple2G(h, 0);
	
	% Calculate g(s) from G(s) by selecting left-hand side roots of G(s)
	g = JB_lhrpoly(G);
	
	% Normalize g(s) so g0 = 1, as this is required by how we defined f(s)
	% in this simplified example
	g.coefficients = g.coefficients./g.get(0);
	
	% Check if g(s) = 0. It is the denominator, so error sum will be inf
	% and cause errors.
	if g.iszero()
		error_sum = 1e50;
		displ("Is zero! [", h.str, "]");
		return;
	end

	% Define weird f(s) so the 'e' equations below can be general
	f = Polynomial(0);
	f.set(0, 1);
	
	%=====================================================================%
	%		Calculate Error Function Parameters
	
	% Calculate target gain
	gain_t = JB_gain_target(SParam_Q);
	
	% At each frequency....
	idx = 0;
	for s=s_vec
		
		idx = idx + 1;
		
		% Calculate S-Parameters of the network
		[e11, e21, e22] = poly2S(f, g, h, s);
		
		% Calculate S-Parameters of the transistor at the relevant
		% frequency
		S21 = getParam(2, 1, imag(s_raw(idx)), SParam_Q);
		S11 = getParam(1, 1, imag(s_raw(idx)), SParam_Q);
		if isempty(S21) || isempty(S11)
			error(strcat("Failed to find required data in S2P file. Frequency: ", num2str(imag(s)), " Hz not found."));
		end
		
		% Calculate S-Parameters of entire network
		eh_11 = e11 + e21^2*S11 / (1 - e22*S11);
		
		eh_22 = e22 + (e21.^2 .* S_G.^2)./(1 - e11.*S_G);
		
		S_G = S22_prev + (S12_prev .* S21_prev .* eh_22_prev) ./ (1 - S11_prev .* eh_22_prev); 
		
		
		% Calculate gain
		gain = abs(e21)^2 * abs(S21)^2 /  abs( 1 - e22*S11 )^2;
		
		
		
		% Calculate multistage gain
		gain = gain_prev .* abs(e21).^2 .* abs(S21).^2 ./ abs(1 - e11.*S_G).^2 ./ abs(1 - eh_22.*S11).^2;
		
		% Calculate VSWR at input
		vswr_in = (1 + abs(eh_11))/(1 - abs(eh_11));
		
		% Eq. 2,28, with VSWR out skipped because the weight is set to zero
		error_sum = error_sum + net.W(stg_no, 1)*(gain/gain_t - 1)^2 + net.W(stg_no, 2)*( vswr_in/vswr_in_t - 1)^2;
		
	end
	
end

function error_sum = error_function(h_vec, s_vec, W1, W2, vswr_in_t, SParam_Q, s_raw)
% ERROR_FUNCTION This is the error function for using SRFT to optimize a
% polynomial to meet certain circuit design goals.
%
%	ERROR_FUNCTION(H_VEC, S_VEC, W1, W2, VSWR_IN_T, SPARAM_Q, S_RAW) Error
%	function for SRFT optimization. H_VEC is the vector of h(s)
%	coefficients provided by the optimizer. It is expected in MATLAB
%	polynomial vector format (ie. that used by roots(), for example). S_VEC
%	is a vector of frequencies in the laplace domain (sigma + j*omega) at
%	which the polynomials will be evaluated. W1 is the weight gain in the
%	error sum. W2 is the weight for input VSWR in the error sum. VSWR_IN_T
%	is the target input VSWR. SPARAM_Q is an S Parameter object containing
%	the data for the transistor in this stage of the circuit. S_RAW are the
%	frequencies, not scaled (s_vec's values can be scaled if so desired),
%	which are looked for in SPARAM_Q. If any of the frequencies are not
%	found in SPARAM_Q, and error will be thrown.
%
%

	h_vec = addTo(h_vec, 0);
	error_sum = 0;
	k = 0;
	
	%=====================================================================%
	%		Calculate Polynomials
	
	% Create h(s) Polynomial object from h vector
	h = Polynomial(h_vec);

	% Calculate G(s)
	%
	% NOTE: In this example, we no zeros appear in f(s), ie. f(s) = 1. 'k' is
	% usually used by JB to describe the number of stages, however here they're
	% using it to describe the number of zeros in f(s)/g(s), and thus in the
	% function JB_hfsimple2G the term 'k' is used to describe the numerator,
	% ie. number of zeros.
	G = JB_hfsimple2G(h, 0);
	
	% Calculate g(s) from G(s) by selecting left-hand side roots of G(s)
	g = JB_lhrpoly(G);
	
	% Normalize g(s) so g0 = 1, as this is required by how we defined f(s)
	% in this simplified example
	g.coefficients = g.coefficients./g.get(0);
	
	% Check if g(s) = 0. It is the denominator, so error sum will be inf
	% and cause errors.
	if g.iszero()
		error_sum = 1e50;
		displ("Is zero! [", h.str, "]");
		return;
	end

	% Define weird f(s) so the 'e' equations below can be general
	f = Polynomial(0);
	f.set(0, 1);
	
	%=====================================================================%
	%		Calculate Error Function Parameters
	
	% Calculate target gain
	gain_t = JB_gain_target(SParam_Q);
	
	% Define functions for calculating the S-parameters of the
	% equalizer/network from the polynomials f(s), g(s), h(s).
	e_11 = @(s, h, g) h.eval(s)./g.eval(s);
	e_21 = @(s, f, g) f.eval(s)./g.eval(s);
	% NOTE: e12 = e21
	e_22 = @(s, h, g) (-1).^(k+1) .* h.eval(s*-1)./g.eval(s);
	
	% At each frequency....
	idx = 0;
	for s=s_vec
		
		idx = idx + 1;
		
		% Calculate S-Parameters of the network
		e11 = e_11(s, h, g);
		e21 = e_21(s, f, g);
		e22 = e_22(s, h, g);
		
		% Calculate S-Parameters of the transistor at the relevant
		% frequency
		S21 = getParam(2, 1, imag(s_raw(idx)), SParam_Q);
		S11 = getParam(1, 1, imag(s_raw(idx)), SParam_Q);
		if isempty(S21) || isempty(S11)
			error(strcat("Failed to find required data in S2P file. Frequency: ", num2str(imag(s)), " Hz not found."));
		end
		
		% Calculate S-Parameters of entire network
		eh_11 = e11 + e21^2*S11 / (1 - e22*S11);
		
		% Calculate gain
		gain = abs(e21)^2 * abs(S21)^2 /  abs( 1 - e22*S11 )^2;
		
		% Calculate VSWR at input
		vswr_in = (1 + abs(eh_11))/(1 - abs(eh_11));
		
		% Eq. 2,28, with VSWR out skipped because the weight is set to zero
		error_sum = error_sum + W1*(gain/gain_t - 1)^2 + W2*( vswr_in/vswr_in_t - 1)^2;
		
	end
	
	net.e(1, 1, k-1, s);
	
end




