classdef Stage < handle
	
	properties 
		
		%======================= Configuration Settings ===================
		
		weights
		eval_func
		targets
		
		% Frequencies
		% NOTE: s_vec is in the laplace domain (ie. sigma + j*omega) and
		% thus the frequency must be encoded as the imaginary component of
		% each element. 'freqs' is automatically populated from 's_raw'
		% when updateFreqs is called. 's_vec' can be scaled to make the
		% coefficients in h more convenient or match prior art. The purpose
		% of 's_raw' is to provide a non-scaled laplace domain frequency
		% input to exact the frequency component (imaginary) only, save as
		% 'freq'. These values can then be used, for example, to query
		% values from S2P files. 
		freqs
		s_vec
		
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
		S_G
		S_L
		
		
		
		% Polynomials
		f
		h
		g
		
		% Metrics
		gain
		gain_t % Target gain
		gain_m % Maximum gain
		
	end
	
	methods
		
		function obj = Stage() %=================== Initializer ===========
			
			obj.weights = [];
			obj.targets = [];
			obj.eval_func = @(h) error("Need to initialize function 'eval_func'");
			
			obj.recompute = true;
			
			obj.e = [];
			
			
			obj.S = [];
			
			obj.eh = [];
			
			obj.S_G = [];
			obj.S_L = [];
			
			obj.freqs = [];
			
			obj.f = Polynomial(0);
			obj.g = Polynomial(0);
			obj.h = Polynomial(0);
			
			obj.gain = [];
			obj.gain_t = [];
			obj.gain_m = [];
		
		end %========================= End Initializer ====================
		
		function updateFreqs(obj, s_vec, s_raw) %========= updateFreqs ====
		%
		% WARNING: It is critical that all stages use the same frequencies,
		% and these frequencies must be represented in the Network object
		% too. If using a Network class, be sure to call updateFreqs() from
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
			obj.S_L = zeros(1,1,m);
			obj.S_G = zeros(1,1,m);
			
			obj.eh = zeros(2,2,m);
			
			obj.gain_t = zeros(1,1,m);
			obj.gain = zeros(1,1,m);
			obj.gain_m = zeros(1,1,m);
			
		end %============================== End updateFreqs() =============
		
		
		%========================= compute_fsimple() ======================
		function [gains, vswrs] = compute_fsimple(obj, h_vec) 
			
			%=====================================================================%
			%		Calculate Polynomials

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

			%=====================================================================%
			%		Calculate Error Function Parameters

			gains = [];
			vswrs = [];

			% Compute e_xy
			[obj.e_11, obj.e_21, obj.e_22] = poly2S(obj.f, obj.g, obj.h, obj.s_vec);
			obj.e_12 = obj.e_21;

			% Populate S_xy
			obj.S = [];
			for frq = obj.freqs
				
				% Find index
				f_idx = find(obj.SPQ.Frequencies == frq);
				if isempty(f_idx)
					error("THIS NEEDS TO BE HANDLED BETTER - Failed to find frequency");
					return;
				end

				% TODO: This must be modified to match the new S format
% 				obj.S_11 = addTo(obj.S_11, obj.SPQ.Parameters(1, 1, f_idx));
% 				obj.S_21 = addTo(obj.S_11, obj.SPQ.Parameters(2, 1, f_idx));
% 				obj.S_12 = addTo(obj.S_11, obj.SPQ.Parameters(1, 2, f_idx));
% 				obj.S_22 = addTo(obj.S_11, obj.SPQ.Parameters(2, 2, f_idx));
			end
			
			obj.S_G % = 0 for first stage if matched TODO: General form?
			obj.S_L % = obj.S11 for first stage TODO: General form?
			
			% Compute eh_xy
			% TODO: This is stage-recursive and should be moved to being a
			% function in 'Network'.
			obj.eh_11 = obj.e11 + obj.e21.^2 .* obj.S_L ./ (1 - obj.e22 .* obj.S_L); %TODO: Is this fully general?	(from p.51)
			% TODO: eh_11 and others update for each stage as other stages
			% are added because they modify S_L (and S_G if not starting at
			% k=1).
			obj.eh_22 = obj.e22 + obj.e21.^2 .* obj.S_G ./ (1 - obj.e11 .* obj.S_G); %TODO: Is this fully general? (from p.53)
			
			% Compute VSWR_in
			obj.vswr_in = 1 + abs(eh_11)
			
% 			% At each frequency....
% 			idx = 0;
% 			for s=s_vec
% 				idx = idx + 1;
% 
% 				% Calculate S-Parameters of entire network
% 				eh_11 = e11 + e21^2*S11 / (1 - e22*S11);
% 
% 				% Calculate gain
% 				gain = abs(e21)^2 * abs(S21)^2 /  abs( 1 - e22*S11 )^2;
% 
% 				% Calculate VSWR at input
% 				vswr_in = (1 + abs(eh_11))/(1 - abs(eh_11));
% 
% 				gains = addTo(gains, gain);
% 				vswrs = addTo(vswrs, vswr_in);
% 
% 			end

			obj.recompute = false;

		end %===================== End compute_fsimple() ==================

		
	end
	
end