function [num, den] = sym2nd(f)
%SYM2ND Converts a symbolic polynomial to a numerator and denominator
%vector polynomial.
%

		
	% Get numerator, denominator of sym poly
	[N, D] = numden(f);

	% Convert num, den to float vectors
	num = double(coeffs(N, 'All'));
	den = double(coeffs(D, 'All'));

end