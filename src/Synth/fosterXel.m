function [L,C] = fost2comp(sp)
% FOST2COMP Calculates L and C values for a Foster I-form stage
%
% Computes the L and C values given a symbolic math polynomial SP and
% returns the parallel L and C values for one stage of a Foster I-form
% implementation of the polynomial.
%
%	[L,C] = FOST2COMP(SP) SP is a symbolic math polynomial representing one
%	stage of a Foster I-form polynomial, achieved via partial fraction
%	decomposition. Returns the L and C values for this stage.
%
	% Get numerator and denominator from symbolic polynomial
	[n,d] = numden(sp);
	
	% Convert to polynomial class
	num = Polynomial(0);
	den = Polynomial(0);
	num.setVec(double(coeffs(n, 'All')));
	den.setVec(double(coeffs(d, 'All')));
	
	% Check that numerator is correct order
	if num.order() ~= 1
		L = NaN;
		C = NaN;
		disp("Input polynomial is wrong format. Numerator must be order 1.");
		return;
	end
	
	% Check that denominator is correct order
	if den.order() ~= 2 && den.order() ~= 0
		L = NaN;
		C = NaN;
		disp("Input polynomial is wrong format. Denominator must be order 2.");
		return;
	end
	
	% Get scale factor - 0th order in denominator should equal 1
	scale_fact = den.get(0);
	
	% Get scaled coefficient from numerator's 1st order term
	L = num.get(1)/scale_fact;
	
	% Get scaled coegfficient from denominator's 2nd order term
	C = den.get(2)/scale_fact/L;

end























