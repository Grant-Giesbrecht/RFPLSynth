function g = lhrpoly(G)
%
% Calculates left-hand roots polynomial:
% Calculates g(s) from G(s) by finding G(s)'s roots, selecting the roots in
% the left-hand side of the complex plane, then multiplying those LHS roots
% out into the polynomial g(s). A numeric example is done on p. 52 of J+B.
% G is expected to by of the class Polynomial.
%

	% Find roots of G
	G_roots = roots(G.getVec());
	G_roots = transpose(G_roots);
	
	% Find LHS roots
	LHS_roots = [];
	for r = G_roots
		
		%If root is in LHS...
		if real(r) <= 0
			LHS_roots = addTo(LHS_roots, r);
		end
	end
	
	% Find polynomial from LHS roots
	g = Polynomial(poly(LHS_roots));

end