function Gs2 = hfsimple2G(h, k)
%
% Computes G(s^2) polynomial from f(s) and h(s), and assumes f(s) = =/- s^k.
%

	% 'n' in JB's notation indicates the order of polynomials used. Higher 'n'
	% used for matching more aggressive goals.
	n = h.order();

	% Create G Polynomial
	G = Polynomial(zeros(1, n));

	% Start at order 0, and compute each term of G(s^2) = g(s)*g(-s)
	for ord = 0:n

		% Compute G_0 special case
		if ord == 0
			G.set(ord, h.get(ord)^2 );
			continue;
		end

		% Compute G_n special case
		if ord == n
			G.set(ord, (-1)^(ord) * h.get(ord)^2);
			continue;
		end


		% Compute general case

		% Compute summation needed for general case equation
		sumval = 0;
		for j = 2:ord
			sumval = sumval + (-1)^(j-1) * h.get(j-1) * h.get(j*2-ord+1);
		end

		% Run general case equation
		G.set(ord, (-1)^ord * h.get(ord)^2 + 2*h.get(2*ord)*h.get(0) + 2*sumval); % TODO: 2*idx is wrong!


	end


	% Modify G at 'k' coefficient. This is substracting F(s) from G(s)
	G.set(k, G.get(k) + (-1)^k );

	% G(s^2) is a function of s^2, so G1 multiplies s^2, G2 multiplies s^4
	% and so forth. Currently G is written as a polynomial of s. Here we
	% add in the missing odd values of 's' so G is correctly presented as
	% G(s^2).
	Gs2 = Polynomial(zeros(1, G.order()*2));
	for ord=0:G.order()

		Gs2.set(ord*2, G.get(ord));

		if ord ~= G.order()
			Gs2.set(ord*2+1, 0);
		end
	end


end
