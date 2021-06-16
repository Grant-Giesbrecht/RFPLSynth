function [L, C, Tn, Td] = foster1el(num, den)
%
%
%          num           L*s         Tn
%   Z(s) = ---  =  ------------- + ------      (Tn, Td would be passed to FOSTER as
%          den      L*C*s^2 + 1       Td      num and den, respectively).
%

	% Create symbolic polynomial from numerator and denominator
	% coefficients
	syms s;
	n = poly2sym(num, s);
	d = poly2sym(den, s);
	Z = n/d;

	% Compute partial fraction decomposition
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

		% To check order, need to pull out denomenator (as vectors)
		[nv, dv] = sym2nd(t);

		% Check 't' describes a circuit element with an 's' in the
		% denominator

		if iselement(nv, dv, 'Format', 'Foster') && isempty(k_term)
			k_term = t; %TODO: Replace with addTo incase there are mult num/s terms? (there shouldnt be)
		else % Does not look like element, add to denominator
			remainder_terms = addTo(remainder_terms, t);
		end

	end

	% Check for missing k_term
	if isempty(k_term)
		error("Failed to find L+C value. Check input polynomial.");
	end

	% Recombine all terms other than the k/s term
	T = sum(remainder_terms);

	% Pull the numerator and denominator out of the sum
	[Tn, Td] = numden(T); %Note: This does NOT flip num, and den, as is required in Cauer

	% Convert Td, Tn from symbolic polynomials to MATLAB polynomial vectors
	Td = double(coeffs(Td, 'All'));
	Tn = double(coeffs(Tn, 'All'));

	% Get numerator and denominator from symbolic polynomial for Element term
	[kn,kd] = numden(k_term);
	el_np = Polynomial(0);
	el_dp = Polynomial(0);
	el_np.setVec(double(coeffs(kn, 'All')));
	el_dp.setVec(double(coeffs(kd, 'All')));

	% Get scale factor - 0th order in denominator should equal 1
	scale_fact = el_dp.get(0);

	% Get scaled coefficient from numerator's 1st order term
	L = el_np.get(1)/scale_fact;

	% Get scaled coegfficient from denominator's 2nd order term
	C = el_dp.get(2)/scale_fact/L;

end
