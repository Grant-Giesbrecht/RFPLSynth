function [L, C, Tn, Td] = fosterXel(num, den)
%
%
%
%
%

	% Create symbolic polynomial from numerator and denominator
	% coefficients
	syms s;
	n = poly2sym(Zn, s);
	d = poly2sym(Zd, s);
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

	% Scan through each term, pick out the term(s) that follow the format
	% of some number divided by 's'.
	for t=terms

		% To check order, need to pull out denomenator (as vectors)
		[nv, dv] = sym2nd(t);

		% Check 't' describes a circuit element with an 's' in the
		% denominator

		if iselement(nv, dv, 'Format', 'Foster')
			k_term = t; %TODO: Replace with addTo incase there are mult num/s terms? (there shouldnt be)
		else % Does not look like element, add to denominator
			remainder_terms = addTo(remainder_terms, t);
		end

	end

	% Check for missing k_term
	if isempty(k_term)
		error("Failed to find K value. Check input polynomial.");
	end

%============================================ END OF NEW CODEE=================

	% Create empty L and C vectors
	Ls = [];
	Cs = [];

	% For each polynomial term...
	for t = terms

		% Get Foster elements
		[L, C] = foster2comp(t);

		% Add to list
		Ls = addTo(Ls, L);
		Cs = addTo(Cs, C);

	end

end
