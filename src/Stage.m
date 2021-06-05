classdef Stage < handle
% STAGE Represents a stage in an SRFT calculation
%
% STAGE Properties:
%	weights - Weights for each parameter in the evaluation function
%	eval_function - Function used to evaluation coefficients during
%	optimization.
%	targets - Targets for each parameter during optimization
%	freqs - Frequencies (not scaled)
%	s_vec - Scaled frequencies
%	recompute - If true, indicates that the stage's polynomials have not
%	been optimized and should not be used in recursive network-wide
%	calcualtions.
%	e - S-parameters of the equalizer
%	S - S-parameters of the active device (populated from SPQ)
%	SPQ - Sparameter object of the active device
%	eh - S-parameters of the equalizer, while accounting for all optimized
%	stages
%	SG - Generator reflection
%	SL - Load reflection
%	f - f(s) SRFT polynomial
%	g - g(s) SRFT polynomial
%	h - h(s) SRFT polynomial
%	gain - Vector of stage gain at each frequency
%	gain_t - Vector of gain targets for each freqency
%	gain_m - Vector of maxium gains for each frequency
	
	properties 
		
		%======================= Configuration Settings ===================
		
		weights
		
		eval_func
		opt_options
		lower_bounds
		upper_bounds
		
		h_init_guess
				
		% Frequencies
		% NOTE: s_vec is in the laplace domain (ie. sigma + j*omega) and
		% thus the frequency must be encoded as the imaginary component of
		% each element. 'freqs' is automatically populated from 's_raw'
		% when setFreqs is called. 's_vec' can be scaled to make the
		% coefficients in h more convenient or match prior art. The purpose
		% of 's_raw' is to provide a non-scaled laplace domain frequency
		% input to exact the frequency component (imaginary) only, save as
		% 'freq'. These values can then be used, for example, to query
		% values from S2P files. 
		freqs
		s_vec
		
		forcedCoefs
		targets
		
		vswr_in_opt
		vswr_out_opt
		
		%============================ Status Data =========================
		
		% Is used by the Network class to determine when these values are
		% up-to-date and should be used in recursive/full-system
		% calcuations, or if this stage needs to be re-optimized and have
		% be recomputed.
		recompute 
		
		%============================ Output Data =========================
		
		% Equalizer S-Parameters
		e
		
		% Transistor S-Parameters
		S
		SPQ
		
		% Multi-stage S-Parameters
		eh
		SG
		SL
		
		
		
		% Polynomials
		f
		h
		g
		
		% Metrics
		gain
		gain_t % Target gain
		gain_m % Maximum gain
		
		optim_out
		
	end
	
	methods
		
		function obj = Stage() %=================== Initializer ===========
			
			obj.weights = [];
			obj.eval_func = @(h) error("Need to initialize function 'eval_func'");
			
			obj.recompute = true;
			
			obj.e = [];
			
			obj.S = [];
			
			obj.eh = [];
			
			obj.SG = [];
			obj.SL = [];
			
			obj.freqs = [];
			
			obj.f = Polynomial(0);
			obj.g = Polynomial(0);
			obj.h = Polynomial(0);
			
			obj.gain = [];
			obj.gain_t = [];
			obj.gain_m = [];
			
			obj.forcedCoefs = containers.Map;
			obj.targets = containers.Map;
			
			obj.optim_out = [];
			
			obj.opt_options = optimoptions('lsqcurvefit','Algorithm','levenberg-marquardt');
			obj.lower_bounds = [];
			obj.upper_bounds = [];
		
		end %========================= End Initializer ====================
		
		function setFreqs(obj, s_vec, s_raw) %========= setFreqs ====
			% Update the frequency variables and resize the output arrays
			% correctly. s_vec uses scaled laplace domain freqs (ie. 1 Hz
			% written as i*1/scaling_factor s.t. scaling_factor is any real
			% number) and s_raw are non-scaled laplace domain frequencies.
		
			% WARNING: It is critical that all stages use the same frequencies,
			% and these frequencies must be represented in the Network object
			% too. If using a Network class, be sure to call setFreqs() from
			% the Network class, which will call this function for each stage,
			% to ensure that all stages and the Network have consistent
			% frequency data.
		
			% Update frequency variables
			obj.s_vec = s_vec;
			obj.freqs = imag(s_raw);
			
			% Modify size of data vectors
			m = length(obj.s_vec);
			obj.e = zeros(2,2,m);
			
			obj.S = zeros(2,2,m);
			obj.SL = zeros(1,1,m);
			obj.SG = zeros(1,1,m);
			
			obj.eh = zeros(2,2,m);
			
			obj.gain_t = zeros(1,m);
			obj.gain = zeros(1,m);
			obj.gain_m = zeros(1,m);
			
			idx = 1;
			for fr = obj.freqs
				obj.S(1,1,idx) = getParam(1,1,fr, obj.SPQ);
				obj.S(2,1,idx) = getParam(2,1,fr, obj.SPQ);
				obj.S(1,2,idx) = getParam(1,2,fr, obj.SPQ);
				obj.S(2,2,idx) = getParam(2,2,fr, obj.SPQ);
				idx = idx + 1;
			end
			
		end %============================== End setFreqs() =============
		
		function forceCoef(obj, order, value)
			
			if ~isnumeric(value)
				if obj.showErrors
					warning("Failed to add non-numeric value");
				end
				return;
			end
			
			obj.forcedCoefs(string(order)) = value;
			
		end
		
		function str = polystr(obj)
			% Returns the polynomials as a string
			
			str = "";
			
			if ~obj.recompute
				str = strcat(str, "f(s) = ", obj.f.str('s'));
				str = strcat(str, string(newline), "g(s) = ", obj.g.str('s'));
				str = strcat(str, string(newline), "h(s) = ", obj.h.str('s'));
			end
			
		end
		
		%========================= compute_fsimple() ======================
		function compute_fsimple(obj, h_vec) 
			% Computes the polynomial g(s) from h(s) assuming f(s) = 1.
			% h_vec contains the coefficients for h(s) in matlab polynomial
			% vector format.

			% Add forced coefficients
			for ky = obj.forcedCoefs.keys()
				
				% Get key (as char)
				key = ky{1};
				
				% Get order
				ord = str2num(key);	
				idx = length(h_vec)+1 - ord;
				idx_s = idx;
				if idx_s > length(h_vec)
					idx_s = length(h_vec);
				end
				
				val = obj.forcedCoefs(key); % Get value
				
				% Update h_vec
				h_vec = [h_vec(1:idx_s) , val, h_vec(idx:end)];
				
			end
			
			
			% Create h(s) Polynomial object from h vector
			obj.h = Polynomial(h_vec);

			% Calculate G(s)
			%
			% NOTE: In this example, we no zeros appear in f(s), ie. f(s) = 1. 'k' is
			% usually used by JB to describe the number of stages, however here they're
			% using it to describe the number of zeros in f(s)/g(s), and thus in the
			% function JB_hfsimple2G the term 'k' is used to describe the numerator,
			% ie. number of zeros.
			G = JB_hfsimple2G(obj.h, 0);

			% Calculate g(s) from G(s) by selecting left-hand side roots of G(s)
			obj.g = JB_lhrpoly(G);

			% Normalize g(s) so g0 = 1, as this is required by how we defined f(s)
			% in this simplified example
			obj.g.coefficients = obj.g.coefficients./obj.g.get(0);

			% Set out weird f(s) so the e equations below can be general
			obj.f = Polynomial(0);
			obj.f.set(0, 1);

			obj.recompute = false;
			
			% Compute e_xy
			[obj.e(1,1,:), obj.e(2,1,:), obj.e(2,2,:)] = poly2S(obj.f, obj.g, obj.h, obj.s_vec);
			obj.e(1,2,:) = obj.e(2,1,:);

		end %===================== End compute_fsimple() ==================

		
	end
	
end