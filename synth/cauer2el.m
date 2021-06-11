function [k, Tn, Td] = cauer2el(num, den)
% CAUER2EL 
%
%		   num      k       1
%	Z(s) = ---  =  --- + ------		(Tn, Td would be passed to CAUER1 as
%		   den      s     Tn/Td      num and den, respectively).
%
	
	% Create symbolic polynomial from numerator and denominator
	% coefficients
	syms s;
	n = poly2sym(num, s);
	d = poly2sym(den, s);
	Z = n/d;
	
	% Perform partial fraction decomposition
	pf = partfrac(Z, 'FactorMode', 'Real');
	
	% Break decomposition up into terms
	terms_cell = children(pf);
	
	% Check output type of children. In MATLAB 2020b and later it will be a
	% cell array. Previously it will be a vector. Here the type is checked,
	% then converted to a vector for consistency.
	if iscell(terms_cell)
		% Convert output to vector
		terms = [];
		for i=1:numel(terms_cell)
			terms = addTo(terms, terms_cell{i});
		end
	else
		terms = terms_cell;
	end
	
	k_term = [];
	remainder_terms = [];
	
	% Scan through each term, pick out the term(s) that follow the format
	% of some number divided by 's'. 
	for t=terms
		
		% To check order, need to pull out denomenator
		[N, D] = numden(t);
		
		% Check if denominator is order 1 polynomial (ie. term = num/s)
		if polynomialDegree(D) == 1 && polynomialDegree(N) == 0
			k_term = t; %TODO: Replace with addTo incase there are mult num/s terms? (there shouldnt be)
		else
			remainder_terms = addTo(remainder_terms, t);
		end
		
	end
	
	% Check for missing k_term
	if isempty(k_term)
		error("Failed to find K value. Check input polynomial.");
	end
	
	% Recombine all terms other than the k/s term
	T = sum(remainder_terms);
	
	% Pull the numerator and denominator out of the sum
	%
	% Note: Td is getting numerator output, Tn is getting denominator. That
	% is because T is defined as 1/(Tn/Td). It's a bit confusing, but done
	% to make Tn feed into next stage as numerator, Td as denominator.
	[Td, Tn] = numden(T);
	
	% Convert Td, Tn from symbolic polynomials to MATLAB polynomial vectors
	Td = double(coeffs(Td, 'All'));
	Tn = double(coeffs(Tn, 'All'));
	
	% Calculate K from k_term
	[N, D] = numden(k_term); % Get numerator and denominator 
	N = double(coeffs(N, 'All')); % Convert to floats
	D = double(coeffs(D, 'All')); % COnvert to floats
	k = N(end)/D(end-1); %K is 0-order term of numerator, divided by 1st order term of denominator
	
	
end