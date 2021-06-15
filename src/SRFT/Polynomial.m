classdef Polynomial < handle
% POLYNOMIAL Represent polynomials by their coefficients
%	Whereas MATLAB conventionally represents polynomials simply as a
%	vector, this system can become confusing because the indexing for each
%	coefficient does not correspond to its order. This class allows you to
%	refer to coefficients by their order, while also converting to and from
%	the conventional MATLAB vector format.
%
% POLYNOMIAL Properties
%	coefficients - Vector of coefficients for the polynomial. Ordered such
%	that index 1 corresponds to order 0 and index 'end' corresponds to
%	order 'n'.
%
% POLYNOMIAL Methods:
%	Polynomial(N) - Constructor, creating a polynomial of order 'N' if
%	input variable N is a single numeric value, else if N is a numeric
%	vector, the Polynomial is initailized from N and interprets it as a
%	polynomial in MATLAB vector format. If N is represents the order as a
%	single numeric value, all coefficients are initialized as zeros.
%
%	getVec() - Return the polynomial in MATLAB vector format.
%	surpressErrors(TF) - If true, disable the class from printing error
%	messages to the console.
%	setOrder(N) - Change the order of the polunomial to order 'N'. Will add
%	zeros if the new order is higher. Will remove the highest order terms
%	if the new order is lower.
%	get(ORD) - Get the coefficient of order 'ORD'
%	set(ORD, VAL) - Change the value of the coefficient of order 'ORD' to
%	'VAL'.
%	setVec(NEWVEC) - Set all coefficients and change the order of the
%	polynomial to match the vector NEWVEC. Note that NEWVEC is expected to
%	be in MATLAB vector format (index '1' corresponds to highest order).
%	order() - Get the order of the polynomial
%
	properties
		coefficients
	end
	
	properties(Access=private)
		allowPrintErrors = true;
	end
	
	methods 
		
		function obj = Polynomial(n)
			
			% Determine dimensions of n
			[~, c] = size(n);
			
			if c == 1 % Initilize with zeros to order 'n'
				obj.coefficients = zeros(1, n+1);
			else % Initialize to mimic vector 'n'
				obj.coefficients = [0];
				obj.setVec(n);
			end
		end
		
		function v = getVec(obj)
			v = flip(obj.coefficients);
		end
		
		function surpressErrors(obj, tf)
			obj.allowPrintErrors = ~tf;
		end
		
		function setOrder(obj, n)
			
			% Add zeros if the old order was lower
			while n+1 > length(obj.coefficients)
				obj.coefficients = addTo(obj.coefficients, 0);
			end
			
			% Remove coefficients if old order was higher
			while n+1 < length(obj.coefficients)
				obj.coefficients(end) = [];
			end
			
		end
		
		function ord = order(obj)
			ord = length(obj.coefficients)-1;
			if ord < 0
				ord = 0;
			end
		end
		
		function p = get(obj, ord)
			
			% Ensure order is within bounds
			if  ord < 0
				p = 0;
% 				p = [];
% 				if obj.allowPrintErrors
% 					displ("Failed to get coefficient because it was out of bounds");
% 				end
				return;
			end
			
			% If order is greater than polynomial order, return 0
			if ord > obj.order()
				p = 0;
				return;
			end
			
			p = obj.coefficients(ord+1);
		end
		
		function set(obj, ord, val)
			
			% Ensure order is within bounds
			if  ord < 0 || ord > obj.order()
				if obj.allowPrintErrors
					displ("Failed to get coefficient because it was out of bounds");
				end
				return;
			end
			
			% Update coefficient value
			obj.coefficients(ord+1) = val;
			
		end
		
		function setVec(obj, newvec)
			
			% Ensure input vector is right type
			if ~isnumeric(newvec)
				if obj.allowPrintErrors
					displ("ERROR: Input vector must be numeric type.");
				end
				return;
			end
			
			% Ensure input vector is not 2D+
			[r, ~] = size(newvec);
			if r ~= 1
				if obj.allowPrintErrors
					displ("ERROR: Input vector must have exactly one row.");
				end
				return;
			end
			
			% Update coefficient values
			obj.coefficients = flip(newvec);
			
			
		end
		
		function s=str(obj, xstr)
			
			if ~exist('xstr','var')
				xstr = "x";
			end
			
			s = poly2str(obj, xstr);
		end
		
		function tf = iszero(obj)
			
			%Initailize return value
			tf = true;
			
			%Check each coefficient
			for c = obj.coefficients
				
				% If coefficient is non-zero, return false
				if c ~= 0
					tf = false;
					return;
				end
			end
			
		end
		
		function solns = solve(obj, val)
		%	
		% Solve the polynomial for the value
		%
			vec = obj.getVec();
			
			vec(end) = vec(end) - val;
			
			solns = roots(vec);
			
		end
		
		function val = eval(obj, x)
		%
		% Evaluate the polynomial at 'x'
		%
		
			val = polyval(obj.getVec(), x);
		
		end
		
		function normalize(obj, x)
			
			% Get order 0 value
			nv = obj.get(0);
			
			% Normalize all coefficients
			for ord = 0:obj.order()
				
				obj.set(ord, obj.get(ord)/nv);
				
			end
			
		end
		
		
		
	end
	
end