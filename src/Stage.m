classdef Stage < handle
	
	properties 
		
		% Equalizer S-Parameters
		e_11
		e_21
		e_12
		e_22
		
		% Transistor S-Parameters
		S_11
		S_21
		S_12
		S_22
		SPQ
		
		% Multi-stage S-Parameters
		eh_11
		eh_21
		eh_12
		eh_22
		S_G
		S_L
		
		% Frequencies
		freqs
		
		% Polynomials
		f
		h
		g
		
		% Metrics
		gain
		vswr_in
		vswr_out
	end
	
	methods
		
		function obj = Stage()
			obj.e_11 = [];
			obj.e_21 = [];
			obj.e_12 = [];
			obj.e_22 = [];
			
			obj.S_11 = [];
			obj.S_21 = [];
			obj.S_12 = [];
			obj.S_22 = [];
			
			obj.eh_11 = [];
			obj.eh_21 = [];
			obj.eh_12 = [];
			obj.eh_22 = [];
			
			obj.S_G = [];
			obj.S_L = [];
			
			obj.freqs = [];
			
			obj.f = Polynomial(0);
			obj.g = Polynomial(0);
			obj.h = Polynomial(0);
			
			obj.gain = [];
			obj.vswr_in = [];
			obj.vswr_out = [];
		end
		
		
		
		function [gains, vswrs] = compute_fsimple(obj, h_vec, s_vec, s_raw)

			% Update frequencies
			obj.freqs = imag(s_raw);
			
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
			[obj.e_11, obj.e_21, obj.e_22] = poly2S(obj.f, obj.g, obj.h, s_vec);
			obj.e_12 = obj.e_21;

			% Populate S_xy
			obj.S_11 = [];
			obj.S_21 = [];
			obj.S_12 = [];
			obj.S_22 = [];
			for frq = imag(s_raw)
				
				% Find index
				f_idx = find(obj.SPQ.Frequencies == frq);
				if isempty(f_idx)
					error("THIS NEEDS TO BE HANDLED BETTER - Failed to find frequency");
					return;
				end
			
				obj.S_11 = addTo(obj.S_11, obj.SPQ.Parameters(1, 1, f_idx));
				obj.S_21 = addTo(obj.S_11, obj.SPQ.Parameters(2, 1, f_idx));
				obj.S_12 = addTo(obj.S_11, obj.SPQ.Parameters(1, 2, f_idx));
				obj.S_22 = addTo(obj.S_11, obj.SPQ.Parameters(2, 2, f_idx));
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

		end

		
	end
	
end