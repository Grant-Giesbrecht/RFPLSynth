function [Ls, Cs] = foster2(Zn, Zd)

	% Create symbolic polynomial from numerator and denominator
	% coefficients
	syms s;
	n = poly2sym(Zn, s);
	d = poly2sym(Zd, s);
	Z = d/n;

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

	% Create empty L and C vectors
	Ls = [];
	Cs = [];
	
	% For each polynomial term...
	for t = terms

		% Get Foster elements
		[C, L] = fost2el(t);

		% Add to list
		Ls = addTo(Ls, L);
		Cs = addTo(Cs, C);

	end	

end





























